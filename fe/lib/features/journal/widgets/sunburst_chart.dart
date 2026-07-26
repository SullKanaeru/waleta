import 'dart:math';
import 'package:flutter/material.dart';

class SunburstNode {
  final String label;
  final double value; // Can be absolute amount
  final Color color;
  final List<SunburstNode> children;

  SunburstNode({
    required this.label,
    required this.value,
    required this.color,
    this.children = const [],
  });
}

class SunburstChart extends StatelessWidget {
  final List<SunburstNode> data;
  final double totalValue;
  final String centerLabel;
  final String centerAmount;
  final double size;

  const SunburstChart({
    super.key,
    required this.data,
    required this.totalValue,
    required this.centerLabel,
    required this.centerAmount,
    this.size = 250,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _SunburstPainter(
              data: data,
              totalValue: totalValue,
              context: context,
            ),
          ),
          // Center content
          Container(
            width: size * 0.45, // Inner circle diameter
            height: size * 0.45,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                )
              ],
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    centerLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    centerAmount,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SunburstPainter extends CustomPainter {
  final List<SunburstNode> data;
  final double totalValue;
  final BuildContext context;

  _SunburstPainter({
    required this.data,
    required this.totalValue,
    required this.context,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Config
    final innerRadius = radius * 0.45;
    final middleRadius = radius * 0.75;
    final outerRadius = radius * 1.0;
    const gap = 0.02; // angular gap between slices

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    double startAngle = -pi / 2; // Start from top

    for (var master in data) {
      final sweepAngle = (master.value / totalValue) * 2 * pi;
      
      if (sweepAngle <= 0) continue;

      // Draw Master Slice (Inner Ring)
      paint.color = master.color;
      
      _drawDonutSlice(canvas, center, innerRadius, middleRadius, startAngle, sweepAngle - gap, paint);

      // Draw Pocket Slices (Outer Ring)
      if (master.children.isNotEmpty) {
        double childStartAngle = startAngle;
        for (var pocket in master.children) {
          final childSweepAngle = (pocket.value / totalValue) * 2 * pi;
          if (childSweepAngle <= 0) continue;

          // Make the pocket color a slightly altered version of master or just use master color with opacity
          paint.color = pocket.color; 
          
          _drawDonutSlice(canvas, center, middleRadius + 2, outerRadius, childStartAngle, childSweepAngle - (gap/2), paint);
          
          childStartAngle += childSweepAngle;
        }
      }

      startAngle += sweepAngle;
    }
  }

  void _drawDonutSlice(Canvas canvas, Offset center, double innerRadius, double outerRadius, double startAngle, double sweepAngle, Paint paint) {
    // We draw an arc using path to create a donut slice
    Path path = Path();
    path.arcTo(
      Rect.fromCircle(center: center, radius: outerRadius),
      startAngle,
      sweepAngle,
      true,
    );
    path.arcTo(
      Rect.fromCircle(center: center, radius: innerRadius),
      startAngle + sweepAngle,
      -sweepAngle,
      false,
    );
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
