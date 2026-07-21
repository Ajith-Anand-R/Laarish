import 'package:flutter/material.dart';
import '../../../content/models/level_content.dart';
import 'tap_progress_game.dart';

/// game: "count" — tap-to-count the harvest basket. Count from
/// LevelStep.count/target, default 5.
class CountGame extends StatelessWidget {
  const CountGame({super.key, required this.step, required this.color, required this.onComplete});
  final LevelStep step;
  final Color color;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) => TapProgressGame(
        prompt: step.prompt ?? 'Count your harvest!',
        target: step.count ?? (step.target?['count'] as num?)?.toInt() ?? 5,
        color: color,
        icon: Icons.tag_rounded,
        onComplete: onComplete,
        completeLabel: 'All counted!',
      );
}
