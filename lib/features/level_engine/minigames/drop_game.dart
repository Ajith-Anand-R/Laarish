import 'package:flutter/material.dart';
import '../../../content/models/level_content.dart';
import 'tap_progress_game.dart';

/// game: "drop" — drop seeds into the hole. Count is content-driven
/// (LevelStep.count), defaulting to 2 (CANON.md §5 "Drop in 2 ... seeds").
class DropGame extends StatelessWidget {
  const DropGame({super.key, required this.step, required this.color, required this.onComplete});
  final LevelStep step;
  final Color color;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) => TapProgressGame(
        prompt: step.prompt ?? 'Drop in the seeds!',
        target: step.count ?? 2,
        color: color,
        icon: Icons.grain_rounded,
        onComplete: onComplete,
        completeLabel: 'Seeds in!',
      );
}
