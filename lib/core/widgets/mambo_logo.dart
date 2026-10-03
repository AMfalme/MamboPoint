import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The MamboPoint POS mark and wordmark.
///
/// The logo is drawn with a [CustomPainter] rather than shipped as a PNG so it
/// stays razor sharp on every density, scales to any size, and can be tinted for
/// light and dark surfaces without extra assets.
class MamboLogo extends StatelessWidget {
  const MamboLogo({
    super.key,
    this.markSize = 40,
    this.showWordmark = true,
    this.onDark = false,
  });

  /// Height of the symbol. The wordmark scales with it.
  final double markSize;

  /// Set to false for tight spots such as an app bar, where only the symbol is
  /// wanted.
  final bool showWordmark;

  /// Renders the wordmark in white for dark surfaces.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final Color wordmarkColor = onDark ? Colors.white : AppColors.brandTeal;
    final Color subColor = onDark
        ? Colors.white.withValues(alpha: 0.72)
        : const Color(0xFF5B7C8C);

    final Widget mark = MamboLogoMark(size: markSize);

    if (!showWordmark) return mark;

    return Semantics(
      label: 'MamboPoint POS',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            mark,
            SizedBox(width: markSize * 0.28),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'MamboPoint',
                  style: TextStyle(
                    color: wordmarkColor,
                    fontSize: markSize * 0.44,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    height: 1.05,
                  ),
                ),
                Text(
                  'POS',
                  style: TextStyle(
                    color: subColor,
                    fontSize: markSize * 0.3,
                    fontWeight: FontWeight.w400,
                    letterSpacing: markSize * 0.13,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Just the symbol, for places where the name is already obvious.
class MamboLogoMark extends StatelessWidget {
  const MamboLogoMark({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size.square(size),
      painter: const _MamboMarkPainter(),
    ),
  );
}

/// Draws the rising-trend arrow with the hexagon "nut" beneath its valley.
class _MamboMarkPainter extends CustomPainter {
  const _MamboMarkPainter();

  /// The mark is authored on a 100x100 grid and scaled to the widget, so every
  /// coordinate below stays readable.
  static const double _canvas = 100;

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = size.shortestSide / _canvas;
    canvas
      ..save()
      ..scale(scale);

    final Paint stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = const LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: <Color>[
          AppColors.brandTealDeep,
          AppColors.brandTeal,
          AppColors.brandMint,
        ],
        stops: <double>[0, 0.45, 1],
      ).createShader(const Rect.fromLTWH(0, 0, _canvas, _canvas));

    // Rising trend line: the valley at (53, 63) is where the hexagon hangs.
    canvas.drawPath(
      Path()
        ..moveTo(12, 70)
        ..lineTo(34, 42)
        ..lineTo(53, 63)
        ..lineTo(84, 22),
      stroke..strokeWidth = 9,
    );

    // Corner arrow head meeting the trend line at its tip.
    canvas.drawPath(
      Path()
        ..moveTo(62, 22)
        ..lineTo(84, 22)
        ..lineTo(84, 44),
      stroke..strokeWidth = 9,
    );

    // Hexagon nut under the valley.
    canvas.drawPath(
      _hexagon(center: const Offset(53, 84), radius: 12),
      stroke..strokeWidth = 7,
    );

    canvas.restore();
  }

  /// Pointy-top hexagon, the same silhouette the logo uses.
  Path _hexagon({required Offset center, required double radius}) {
    final Path path = Path();
    for (int i = 0; i < 6; i++) {
      final double angle = -math.pi / 2 + i * math.pi / 3;
      final Offset point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  @override
  bool shouldRepaint(_MamboMarkPainter oldDelegate) => false;
}
