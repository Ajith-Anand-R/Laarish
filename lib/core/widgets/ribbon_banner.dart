import 'package:flutter/material.dart';
import '../fx/fx.dart';
import '../theme/laarish_colors.dart';
import '../theme/laarish_spacing.dart';
import '../theme/laarish_text.dart';

/// Pill-shaped colored ribbon header — guidebook "PHASE 1 - NURSERY" style.
/// DESIGN_SYSTEM.md §3.
///
/// Premium pass: an embossed cloth ribbon rather than a flat pill — lit crown
/// and shaded belly, a bright inner hairline, layered shadow, a slow specular
/// sweep, and stitched end-caps that read as folded fabric tails.
class RibbonBanner extends StatelessWidget {
  const RibbonBanner({
    super.key,
    required this.text,
    this.color = LaarishColors.leafDeep,
    this.tails = true,
  });

  final String text;
  final Color color;

  /// Draw the folded fabric tails on either end.
  final bool tails;

  @override
  Widget build(BuildContext context) {
    final deep = Color.alphaBlend(Colors.black.withValues(alpha: 0.28), color);
    final lit = Color.alphaBlend(Colors.white.withValues(alpha: 0.28), color);

    final body = ShimmerSweep(
      strength: 0.32,
      period: const Duration(milliseconds: 5000),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: LaarishSpacing.lg,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [lit, color, deep],
            stops: const [0.0, 0.55, 1.0],
          ),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.45),
            width: 1.4,
          ),
          boxShadow: DepthShadow.shadows(LaarishColors.soil, 1.0),
        ),
        child: Text(
          text.toUpperCase(),
          style: LaarishText.display22.copyWith(
            color: Colors.white,
            fontSize: 16,
            letterSpacing: 0.6,
            shadows: [
              Shadow(color: deep, blurRadius: 3, offset: const Offset(0, 1)),
            ],
          ),
        ),
      ),
    );

    if (!tails) return body;

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Positioned(left: -14, child: _Tail(color: deep, flip: false)),
        Positioned(right: -14, child: _Tail(color: deep, flip: true)),
        body,
      ],
    );
  }
}

/// Folded-under ribbon tail — a notched trapezoid in the shadow tone.
class _Tail extends StatelessWidget {
  const _Tail({required this.color, required this.flip});

  final Color color;
  final bool flip;

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..scaleByDouble(flip ? -1 : 1, 1, 1, 1),
      child: CustomPaint(size: const Size(22, 26), painter: _TailPainter(color)),
    );
  }
}

class _TailPainter extends CustomPainter {
  _TailPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height * 0.16)
      ..lineTo(size.width * 0.42, size.height * 0.5) // the notch
      ..lineTo(0, size.height * 0.84)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..maskFilter = null,
    );
  }

  @override
  bool shouldRepaint(covariant _TailPainter old) => old.color != color;
}
