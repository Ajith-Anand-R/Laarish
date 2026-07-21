import 'package:flutter/material.dart';
import '../theme/laarish_colors.dart';
import '../theme/laarish_spacing.dart';
import '../theme/laarish_text.dart';

/// Sun Points / Seed Coins / streak counters. Dumb widget — screens feed it
/// values from ProgressController; this is the fly-to target for rewards
/// (AGENT.md "Celebrations" / GAMIFICATION.md).
class HudBar extends StatelessWidget {
  const HudBar({
    super.key,
    required this.sunPoints,
    required this.seedCoins,
    required this.streak,
  });

  final int sunPoints;
  final int seedCoins;
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _chip(Icons.wb_sunny_rounded, LaarishColors.sunflowerDeep, '$sunPoints'),
        const SizedBox(width: LaarishSpacing.sm),
        _chip(Icons.eco_rounded, LaarishColors.leafDeep, '$seedCoins'),
        const SizedBox(width: LaarishSpacing.sm),
        _chip(Icons.local_fire_department_rounded, LaarishColors.tomato, '$streak'),
      ],
    );
  }

  Widget _chip(IconData icon, Color color, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: LaarishColors.bubble,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 4),
          Text(value, style: LaarishText.body16),
        ],
      ),
    );
  }
}
