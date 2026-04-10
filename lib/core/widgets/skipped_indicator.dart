import 'package:flutter/material.dart';

class SkippedIndicator extends StatelessWidget {
  const SkippedIndicator({super.key});

  static const _size = 40.0;
  static const _stroke = 2.0;

  @override
  Widget build(BuildContext context) {
    const muted = Color(0xFF8C7A6B);
    final strokeColor = muted.withValues(alpha: 0.55);
    final iconColor = muted.withValues(alpha: 0.70);

    return SizedBox(
      width: _size,
      height: _size,
      child: CustomPaint(
        painter: _DashedCirclePainter(
          color: strokeColor,
          strokeWidth: _stroke,
        ),
        child: Center(
          child: Icon(
            Icons.calendar_month_outlined,
            size: 20,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  const _DashedCirclePainter({
    required this.color,
    required this.strokeWidth,
  });

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const dashCount = 22;
    const dashFraction = 0.45;
    final full = 2 * 3.141592653589793;
    final step = full / dashCount;
    final dash = step * dashFraction;

    for (var i = 0; i < dashCount; i++) {
      final start = i * step;
      canvas.drawArc(rect, start, dash, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}

