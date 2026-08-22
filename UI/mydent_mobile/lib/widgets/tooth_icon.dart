import 'package:flutter/material.dart';

/// The MyDent brand mark — a gradient tooth silhouette, transcribed 1:1 from
/// the approved logo SVG (viewBox 0 0 40 44) so the in-app badge and the
/// generated Windows .ico / Android launcher icons are pixel-for-pixel the
/// same shape and gradient, not just similarly-colored icons.
///
/// Carries its own light-violet-to-purple gradient fill, so unlike a plain
/// [Icon] it needs a light backdrop (a white badge) rather than sitting
/// directly on the app's dark purple surfaces.
class ToothLogo extends StatelessWidget {
  const ToothLogo({super.key, this.width = 24});

  final double width;

  @override
  Widget build(BuildContext context) {
    final height = width * 44 / 40;
    return CustomPaint(
      size: Size(width, height),
      painter: _ToothPainter(),
    );
  }
}

class _ToothPainter extends CustomPainter {
  static const _gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFC4B5FD), Color(0xFF7C3AED)],
  );

  Path _toothPath(double s) {
    return Path()
      ..moveTo(8 * s, 4 * s)
      ..cubicTo(5.5 * s, 4 * s, 3 * s, 6 * s, 3 * s, 9.5 * s)
      ..cubicTo(3 * s, 13 * s, 4.5 * s, 16.5 * s, 6 * s, 19.5 * s)
      ..cubicTo(7.5 * s, 22.5 * s, 8 * s, 25 * s, 8.5 * s, 28.5 * s)
      ..cubicTo(9 * s, 32 * s, 9.5 * s, 36 * s, 11 * s, 38 * s)
      ..cubicTo(12 * s, 39.5 * s, 13 * s, 40 * s, 14 * s, 40 * s)
      ..cubicTo(15.5 * s, 40 * s, 16.5 * s, 37.5 * s, 17 * s, 35 * s)
      ..cubicTo(17.5 * s, 32.5 * s, 18 * s, 30 * s, 20 * s, 30 * s)
      ..cubicTo(22 * s, 30 * s, 22.5 * s, 32.5 * s, 23 * s, 35 * s)
      ..cubicTo(23.5 * s, 37.5 * s, 24.5 * s, 40 * s, 26 * s, 40 * s)
      ..cubicTo(27 * s, 40 * s, 28 * s, 39.5 * s, 29 * s, 38 * s)
      ..cubicTo(30.5 * s, 36 * s, 31 * s, 32 * s, 31.5 * s, 28.5 * s)
      ..cubicTo(32 * s, 25 * s, 32.5 * s, 22.5 * s, 34 * s, 19.5 * s)
      ..cubicTo(35.5 * s, 16.5 * s, 37 * s, 13 * s, 37 * s, 9.5 * s)
      ..cubicTo(37 * s, 6 * s, 34.5 * s, 4 * s, 32 * s, 4 * s)
      ..cubicTo(29.5 * s, 4 * s, 27.5 * s, 6 * s, 26 * s, 8 * s)
      ..cubicTo(24.5 * s, 6 * s, 22.5 * s, 4 * s, 20 * s, 4 * s)
      ..cubicTo(17.5 * s, 4 * s, 15.5 * s, 6 * s, 14 * s, 8 * s)
      ..cubicTo(12.5 * s, 6 * s, 10.5 * s, 4 * s, 8 * s, 4 * s)
      ..close();
  }

  Path _shinePath(double s) {
    return Path()
      ..moveTo(10 * s, 5.5 * s)
      ..cubicTo(8.2 * s, 6.5 * s, 6.5 * s, 8.5 * s, 5.5 * s, 11 * s)
      ..cubicTo(7 * s, 9.5 * s, 9 * s, 8 * s, 11.5 * s, 7 * s)
      ..cubicTo(12.5 * s, 5.8 * s, 13.5 * s, 4.5 * s, 14 * s, 4 * s)
      ..cubicTo(12.5 * s, 4 * s, 11.2 * s, 4.6 * s, 10 * s, 5.5 * s)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 40;
    final toothPath = _toothPath(s);

    final gradientPaint = Paint()
      ..shader = _gradient.createShader(Rect.fromLTWH(0, 0, 40 * s, 44 * s));
    canvas.drawPath(toothPath, gradientPaint);

    final shinePaint = Paint()..color = Colors.white.withValues(alpha: 0.45);
    canvas.drawPath(_shinePath(s), shinePaint);
  }

  @override
  bool shouldRepaint(covariant _ToothPainter oldDelegate) => false;
}
