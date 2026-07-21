import 'package:flutter/material.dart';
import '../../../core/theme/laarish_colors.dart';
import '../../../core/theme/laarish_spacing.dart';
import '../../../core/theme/laarish_text.dart';
import '../../../domain/gardener_rank.dart';

/// Small reusable "current rank" pill — GAMIFICATION.md §1 Gardener Rank
/// ladder. Other screens (garden home, profile) can drop this in later.
class GardenerRankBadge extends StatelessWidget {
  const GardenerRankBadge({super.key, required this.sunPoints});
  final int sunPoints;

  @override
  Widget build(BuildContext context) {
    final rank = gardenerRankFor(sunPoints);
    final next = rank.index < GardenerRank.values.length - 1
        ? GardenerRank.values[rank.index + 1]
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: LaarishSpacing.lg, vertical: LaarishSpacing.sm),
      decoration: BoxDecoration(
        color: LaarishColors.sunflower.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: LaarishColors.sunflowerDeep, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.workspace_premium_rounded, color: LaarishColors.sunflowerDeep, size: 22),
              const SizedBox(width: 6),
              Text(rank.title, style: LaarishText.display22.copyWith(fontSize: 18)),
            ],
          ),
          if (next != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '${next.threshold - sunPoints} Sun Points to ${next.title}',
                style: LaarishText.body16.copyWith(fontSize: 11, color: LaarishColors.soil),
              ),
            ),
        ],
      ),
    );
  }
}
