import 'package:flutter/material.dart';
import '../fx/fx.dart';
import '../theme/laarish_colors.dart';
import '../theme/laarish_spacing.dart';
import '../theme/laarish_text.dart';

/// Sun Points / Seed Coins / streak counters. Dumb widget — screens feed it
/// values from ProgressController; this is the fly-to target for rewards
/// (AGENT.md "Celebrations" / GAMIFICATION.md).
///
/// Each chip is a small 3D token: radial-lit icon well, glossy pill, layered
/// shadow. When a value changes the chip **punches** (elastic scale) and the
/// number rolls up — so earning currency is visible even if the child has
/// already dismissed the reward overlay.
class HudBar extends StatelessWidget {
  const HudBar({
    super.key,
    required this.sunPoints,
    required this.seedCoins,
    required this.streak,
    this.sunKey,
    this.coinKey,
  });

  final int sunPoints;
  final int seedCoins;
  final int streak;

  /// Optional targets for the reward overlay's fly-to arc — pass a
  /// [GlobalKey] and read its render box centre.
  final GlobalKey? sunKey;
  final GlobalKey? coinKey;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _HudChip(
          key: sunKey,
          icon: Icons.wb_sunny_rounded,
          color: LaarishColors.sunflowerDeep,
          value: sunPoints,
        ),
        const SizedBox(width: LaarishSpacing.sm),
        _HudChip(
          key: coinKey,
          icon: Icons.eco_rounded,
          color: LaarishColors.leafDeep,
          value: seedCoins,
        ),
        const SizedBox(width: LaarishSpacing.sm),
        _HudChip(
          icon: Icons.local_fire_department_rounded,
          color: LaarishColors.tomato,
          value: streak,
          // A live streak is a status symbol — let it burn.
          glow: streak > 0,
        ),
      ],
    );
  }
}

class _HudChip extends StatelessWidget {
  const _HudChip({
    super.key,
    required this.icon,
    required this.color,
    required this.value,
    this.glow = false,
  });

  final IconData icon;
  final Color color;
  final int value;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    Widget chip = Container(
      padding: const EdgeInsets.fromLTRB(6, 5, 12, 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, LaarishColors.paperDeep],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
        boxShadow: DepthShadow.shadows(LaarishColors.soil, 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon sits in a lit circular well so it reads as an inset token.
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.35, -0.4),
                colors: [
                  Color.lerp(color, Colors.white, 0.55)!,
                  color,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.45),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 15, color: Colors.white),
          ),
          const SizedBox(width: 6),
          // Roll the number rather than snapping it — the count-up is half
          // the satisfaction of earning it.
          TweenAnimationBuilder<double>(
            // On rebuild TweenAnimationBuilder lerps from the *current*
            // displayed value to the new `end`, so this rolls on every change.
            tween: Tween(begin: 0, end: value.toDouble()),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => Text(
              '${v.round()}',
              style: LaarishText.body16.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    chip = ShimmerSweep(strength: 0.22, period: const Duration(seconds: 6), child: chip);

    if (glow) {
      chip = PulseGlow(
        color: color,
        radius: 12,
        intensity: 0.4,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(999),
        child: chip,
      );
    }

    // Punch whenever the number moves.
    return PopOnChange(value: value, scale: 1.28, child: chip);
  }
}
