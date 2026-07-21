import 'package:flutter/material.dart';
import '../audio/audio_service.dart';
import '../fx/fx.dart';
import '../theme/laarish_colors.dart';
import '../theme/laarish_spacing.dart';
import '../theme/laarish_text.dart';

/// "Gummy" 3D button — DESIGN_SYSTEM.md §3, upgraded to AAA-casual standard.
/// This is the ONLY button widget in the app — no raw ElevatedButton/
/// TextButton on child-facing screens.
///
/// What every tap now gets, via [MagneticTap]:
///   magnetic pull toward the finger · squash & stretch · spring overshoot on
///   release · ripple from the exact touch point · haptic + sfx on the same
///   frame · optional particle spark.
///
/// What the surface itself carries:
///   a lit top bevel and dark rim (real gummy volume), a hard offset rim
///   shadow plus a soft ambient shadow (two-shadow depth), a travelling
///   specular sheen, and — for [hero] calls to action — a breathing glow so
///   the primary action always reads as *the* thing to press.
class LaarishButton extends StatelessWidget {
  const LaarishButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color = LaarishColors.sunflower,
    this.icon,
    this.enabled = true,
    this.hero = false,
    this.spark = true,
    this.sfx = Sfx.tap,
    this.expand = false,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;
  final IconData? icon;

  /// Disabled buttons dim and stop responding, but never disappear — a child
  /// should always see where the action will be.
  final bool enabled;

  /// Primary call to action: adds the breathing glow and a stronger sheen.
  /// At most one per screen.
  final bool hero;

  /// Fire a sparkle burst at the touch point on activation.
  final bool spark;
  final Sfx? sfx;

  /// Stretch to the full width of the parent.
  final bool expand;

  Color get _deep => Color.alphaBlend(Colors.black.withValues(alpha: 0.22), color);
  Color get _lit => Color.alphaBlend(Colors.white.withValues(alpha: 0.32), color);

  @override
  Widget build(BuildContext context) {
    Widget surface = Container(
      constraints: const BoxConstraints(minHeight: LaarishSpacing.minTapTarget),
      width: expand ? double.infinity : null,
      padding: const EdgeInsets.symmetric(
        horizontal: LaarishSpacing.xl,
        vertical: LaarishSpacing.md,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        // Three stops, not two: lit crown → body → shaded belly. That middle
        // break is what makes it read as a rounded gummy solid.
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_lit, color, _deep],
          stops: const [0.0, 0.52, 1.0],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 1.4),
        boxShadow: [
          // Hard rim underneath — the physical "thickness" of the key.
          BoxShadow(color: _deep, offset: const Offset(0, 5), blurRadius: 0),
          // Soft ambient contact shadow on the surface below it.
          BoxShadow(
            color: _deep.withValues(alpha: 0.45),
            offset: const Offset(0, 10),
            blurRadius: 18,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, shadows: const [
              Shadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 1)),
            ]),
            const SizedBox(width: LaarishSpacing.sm),
          ],
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: LaarishText.button.copyWith(
                shadows: const [
                  Shadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 1)),
                ],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    // Glossy top-half highlight, clipped to the pill — the wet-plastic look —
    // plus a travelling sheen so the button is never a dead shape.
    surface = ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: ShimmerSweep(
        strength: hero ? 0.5 : 0.26,
        period: Duration(milliseconds: hero ? 2600 : 4200),
        child: Stack(
          children: [
            surface,
            Positioned.fill(
              child: IgnorePointer(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: 0.46,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.38),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (hero) {
      surface = PulseGlow(
        color: color,
        radius: 22,
        intensity: 0.5,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(999),
        child: surface,
      );
    }

    if (!enabled) {
      // Dim rather than hide: the target stays discoverable.
      surface = Opacity(opacity: 0.45, child: surface);
    }

    return MagneticTap(
      enabled: enabled,
      onTap: onTap,
      spark: spark,
      sparkColor: color,
      sfx: sfx,
      borderRadius: BorderRadius.circular(999),
      rippleColor: Colors.white.withValues(alpha: 0.55),
      magnetStrength: 6,
      child: surface,
    );
  }
}
