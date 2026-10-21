import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A custom painter that draws authentic WhatsApp-style dark mode doodles
/// (chat bubbles, paper airplanes, cameras, coffee cups, clocks, headphones,
/// folders, documents, audio waves, sparkles, hearts) in a resolution-independent,
/// lightweight vector grid.
class WhatsAppDoodleBackground extends StatelessWidget {
  final Widget? child;
  final double opacity;
  final Color baseColor;

  const WhatsAppDoodleBackground({
    super.key,
    this.child,
    this.opacity = 0.045, // WhatsApp standard subtle opacity
    this.baseColor = const Color(0xFF0B141A),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: baseColor,
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: CustomPaint(
              painter: _WhatsAppDoodlePainter(opacity: opacity),
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

class _WhatsAppDoodlePainter extends CustomPainter {
  final double opacity;

  _WhatsAppDoodlePainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = Colors.white.withOpacity(opacity * 0.6)
      ..style = PaintingStyle.fill;

    const double cellSize = 80.0;
    final int cols = (size.width / cellSize).ceil() + 1;
    final int rows = (size.height / cellSize).ceil() + 1;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        // Deterministic pseudo-random seed per cell
        final int index = (r * 17 + c * 31) % 12;
        final double x = c * cellSize + ((r % 2 == 1) ? 20.0 : 40.0);
        final double y = r * cellSize + 40.0;

        canvas.save();
        canvas.translate(x, y);

        // Slight alternating tilt
        final double angle = ((r + c) % 3 - 1) * 0.12;
        canvas.rotate(angle);

        _drawDoodle(canvas, index, paint, fillPaint);
        canvas.restore();
      }
    }
  }

  void _drawDoodle(Canvas canvas, int type, Paint stroke, Paint fill) {
    switch (type) {
      case 0: // Chat speech bubble
        final rrect = RRect.fromRectAndRadius(
          const Rect.fromLTWH(-12, -9, 24, 18),
          const Radius.circular(5),
        );
        canvas.drawRRect(rrect, stroke);
        final path = Path()
          ..moveTo(-4, 9)
          ..lineTo(-8, 14)
          ..lineTo(-1, 9);
        canvas.drawPath(path, stroke);
        // Little dots inside
        canvas.drawCircle(const Offset(-4, 0), 1.2, fill);
        canvas.drawCircle(const Offset(0, 0), 1.2, fill);
        canvas.drawCircle(const Offset(4, 0), 1.2, fill);
        break;

      case 1: // Paper plane
        final path = Path()
          ..moveTo(12, 0)
          ..lineTo(-10, -9)
          ..lineTo(-4, 0)
          ..lineTo(-10, 9)
          ..close();
        canvas.drawPath(path, stroke);
        canvas.drawLine(const Offset(-4, 0), const Offset(12, 0), stroke);
        break;

      case 2: // Folder (MemChat Drive symbol)
        final path = Path()
          ..moveTo(-11, -7)
          ..lineTo(-5, -7)
          ..lineTo(-3, -4)
          ..lineTo(11, -4)
          ..lineTo(11, 7)
          ..lineTo(-11, 7)
          ..close();
        canvas.drawPath(path, stroke);
        canvas.drawLine(const Offset(-11, -2), const Offset(11, -2), stroke);
        break;

      case 3: // Coffee / Tea Cup
        final cup = Path()
          ..moveTo(-8, -6)
          ..lineTo(8, -6)
          ..lineTo(6, 6)
          ..arcToPoint(const Offset(-6, 6), radius: const Radius.circular(4))
          ..close();
        canvas.drawPath(cup, stroke);
        // Handle
        canvas.drawArc(
          const Rect.fromLTWH(6, -4, 6, 8),
          -math.pi / 2,
          math.pi,
          false,
          stroke,
        );
        // Steam
        canvas.drawLine(const Offset(-3, -11), const Offset(-3, -8), stroke);
        canvas.drawLine(const Offset(2, -11), const Offset(2, -8), stroke);
        break;

      case 4: // Camera
        final rrect = RRect.fromRectAndRadius(
          const Rect.fromLTWH(-11, -6, 22, 14),
          const Radius.circular(4),
        );
        canvas.drawRRect(rrect, stroke);
        canvas.drawCircle(const Offset(0, 1), 4, stroke);
        // Flash bump
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-4, -9, 8, 3),
            const Radius.circular(1.5),
          ),
          stroke,
        );
        break;

      case 5: // Clock / Time
        canvas.drawCircle(Offset.zero, 9, stroke);
        canvas.drawLine(Offset.zero, const Offset(0, -5), stroke);
        canvas.drawLine(Offset.zero, const Offset(4, 0), stroke);
        break;

      case 6: // Audio Headphones
        canvas.drawArc(
          const Rect.fromLTWH(-9, -10, 18, 16),
          math.pi,
          math.pi,
          false,
          stroke,
        );
        // Ear cups
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-11, -3, 4, 8),
            const Radius.circular(2),
          ),
          fill,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(7, -3, 4, 8),
            const Radius.circular(2),
          ),
          fill,
        );
        break;

      case 7: // Document / Note
        final path = Path()
          ..moveTo(-7, -10)
          ..lineTo(3, -10)
          ..lineTo(7, -6)
          ..lineTo(7, 10)
          ..lineTo(-7, 10)
          ..close();
        canvas.drawPath(path, stroke);
        canvas.drawLine(const Offset(-4, -2), const Offset(4, -2), stroke);
        canvas.drawLine(const Offset(-4, 2), const Offset(4, 2), stroke);
        canvas.drawLine(const Offset(-4, 6), const Offset(1, 6), stroke);
        break;

      case 8: // Sound wave / Mic
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-3, -8, 6, 11),
            const Radius.circular(3),
          ),
          stroke,
        );
        canvas.drawArc(
          const Rect.fromLTWH(-6, -4, 12, 10),
          0,
          math.pi,
          false,
          stroke,
        );
        canvas.drawLine(const Offset(0, 6), const Offset(0, 10), stroke);
        canvas.drawLine(const Offset(-4, 10), const Offset(4, 10), stroke);
        break;

      case 9: // Lock (Private / Zero-Server symbol)
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-7, -2, 14, 10),
            const Radius.circular(3),
          ),
          stroke,
        );
        canvas.drawArc(
          const Rect.fromLTWH(-4, -9, 8, 8),
          math.pi,
          math.pi,
          false,
          stroke,
        );
        canvas.drawCircle(const Offset(0, 3), 1.5, fill);
        break;

      case 10: // Star / Sparkle
        final path = Path()
          ..moveTo(0, -9)
          ..quadraticBezierTo(0, 0, 9, 0)
          ..quadraticBezierTo(0, 0, 0, 9)
          ..quadraticBezierTo(0, 0, -9, 0)
          ..quadraticBezierTo(0, 0, 0, -9);
        canvas.drawPath(path, fill);
        break;

      case 11: // Heart
        final path = Path()
          ..moveTo(0, 4)
          ..cubicTo(-7, -3, -9, -9, -4, -9)
          ..cubicTo(-1, -9, 0, -6, 0, -5)
          ..cubicTo(0, -6, 1, -9, 4, -9)
          ..cubicTo(9, -9, 7, -3, 0, 4);
        canvas.drawPath(path, stroke);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _WhatsAppDoodlePainter oldDelegate) =>
      oldDelegate.opacity != opacity;
}
