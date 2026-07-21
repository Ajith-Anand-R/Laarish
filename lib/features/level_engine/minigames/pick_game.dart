import 'package:flutter/material.dart';
import '../../../content/models/level_content.dart';
import 'tap_progress_game.dart';

/// game: "pick" — harvest pluck (CANON.md "Pick when fully red" / "Snip
/// never twist"). Count from LevelStep.count/target, default 3.
class PickGame extends StatelessWidget {
  const PickGame({super.key, required this.step, required this.color, required this.onComplete});
  final LevelStep step;
  final Color color;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) => TapProgressGame(
        prompt: step.prompt ?? 'Pick when ready!',
        target: step.count ?? (step.target?['count'] as num?)?.toInt() ?? 3,
        color: color,
        icon: Icons.eco_rounded,
        onComplete: onComplete,
        completeLabel: 'Harvested!',
      );
}
