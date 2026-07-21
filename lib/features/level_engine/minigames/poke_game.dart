import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../content/models/level_content.dart';
import '../../../core/theme/laarish_text.dart';
import 'minigame_common.dart';

/// game: "poke" — press and hold to poke the seed hole to canon depth
/// (LevelStep.target['depthMm'], e.g. "6 mm deep — Diggy checks!"
/// CANON.md §5). Release too early or too late and it resets, gently.
class PokeGame extends StatefulWidget {
  const PokeGame({super.key, required this.step, required this.color, required this.onComplete});
  final LevelStep step;
  final Color color;
  final VoidCallback onComplete;

  @override
  State<PokeGame> createState() => _PokeGameState();
}

class _PokeGameState extends State<PokeGame> {
  double _depth = 0; // 0..1
  bool _done = false;
  Timer? _ticker;

  int get _depthMm => (widget.step.target?['depthMm'] as num?)?.toInt() ?? 6;

  void _start() {
    if (_done) return;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 60), (_) {
      setState(() => _depth = (_depth + 0.08).clamp(0.0, 1.0));
    });
  }

  void _release() {
    _ticker?.cancel();
    if (_done) return;
    if (_depth >= 0.7) {
      setState(() => _done = true);
      HapticFeedback.mediumImpact();
      widget.onComplete();
    } else {
      setState(() => _depth = 0);
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MinigamePrompt(text: widget.step.prompt ?? 'Poke a hole $_depthMm mm deep!'),
        GestureDetector(
          onTapDown: (_) => _start(),
          onTapUp: (_) => _release(),
          onTapCancel: _release,
          child: BiomeBlob(color: widget.color, icon: Icons.height_rounded, size: 110),
        ),
        const SizedBox(height: 12),
        ProgressBar(value: _depth, color: widget.color),
        const SizedBox(height: 8),
        Text(
          _done ? "Diggy says perfect!" : 'Hold to poke, let go at the right depth',
          style: LaarishText.body16,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
