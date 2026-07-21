import 'package:flutter/material.dart';
import '../../../content/models/level_content.dart';
import 'tap_progress_game.dart';

/// game: "scatter" — Methi's round-1/round-2 pinch-and-scatter sowing
/// (CANON.md §5 Methi: "SCATTER seeds", no hole).
class ScatterGame extends StatelessWidget {
  const ScatterGame({super.key, required this.step, required this.color, required this.onComplete});
  final LevelStep step;
  final Color color;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) => TapProgressGame(
        prompt: step.prompt ?? 'Scatter the seeds!',
        target: step.count ?? 8,
        color: color,
        icon: Icons.blur_on_rounded,
        onComplete: onComplete,
        completeLabel: 'Scattered!',
      );
}
