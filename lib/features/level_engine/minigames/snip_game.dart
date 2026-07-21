import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../content/models/level_content.dart';
import '../../../core/theme/laarish_text.dart';
import 'minigame_common.dart';

/// game: "snip" — drag scissors across the weaker sprout at soil level.
/// CANON.md Rule 4: "Never pull — pulling disturbs the roots of the one
/// you're keeping."
class SnipGame extends StatefulWidget {
  const SnipGame({super.key, required this.step, required this.color, required this.onComplete});
  final LevelStep step;
  final Color color;
  final VoidCallback onComplete;

  @override
  State<SnipGame> createState() => _SnipGameState();
}

class _SnipGameState extends State<SnipGame> {
  double _progress = 0;
  bool _done = false;

  void _onDrag(DragUpdateDetails d) {
    if (_done) return;
    setState(() => _progress = (_progress + d.delta.dx.abs() / 140).clamp(0.0, 1.0));
    if (_progress >= 1.0) {
      setState(() => _done = true);
      HapticFeedback.mediumImpact();
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MinigamePrompt(text: widget.step.prompt ?? 'Snip the weaker sprout — never pull!'),
        GestureDetector(
          onHorizontalDragUpdate: _onDrag,
          child: Container(
            width: 180,
            height: 90,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.content_cut_rounded, color: widget.color, size: 40),
          ),
        ),
        const SizedBox(height: 12),
        ProgressBar(value: _progress, color: widget.color),
        const SizedBox(height: 8),
        Text(_done ? 'One cup = one plant.' : 'Drag scissors across', style: LaarishText.body16),
      ],
    );
  }
}
