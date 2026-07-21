import 'package:flutter/material.dart';
import '../fx/fx.dart';
import '../theme/laarish_colors.dart';
import '../theme/laarish_spacing.dart';

/// Guidebook sticker card: cream card, rounded-24, thin outline, layered
/// shadow. DESIGN_SYSTEM.md §3.
///
/// Now a real physical object rather than a flat rectangle:
///   • **two-layer shadow** — a tight contact shadow that grounds it plus a
///     wide ambient one; a single blur always reads as a sticker on glass;
///   • **inner bevel** — a light top edge and a dark bottom edge inside the
///     border, so the card has thickness;
///   • **[tilt]** — optional: the card turns in 3D with the finger and the
///     device, with a moving specular sheen (see [Tilt3D]);
///   • **[glow]** — optional biome halo for hero cards.
///
/// The default constructor call sites are untouched (`child`/`padding`/
/// `color` only); everything new is opt-in.
class StickerCard extends StatelessWidget {
  const StickerCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.elevation = 1.0,
    this.tilt = false,
    this.glow,
    this.radius = LaarishSpacing.cardRadius,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets? padding;
  final Color? color;

  /// 0.5 resting chip · 1 card · 2 floating hero.
  final double elevation;

  /// Turn in 3D with drag + device tilt. Use for the one hero card on a
  /// screen, not for every row.
  final bool tilt;

  /// Biome halo behind the card.
  final Color? glow;

  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final base = color ?? LaarishColors.bubble;

    Widget card = Container(
      padding: padding ?? const EdgeInsets.all(LaarishSpacing.md),
      decoration: BoxDecoration(
        // Very slight top-to-bottom lift so the card catches light like paper
        // curling toward the viewer.
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.alphaBlend(Colors.white.withValues(alpha: 0.55), base),
            base,
          ],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: LaarishColors.soil.withValues(alpha: 0.15),
          width: 2,
        ),
        boxShadow: DepthShadow.shadows(LaarishColors.soil, elevation),
      ),
      child: child,
    );

    // Inner bevel: bright hairline along the top, soft shade along the bottom.
    card = Stack(
      children: [
        card,
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.5),
                    Colors.white.withValues(alpha: 0.0),
                    LaarishColors.soil.withValues(alpha: 0.06),
                  ],
                  stops: const [0.0, 0.10, 1.0],
                ),
              ),
            ),
          ),
        ),
      ],
    );

    if (glow != null) {
      card = PulseGlow(
        color: glow!,
        radius: 24,
        intensity: 0.35,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(radius),
        child: card,
      );
    }

    if (tilt) {
      card = Tilt3D(maxTilt: 0.14, onTap: onTap, child: card);
    } else if (onTap != null) {
      card = MagneticTap(
        onTap: onTap!,
        borderRadius: BorderRadius.circular(radius),
        rippleColor: LaarishColors.sunflower.withValues(alpha: 0.5),
        child: card,
      );
    }

    return card;
  }
}
