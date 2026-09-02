import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:survival_calc/core/theme/outdoor_theme.dart';

/// Atmospheric dark-grey topographic contour lines background
class TopographicBackground extends StatelessWidget {
  final Widget child;
  final double opacity;

  const TopographicBackground({
    super.key,
    required this.child,
    this.opacity = 0.45,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            color: OutdoorTheme.darkBackground,
          ),
        ),
        Positioned.fill(
          child: Opacity(
            opacity: opacity,
            child: const CustomPaint(
              painter: _TopographicMapPainter(),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _TopographicMapPainter extends CustomPainter {
  const _TopographicMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF28343E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final indexLinePaint = Paint()
      ..color = const Color(0xFF384754)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Number of contour waves based on height
    const double stepY = 48.0;
    final int lineCount = (size.height / stepY).ceil() + 3;

    for (int i = 0; i < lineCount; i++) {
      final double baseY = i * stepY;
      final bool isIndexLine = i % 5 == 0;
      final paintToUse = isIndexLine ? indexLinePaint : linePaint;

      final path = Path();
      path.moveTo(0, baseY + _waveOffset(0, baseY, size.width));

      for (double x = 0; x <= size.width; x += 30) {
        final double yOffset = _waveOffset(x, baseY, size.width);
        path.lineTo(x, baseY + yOffset);
      }

      canvas.drawPath(path, paintToUse);

      // Draw elevation label on index lines
      if (isIndexLine && baseY > 60 && baseY < size.height - 40) {
        final elevation = 800 + (i * 50);
        final labelX = (size.width * 0.25 + (i * 70)) % (size.width - 80);
        final labelY = baseY + _waveOffset(labelX, baseY, size.width) - 6;

        textPainter.text = TextSpan(
          text: '$elevation m',
          style: const TextStyle(
            color: Color(0xFF4A5C6D),
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(labelX, labelY));
      }
    }

    // Topo peak concentric rings in top-right
    _drawTopoPeak(
      canvas,
      center: Offset(size.width * 0.85, size.height * 0.2),
      baseRadius: 160,
      ringCount: 6,
      linePaint: linePaint,
      indexPaint: indexLinePaint,
    );

    // Topo peak concentric rings in bottom-left
    _drawTopoPeak(
      canvas,
      center: Offset(size.width * 0.12, size.height * 0.75),
      baseRadius: 200,
      ringCount: 7,
      linePaint: linePaint,
      indexPaint: indexLinePaint,
    );
  }

  double _waveOffset(double x, double y, double width) {
    final double freq1 = 0.003;
    final double freq2 = 0.007;
    final double wave1 = math.sin(x * freq1 + y * 0.01) * 22.0;
    final double wave2 = math.cos(x * freq2 - y * 0.005) * 14.0;
    final double wave3 = math.sin((x + y) * 0.002) * 10.0;
    return wave1 + wave2 + wave3;
  }

  void _drawTopoPeak(
    Canvas canvas, {
    required Offset center,
    required double baseRadius,
    required int ringCount,
    required Paint linePaint,
    required Paint indexPaint,
  }) {
    for (int r = 1; r <= ringCount; r++) {
      final double radius = baseRadius * (1.0 - (r / (ringCount + 1)));
      final bool isIndex = r % 3 == 0;
      final paint = isIndex ? indexPaint : linePaint;

      final path = Path();
      const int segments = 36;
      for (int s = 0; s <= segments; s++) {
        final double angle = (s / segments) * 2 * math.pi;
        final double distortion =
            1.0 + 0.12 * math.sin(angle * 3) + 0.08 * math.cos(angle * 5);
        final double currentR = radius * distortion;
        final double x = center.dx + currentR * math.cos(angle);
        final double y = center.dy + currentR * math.sin(angle) * 0.65; // ellipse

        if (s == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
