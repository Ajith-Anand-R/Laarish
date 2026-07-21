import 'package:flutter/material.dart';
import '../../content/models/level_content.dart';
import '../../core/widgets/laarish_button.dart';
import 'minigames/count_game.dart';
import 'minigames/drop_game.dart';
import 'minigames/fill_game.dart';
import 'minigames/label_game.dart';
import 'minigames/match_game.dart';
import 'minigames/minigame_common.dart';
import 'minigames/mist_game.dart';
import 'minigames/pick_game.dart';
import 'minigames/poke_game.dart';
import 'minigames/pour_game.dart';
import 'minigames/scatter_game.dart';
import 'minigames/snip_game.dart';
import 'minigames/soak_game.dart';

/// Maps `LevelStep.game` -> minigame widget (ARCHITECTURE.md §3.3 minigame
/// set). WS7 writes JSON `game` values matching these 12 keys exactly:
/// soak, fill, poke, drop, label, mist, pour, snip, scatter, pick, match, count.
Widget buildMinigame({
  required LevelStep step,
  required String plantId,
  required Color color,
  required VoidCallback onComplete,
}) {
  final game = _dispatchGame(step: step, plantId: plantId, color: color, onComplete: onComplete);
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (step.game != null) MinigamePropHeader(game: step.game!, color: color),
      game,
    ],
  );
}

Widget _dispatchGame({
  required LevelStep step,
  required String plantId,
  required Color color,
  required VoidCallback onComplete,
}) {
  switch (step.game) {
    case 'soak':
      return SoakGame(step: step, color: color, onComplete: onComplete);
    case 'fill':
      return FillGame(step: step, color: color, onComplete: onComplete);
    case 'poke':
      return PokeGame(step: step, color: color, onComplete: onComplete);
    case 'drop':
      return DropGame(step: step, color: color, onComplete: onComplete);
    case 'label':
      return LabelGame(step: step, color: color, plantId: plantId, onComplete: onComplete);
    case 'mist':
      return MistGame(step: step, color: color, onComplete: onComplete);
    case 'pour':
      return PourGame(step: step, color: color, onComplete: onComplete);
    case 'snip':
      return SnipGame(step: step, color: color, onComplete: onComplete);
    case 'scatter':
      return ScatterGame(step: step, color: color, onComplete: onComplete);
    case 'pick':
      return PickGame(step: step, color: color, onComplete: onComplete);
    case 'match':
      return MatchGame(step: step, color: color, onComplete: onComplete);
    case 'count':
      return CountGame(step: step, color: color, onComplete: onComplete);
    default:
      return _UnknownGame(step: step, color: color, onComplete: onComplete);
  }
}

/// Fail-soft fallback for an unrecognized/missing `game` key — never blocks
/// a child's level (ARCHITECTURE.md §3.7).
class _UnknownGame extends StatelessWidget {
  const _UnknownGame({required this.step, required this.color, required this.onComplete});
  final LevelStep step;
  final Color color;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MinigamePrompt(text: step.prompt ?? 'Let\'s keep going!'),
        LaarishButton(label: 'Continue', color: color, onTap: onComplete),
      ],
    );
  }
}
