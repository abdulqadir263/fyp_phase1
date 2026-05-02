import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Google "G" brand icon drawn with CustomPainter — no external asset needed.
class GoogleSignInIcon extends StatelessWidget {
  final double size;
  const GoogleSignInIcon({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = size.width * 0.18;
    final arcRadius = radius * 0.78;

    final segments = [
      (const Color(0xFF4285F4), 0.0,  0.25),  // blue
      (const Color(0xFFEA4335), 0.25, 0.5),   // red
      (const Color(0xFFFBBC05), 0.5,  0.75),  // yellow
      (const Color(0xFF34A853), 0.75, 1.0),   // green
    ];

    for (final (color, start, end) in segments) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: arcRadius),
        start * 2 * math.pi - math.pi / 2,
        (end - start) * 2 * math.pi,
        false,
        paint,
      );
    }

    // White rectangle that creates the right-side notch of the "G"
    final cutPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(
        center.dx,
        center.dy - size.height * 0.12,
        radius,
        size.height * 0.24,
      ),
      cutPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
