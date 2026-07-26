import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';

/// A speed-dial style FAB that expands to 3 buttons floating in an arc above the navbar
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
      duration: const Duration(milliseconds: 250),
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
    if (!_isOpen) return;
    setState(() => _isOpen = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Backdrop overlay when open
        if (_isOpen)
          Positioned(
            top: -1000,
            bottom: -500,
            left: -500,
            right: -500,
            child: GestureDetector(
              onTap: _close,
              behavior: HitTestBehavior.opaque,
              child: Container(
                color: Colors.black.withValues(alpha: 0.35),
              ),
            ),
          ),

        // Left: Scan button (Arc position: Top -72, Right 60)
        if (_isOpen)
          Positioned(
            top: -72,
            right: 60,
            child: _MiniFabButton(
              icon: LucideIcons.scanLine,
              label: 'Scan',
              color: AppColors.accentGold,
              onTap: () {
                _close();
                widget.onScan();
              },
            ),
          ).animate().slideY(begin: 0.4, end: 0).fadeIn(duration: 180.ms),

        // Center: Manual add button (Arc position: Top -98)
        if (_isOpen)
          Positioned(
            top: -98,
            child: _MiniFabButton(
              icon: LucideIcons.pencil,
              label: 'Manual',
              color: AppColors.primary,
              onTap: () {
                _close();
                widget.onAdd();
              },
            ),
          ).animate().slideY(begin: 0.4, end: 0).fadeIn(duration: 180.ms),

        // Right: Calculator button (Arc position: Top -72, Left 60)
        if (_isOpen)
          Positioned(
            top: -72,
            left: 60,
            child: _MiniFabButton(
              icon: LucideIcons.calculator,
              label: 'Kalkulator',
              color: Colors.teal,
              onTap: () {
                _close();
                widget.onCalculator();
              },
            ),
          ).animate().slideY(begin: 0.4, end: 0).fadeIn(duration: 180.ms),

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
                      color: AppColors.primary.withValues(alpha: _isOpen ? 0.6 : 0.35),
                      blurRadius: _isOpen ? 18 : 12,
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
  final Color color;
  final VoidCallback onTap;

  const _MiniFabButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurface.withValues(alpha: 0.95)
                : AppColors.lightTextPrimary.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
