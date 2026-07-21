import 'package:flutter/material.dart';
import '../../../content/models/level_content.dart';
import 'tap_progress_game.dart';

/// game: "soak" — Corky soaks in water before filling (CANON.md §4 step 1).
/// Canon gives no tap count for the wait; tap-to-soak stands in for it.
class SoakGame extends StatelessWidget {
  const SoakGame({super.key, required this.step, required this.color, required this.onComplete});
  final LevelStep step;
  final Color color;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) => TapProgressGame(
        prompt: step.prompt ?? 'Soak Corky in water!',
        target: 5,
        color: color,
        icon: Icons.water_drop_rounded,
        onComplete: onComplete,
        completeLabel: 'Soaked!',
      );
}
