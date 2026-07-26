import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:io';
import '../../../core/theme/app_colors.dart';
import '../../../services/ocr_service.dart';

class CameraScannerScreen extends StatefulWidget {
  const CameraScannerScreen({super.key});

  @override
  State<CameraScannerScreen> createState() => _CameraScannerScreenState();
}

class _CameraScannerScreenState extends State<CameraScannerScreen> {
  final _ocrService = OCRService();
  bool _isScanning = false;
  bool _hasTriedCamera = false;
  String _scanStatusText = '';
  File? _capturedImage;

  @override
  void initState() {
    super.initState();
    // Directly open camera when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runCameraCapture();
    });
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  void _processSelectedImage(File imageFile) async {
    setState(() {
      _isScanning = true;
      _capturedImage = imageFile;
      _scanStatusText = 'Membaca gambar struk...';
    });

    try {
      final result = await _ocrService.processImage(imageFile);
      if (!mounted) return;

      if (result != null) {
        setState(() {
          _scanStatusText =
              'Total terdeteksi: Rp ${_formatNumber(result.totalAmount)}';
        });
        await Future.delayed(const Duration(milliseconds: 800));
        if (!mounted) return;
        Navigator.pop(context, result);
      } else {
        setState(() {
          _isScanning = false;
          _scanStatusText = '';
        });
        _showErrorSnackBar(
          'Gagal mendeteksi total harga dari struk ini.\nCoba foto ulang dengan pencahayaan yang lebih baik.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _scanStatusText = '';
      });
      _showErrorSnackBar('Error saat proses OCR: $e');
    }
  }

  String _formatNumber(double n) {
    final s = n.toStringAsFixed(0);
    final result = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      result.write(s[i]);
      count++;
      if (count % 3 == 0 && i > 0) result.write('.');
    }
    return result.toString().split('').reversed.join();
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _runCameraCapture() async {
    try {
      final file = await _ocrService.pickImageFromCamera();
      if (!mounted) return;

      if (file != null) {
        _processSelectedImage(file);
      } else {
        // User cancelled camera — if first attempt, go back
        if (!_hasTriedCamera) {
          Navigator.pop(context);
          return;
        }
      }
      setState(() {
        _hasTriedCamera = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasTriedCamera = true;
      });
      _showErrorSnackBar('Gagal mengakses kamera: $e');
    }
  }

  void _runGalleryPick() async {
    try {
      final file = await _ocrService.pickImageFromGallery();
      if (!mounted) return;

      if (file != null) {
        _processSelectedImage(file);
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Gagal mengakses galeri: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background: captured image or dark placeholder
          if (_capturedImage != null)
            Positioned.fill(
              child: Image.file(
                _capturedImage!,
                fit: BoxFit.contain,
                color: _isScanning ? Colors.black.withValues(alpha: 0.3) : null,
                colorBlendMode: _isScanning ? BlendMode.darken : null,
              ),
            )
          else
            Container(color: Colors.grey.shade900),

          // Scanner Overlay (only visible when scanning)
          if (_isScanning)
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 290,
                    height: 380,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.6),
                          width: 2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            _scanStatusText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(),
                  ),
                  // Laser line animation
                  Positioned(
                    top: 10,
                    child: Container(
                      width: 270,
                      height: 3,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.6),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    )
                        .animate(
                            onPlay: (controller) =>
                                controller.repeat(reverse: true))
                        .moveY(
                            begin: 10,
                            end: 360,
                            duration: 1.5.seconds,
                            curve: Curves.easeInOut),
                  ),
                ],
              ),
            ),

          // UI Controls
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.x, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'Pindai Struk Belanja',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                // Bottom Bar Controls
                if (!_isScanning)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 32),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black87],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _capturedImage != null
                              ? 'Struk tidak terdeteksi. Coba lagi?'
                              : 'Pilih metode input struk belanja',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Gallery Option
                            _buildControlCircle(
                              icon: LucideIcons.image,
                              label: 'Galeri',
                              onTap: _runGalleryPick,
                            ),
                            // Camera Capture Button
                            GestureDetector(
                              onTap: _runCameraCapture,
                              child: Container(
                                width: 76,
                                height: 76,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 4),
                                  color:
                                      Colors.white.withValues(alpha: 0.15),
                                ),
                                child: Container(
                                  margin: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(LucideIcons.camera,
                                      color: Colors.black, size: 28),
                                ),
                              ),
                            ),
                            // Placeholder for symmetry
                            _buildControlCircle(
                              icon: LucideIcons.rotateCcw,
                              label: 'Ulangi',
                              onTap: _runCameraCapture,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlCircle({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onTap,
          icon: Icon(icon, color: Colors.white, size: 24),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.15),
            padding: const EdgeInsets.all(14),
            shape: const CircleBorder(),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }
}
