import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../../core/theme/app_colors.dart';
import '../../../models/ocr_result.dart';
import '../../../services/ocr_service.dart';

class CameraScannerScreen extends StatefulWidget {
  const CameraScannerScreen({super.key});

  @override
  State<CameraScannerScreen> createState() => _CameraScannerScreenState();
}

class _CameraScannerScreenState extends State<CameraScannerScreen> {
  final _ocrService = OCRService();
  bool _isScanning = false;
  String _scanStatusText = '';

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  void _processSelectedImage(File imageFile) async {
    setState(() {
      _isScanning = true;
      _scanStatusText = 'Membaca gambar struk...';
    });

    try {
      final result = await _ocrService.processImage(imageFile);
      if (!mounted) return;

      if (result != null) {
        setState(() {
          _scanStatusText = 'Data struk berhasil diekstrak!';
        });
        await Future.delayed(const Duration(milliseconds: 800));
        if (!mounted) return;
        Navigator.pop(context, result);
      } else {
        setState(() {
          _isScanning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengekstrak total nominal dari struk ini. Silakan coba lagi.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saat proses OCR: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _runCameraCapture() async {
    try {
      final file = await _ocrService.pickImage();
      if (file != null) {
        _processSelectedImage(file);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengakses kamera: $e')),
      );
    }
  }

  void _simulateScan() async {
    setState(() {
      _isScanning = true;
      _scanStatusText = 'Mensimulasikan pembacaan struk (Mock)...';
    });
    
    // Simulate API/ML processing delay
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;

    final mockResult = OCRResult(
      totalAmount: 26500.0,
      date: DateFormat('dd/MM/yyyy').format(DateTime.now()),
      merchantName: 'Indomaret Utama',
      items: [
        {'name': 'Susu Bear Brand', 'price': 10500.0},
        {'name': 'Roti Tawar', 'price': 16000.0},
      ],
    );

    setState(() {
      _scanStatusText = 'Mock OCR sukses!';
    });

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    Navigator.pop(context, mockResult);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Simulated Camera View
          Container(color: Colors.grey.shade900),
          
          // Scanner Overlay
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 290,
                  height: 380,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white24, width: 2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: _isScanning
                      ? Column(
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
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ).animate().fadeIn()
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.scan, color: Colors.white.withValues(alpha: 0.3), size: 48),
                              const SizedBox(height: 12),
                              Text(
                                'Posisikan Struk Belanja\ndi dalam Kotak ini',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                ),
                // Laser line moving animation during scanning
                if (_isScanning)
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
                    .animate(onPlay: (controller) => controller.repeat(reverse: true))
                    .moveY(begin: 10, end: 360, duration: 1.5.seconds, curve: Curves.easeInOut),
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
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                // Bottom Bar Controls
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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
                      if (!_isScanning) ...[
                        Text(
                          'Pilih metode input struk belanja',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Gallery/Capture Option
                            _buildControlCircle(
                              icon: LucideIcons.image,
                              label: 'Galeri',
                              onTap: _runCameraCapture, // We can reuse pickImage
                            ),
                            // Capture Option
                            GestureDetector(
                              onTap: _runCameraCapture,
                              child: Container(
                                width: 76,
                                height: 76,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 4),
                                  color: Colors.white.withValues(alpha: 0.15),
                                ),
                                child: Container(
                                  margin: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(LucideIcons.camera, color: Colors.black, size: 28),
                                ),
                              ),
                            ),
                            // Simulation Option
                            _buildControlCircle(
                              icon: LucideIcons.sparkles,
                              label: 'Simulasi',
                              onTap: _simulateScan,
                            ),
                          ],
                        ),
                      ],
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