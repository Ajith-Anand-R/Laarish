import 'package:flutter/material.dart';
import '../../../content/models/level_content.dart';
import '../../../core/theme/laarish_text.dart';
import '../../../core/widgets/laarish_button.dart';
import 'minigame_common.dart';

/// game: "label" — canon labeling convention is "PLANT + date"
/// (CANON.md §1 "Wooden name labels").
class LabelGame extends StatefulWidget {
  const LabelGame({
    super.key,
    required this.step,
    required this.color,
    required this.plantId,
    required this.onComplete,
  });
  final LevelStep step;
  final Color color;
  final String plantId;
  final VoidCallback onComplete;

  @override
  State<LabelGame> createState() => _LabelGameState();
}

class _LabelGameState extends State<LabelGame> {
  bool _labeled = false;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final label = '${widget.plantId.toUpperCase()} · ${now.day}/${now.month}';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MinigamePrompt(text: widget.step.prompt ?? 'Label your cup!'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: widget.color, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(label, style: LaarishText.display22),
        ),
        const SizedBox(height: 16),
        if (!_labeled)
          LaarishButton(
            label: 'Stick label on',
            color: widget.color,
            onTap: () {
              setState(() => _labeled = true);
              widget.onComplete();
            },
          )
        else
          Text('Labeled!', style: LaarishText.body16),
      ],
    );
  }
}
