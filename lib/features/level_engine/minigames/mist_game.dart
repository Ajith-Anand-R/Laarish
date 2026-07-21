import 'package:flutter/material.dart';
import '../../../content/models/level_content.dart';
import 'tap_progress_game.dart';

/// game: "mist" — spray with Misty. CANON.md Rule 2: "10-15 sprays from
/// 10 cm above". Default 12, overridable via LevelStep.count.
class MistGame extends StatelessWidget {
  const MistGame({super.key, required this.step, required this.color, required this.onComplete});
  final LevelStep step;
  final Color color;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) => TapProgressGame(
        prompt: step.prompt ?? 'Mist with Misty!',
        target: step.count ?? 12,
        color: color,
        icon: Icons.water_rounded,
        onComplete: onComplete,
        completeLabel: 'Misted!',
      );
}
