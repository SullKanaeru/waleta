import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
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

class _CameraScannerScreenState extends State<CameraScannerScreen>
    with WidgetsBindingObserver {
  final _ocrService = OCRService();

  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraReady = false;
  bool _isScanning = false;
  bool _hasFlash = false;
  bool _flashOn = false;
  String _scanStatusText = '';
  File? _capturedImage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ocrService.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (mounted) {
          _showErrorSnackBar('Tidak ada kamera yang tersedia di perangkat ini.');
        }
        return;
      }

      final backCamera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _cameraController = controller;
      await controller.initialize();

      if (!mounted) return;

      setState(() {
        _isCameraReady = true;
        _hasFlash =
            backCamera.lensDirection == CameraLensDirection.back;
      });
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Gagal mengakses kamera: $e');
      }
    }
  }

  Future<void> _captureAndProcess() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    if (_isScanning) return;

    try {
      // Turn off flash before capture if not needed
      final XFile photo = await _cameraController!.takePicture();
      final file = File(photo.path);

      await _processSelectedImage(file);
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Gagal mengambil foto: $e');
      }
    }
  }

  Future<void> _processSelectedImage(File imageFile) async {
    setState(() {
      _isScanning = true;
      _capturedImage = imageFile;
      _scanStatusText = 'Membaca struk...';
    });

    try {
      final result = await _ocrService.processImage(imageFile);
      if (!mounted) return;

      if (result != null) {
        setState(() {
          _scanStatusText =
              'Terdeteksi: Rp ${_formatNumber(result.totalAmount)}';
        });
        await Future.delayed(const Duration(milliseconds: 700));
        if (!mounted) return;
        Navigator.pop(context, result);
      } else {
        setState(() {
          _isScanning = false;
          _capturedImage = null;
          _scanStatusText = '';
        });
        _showErrorSnackBar(
          'Gagal mendeteksi harga. Pastikan struk terlihat jelas dan cukup cahaya.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _capturedImage = null;
        _scanStatusText = '';
      });
      _showErrorSnackBar('Error: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final file = await _ocrService.pickImageFromGallery();
      if (file != null && mounted) {
        await _processSelectedImage(file);
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar('Gagal membuka galeri: $e');
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    setState(() => _flashOn = !_flashOn);
    await _cameraController!.setFlashMode(
      _flashOn ? FlashMode.torch : FlashMode.off,
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Camera Preview ─────────────────────────────────────
          if (_isCameraReady && _cameraController != null && !_isScanning)
            Positioned.fill(
              child: CameraPreview(_cameraController!),
            )
          else if (_isScanning && _capturedImage != null)
            Positioned.fill(
              child: Image.file(
                _capturedImage!,
                fit: BoxFit.cover,
                color: Colors.black.withValues(alpha: 0.4),
                colorBlendMode: BlendMode.darken,
              ),
            )
          else
            Container(color: Colors.black),

          // ── Scanner frame overlay ───────────────────────────────
          if (!_isScanning)
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.45,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.7),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    // Corner brackets
                    ..._buildCornerBrackets(),
                  ],
                ),
              ),
            ),

          // ── Scanning overlay ────────────────────────────────────
          if (_isScanning)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _scanStatusText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 300.ms),
                ],
              ),
            ),

          // ── UI Controls ─────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Flash toggle
                      if (_hasFlash && !_isScanning)
                        IconButton(
                          icon: Icon(
                            _flashOn
                                ? LucideIcons.zap
                                : LucideIcons.zapOff,
                            color: _flashOn
                                ? AppColors.accentGold
                                : Colors.white,
                          ),
                          onPressed: _toggleFlash,
                        )
                      else
                        const SizedBox(width: 48),
                    ],
                  ),
                ),

                // Hint text below header
                if (!_isScanning) ...[
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Arahkan kamera ke struk belanja',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],

                const Spacer(),

                // Bottom controls
                if (!_isScanning)
                  Container(
                    padding: const EdgeInsets.only(
                        left: 32, right: 32, bottom: 40, top: 24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black87],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Galeri
                        _buildSideButton(
                          icon: LucideIcons.image,
                          label: 'Galeri',
                          onTap: _pickFromGallery,
                        ),

                        // Shutter button
                        GestureDetector(
                          onTap: _captureAndProcess,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white, width: 3.5),
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                            child: Container(
                              margin: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                LucideIcons.camera,
                                color: Colors.black,
                                size: 26,
                              ),
                            ),
                          ),
                        ),

                        // Ulangi (no-op placeholder or retry)
                        _buildSideButton(
                          icon: LucideIcons.rotateCcw,
                          label: 'Ulangi',
                          onTap: () {
                            setState(() {
                              _capturedImage = null;
                              _isScanning = false;
                              _scanStatusText = '';
                            });
                          },
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

  Widget _buildSideButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCornerBrackets() {
    const color = Colors.white;
    const len = 24.0;
    const thickness = 3.0;
    const radius = 6.0;

    Widget corner({
      required Alignment alignment,
      required bool left,
      required bool top,
    }) {
      return Align(
        alignment: alignment,
        child: Padding(
          padding: const EdgeInsets.all(0),
          child: SizedBox(
            width: len,
            height: len,
            child: CustomPaint(
              painter: _CornerPainter(
                color: color,
                thickness: thickness,
                radius: radius,
                isLeft: left,
                isTop: top,
              ),
            ),
          ),
        ),
      );
    }

    return [
      corner(alignment: Alignment.topLeft, left: true, top: true),
      corner(alignment: Alignment.topRight, left: false, top: true),
      corner(alignment: Alignment.bottomLeft, left: true, top: false),
      corner(alignment: Alignment.bottomRight, left: false, top: false),
    ];
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double thickness;
  final double radius;
  final bool isLeft;
  final bool isTop;

  _CornerPainter({
    required this.color,
    required this.thickness,
    required this.radius,
    required this.isLeft,
    required this.isTop,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final w = size.width;
    final h = size.height;

    if (isLeft && isTop) {
      path.moveTo(0, h);
      path.lineTo(0, radius);
      path.arcToPoint(Offset(radius, 0),
          radius: Radius.circular(radius), clockwise: true);
      path.lineTo(w, 0);
    } else if (!isLeft && isTop) {
      path.moveTo(0, 0);
      path.lineTo(w - radius, 0);
      path.arcToPoint(Offset(w, radius),
          radius: Radius.circular(radius), clockwise: true);
      path.lineTo(w, h);
    } else if (isLeft && !isTop) {
      path.moveTo(0, 0);
      path.lineTo(0, h - radius);
      path.arcToPoint(Offset(radius, h),
          radius: Radius.circular(radius), clockwise: false);
      path.lineTo(w, h);
    } else {
      path.moveTo(0, h);
      path.lineTo(w - radius, h);
      path.arcToPoint(Offset(w, h - radius),
          radius: Radius.circular(radius), clockwise: false);
      path.lineTo(w, 0);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
