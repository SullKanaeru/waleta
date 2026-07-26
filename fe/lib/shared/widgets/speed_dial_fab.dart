import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';

/// A speed-dial style FAB that expands to 3 buttons: Scan, Add, Calculator
class SpeedDialFab extends StatefulWidget {
  final VoidCallback onScan;
  final VoidCallback onAdd;
  final VoidCallback onCalculator;

  const SpeedDialFab({
    super.key,
    required this.onScan,
    required this.onAdd,
    required this.onCalculator,
  });

  @override
  State<SpeedDialFab> createState() => _SpeedDialFabState();
}

class _SpeedDialFabState extends State<SpeedDialFab>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _controller;
  late Animation<double> _rotateAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _rotateAnim = Tween<double>(begin: 0, end: 0.375).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isOpen = !_isOpen);
    if (_isOpen) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _close() {
    setState(() => _isOpen = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Backdrop tap to close
        if (_isOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: _close,
              behavior: HitTestBehavior.translucent,
              child: Container(),
            ),
          ),

        // Left: Scan button
        if (_isOpen)
          Positioned(
            right: 64,
            child: _MiniFabButton(
              icon: LucideIcons.scanLine,
              label: 'Scan',
              onTap: () {
                _close();
                widget.onScan();
              },
            ),
          ).animate().slideX(begin: 0.5, end: 0).fadeIn(duration: 200.ms),

        // Center: Manual add button (already handled by main FAB when closed)
        if (_isOpen)
          _MiniFabButton(
            icon: LucideIcons.pencil,
            label: 'Manual',
            onTap: () {
              _close();
              widget.onAdd();
            },
            isCenter: true,
          ).animate().scale(begin: const Offset(0.5, 0.5)).fadeIn(duration: 200.ms),

        // Right: Calculator button
        if (_isOpen)
          Positioned(
            left: 64,
            child: _MiniFabButton(
              icon: LucideIcons.calculator,
              label: 'Kalkulator',
              onTap: () {
                _close();
                widget.onCalculator();
              },
            ),
          ).animate().slideX(begin: -0.5, end: 0).fadeIn(duration: 200.ms),

        // Main FAB
        GestureDetector(
          onTap: _isOpen ? _close : _toggle,
          child: AnimatedBuilder(
            animation: _rotateAnim,
            builder: (context, child) {
              return Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primaryLight, AppColors.primaryDark],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: _isOpen ? 0.5 : 0.35),
                      blurRadius: _isOpen ? 20 : 12,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Transform.rotate(
                  angle: _rotateAnim.value * 2 * 3.14159,
                  child: const Icon(LucideIcons.plus, color: Colors.white, size: 26),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MiniFabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isCenter;

  const _MiniFabButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isCenter = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isCenter ? AppColors.primary : AppColors.lightSurface,
              shape: BoxShape.circle,
              border: isCenter
                  ? null
                  : Border.all(color: AppColors.primary, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: isCenter ? Colors.white : AppColors.primary,
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
