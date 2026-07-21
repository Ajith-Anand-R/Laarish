import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../content/models/level_content.dart';
import '../../../core/theme/laarish_text.dart';
import 'minigame_common.dart';

/// game: "pour" — pour slowly in circles around the inside edge, never the
/// centre (CANON.md Rule 2, Phase 2 grow-bag watering). Drag in a circle;
/// each full lap fills the gauge. `target['ml']` is display-only text, never
/// a hardcoded canon number in Dart.
class PourGame extends StatefulWidget {
  const PourGame({super.key, required this.step, required this.color, required this.onComplete});
  final LevelStep step;
  final Color color;
  final VoidCallback onComplete;

  @override
  State<PourGame> createState() => _PourGameState();
}

class _PourGameState extends State<PourGame> {
  static const _lapsNeeded = 3;
  double _angleAccum = 0;
  double? _lastAngle;
  int _laps = 0;
  bool _done = false;

  int get _ml => (widget.step.target?['ml'] as num?)?.toInt() ?? 400;

  void _onPanUpdate(DragUpdateDetails d, Offset center) {
    if (_done) return;
    final v = d.localPosition - center;
    final angle = math.atan2(v.dy, v.dx);
    if (_lastAngle != null) {
      var delta = angle - _lastAngle!;
      if (delta > math.pi) delta -= 2 * math.pi;
      if (delta < -math.pi) delta += 2 * math.pi;
      _angleAccum += delta.abs();
      if (_angleAccum >= 2 * math.pi) {
        _angleAccum -= 2 * math.pi;
        setState(() => _laps++);
        HapticFeedback.lightImpact();
        if (_laps >= _lapsNeeded) {
          setState(() => _done = true);
          widget.onComplete();
        }
      }
    }
    _lastAngle = angle;
  }

  @override
  Widget build(BuildContext context) {
    const size = 140.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MinigamePrompt(text: widget.step.prompt ?? 'Pour $_ml ml slowly in circles!'),
        GestureDetector(
          onPanUpdate: (d) => _onPanUpdate(d, const Offset(size / 2, size / 2)),
          onPanEnd: (_) => _lastAngle = null,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: widget.color, width: 4)),
            child: Center(child: BiomeBlob(color: widget.color, icon: Icons.water_drop_rounded, size: 70)),
          ),
        ),
        const SizedBox(height: 12),
        ProgressBar(value: _laps / _lapsNeeded, color: widget.color),
        const SizedBox(height: 8),
        Text(_done ? 'Watch it drain — that means it\'s working!' : '$_laps / $_lapsNeeded circles', style: LaarishText.body16),
      ],
    );
  }
}
