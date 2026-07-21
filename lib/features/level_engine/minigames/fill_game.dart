import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../content/models/level_content.dart';
import '../../../core/theme/laarish_text.dart';
import 'minigame_common.dart';

/// game: "fill" — drag up to fill the cup/bag with soil, stopping at the
/// canon gap left at the top (LevelStep.target['gapMm'], e.g. "leave 10 mm
/// space" CANON.md §4).
class FillGame extends StatefulWidget {
  const FillGame({super.key, required this.step, required this.color, required this.onComplete});
  final LevelStep step;
  final Color color;
  final VoidCallback onComplete;

  @override
  State<FillGame> createState() => _FillGameState();
}

class _FillGameState extends State<FillGame> {
  double _level = 0; // 0..1
  bool _done = false;
  static const _targetBand = 0.82; // leaves a visible gap at the top
  static const _tolerance = 0.1;

  int get _gapMm => (widget.step.target?['gapMm'] as num?)?.toInt() ?? 10;

  void _onDrag(DragUpdateDetails d) {
    if (_done) return;
    setState(() => _level = (_level - d.delta.dy / 160).clamp(0.0, 1.0));
  }

  void _onDragEnd(DragEndDetails d) {
    if (_done) return;
    if ((_level - _targetBand).abs() <= _tolerance) {
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
        MinigamePrompt(text: widget.step.prompt ?? 'Fill with soil. Leave $_gapMm mm space!'),
        GestureDetector(
          onVerticalDragUpdate: _onDrag,
          onVerticalDragEnd: _onDragEnd,
          child: Container(
            width: 90,
            height: 160,
            decoration: BoxDecoration(
              border: Border.all(color: widget.color, width: 3),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.bottomCenter,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: FractionallySizedBox(
                heightFactor: _level,
                widthFactor: 1,
                child: Container(color: widget.color.withValues(alpha: 0.7)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(_done ? 'Perfect mix!' : 'Drag up to fill', style: LaarishText.body16),
      ],
    );
  }
}
