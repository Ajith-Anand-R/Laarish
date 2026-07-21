import 'package:flutter/material.dart';
import '../../core/theme/laarish_colors.dart';

/// "Growing vine" progress across the top of a level — fills green as steps
/// complete (DESIGN_SYSTEM.md §6 vine-sweep motif, scaled down for the level
/// header). No raw Material `LinearProgressIndicator` (AGENT.md "no default
/// Material chrome").
class VineProgress extends StatelessWidget {
  const VineProgress({super.key, required this.done, required this.total});
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final fraction = total == 0 ? 0.0 : (done / total).clamp(0.0, 1.0);
    return Row(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 14,
                decoration: BoxDecoration(color: LaarishColors.paperDeep, borderRadius: BorderRadius.circular(7)),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: fraction),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value,
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(color: LaarishColors.leaf, borderRadius: BorderRadius.circular(7)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.eco_rounded, color: LaarishColors.leafDeep, size: 22),
      ],
    );
  }
}
