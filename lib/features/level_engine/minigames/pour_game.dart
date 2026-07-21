import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../content/models/level_content.dart';
import '../../../core/fx/fx.dart';
import '../../../core/theme/laarish_colors.dart';
import '../../../core/theme/laarish_text.dart';
import 'minigame_common.dart';

/// game: "pour" — pour slowly in circles around the inside edge, never the
/// centre (CANON.md Rule 2, Phase 2 grow-bag watering). Drag in a circle;
/// each full lap fills the gauge. `target['ml']` is display-only text, never
/// a hardcoded canon number in Dart.
///
/// Feel: a glowing arc traces the finger around the rim so the child can see
/// the lap they are drawing, each completed lap pops with its own sparkle
/// burst, and the third one detonates.
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
  final _propKey = GlobalKey();

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
        if (_laps >= _lapsNeeded) {
          setState(() => _done = true);
          celebrateMinigame(context, _propKey, widget.color);
          widget.onComplete();
        } else {
          // Each completed lap is its own small win.
          HapticFeedback.mediumImpact();
          FxBurst.atWidget(_propKey,
              color: widget.color, style: BurstStyle.sparkle, intensity: 0.7);
        }
      } else {
        setState(() {}); // repaint the trace arc as the finger travels
      }
    }
    _lastAngle = angle;
  }

  @override
  Widget build(BuildContext context) {
    const size = 150.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MinigamePrompt(text: widget.step.prompt ?? 'Pour $_ml ml slowly in circles!'),
        GestureDetector(
          onPanUpdate: (d) => _onPanUpdate(d, const Offset(size / 2, size / 2)),
          onPanEnd: (_) => _lastAngle = null,
          child: SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              // The arc the child is currently drawing, painted under the prop.
              painter: _PourRingPainter(
                color: widget.color,
                sweep: _angleAccum,
                laps: _laps,
                lapsNeeded: _lapsNeeded,
              ),
              child: Center(
                child: KeyedSubtree(
                  key: _propKey,
                  child: BiomeBlob(
                    color: widget.color,
                    icon: Icons.water_drop_rounded,
                    size: 70,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ProgressBar(value: _laps / _lapsNeeded, color: widget.color),
        const SizedBox(height: 8),
        PopOnChange(
          value: _laps,
          child: Text(
            _done
                ? "Watch it drain — that means it's working!"
                : '$_laps / $_lapsNeeded circles',
            style: LaarishText.body16,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _PourRingPainter extends CustomPainter {
  _PourRingPainter({
    required this.color,
    required this.sweep,
    required this.laps,
    required this.lapsNeeded,
  });

  final Color color;
  final double sweep; // radians accumulated in the current lap
  final int laps;
  final int lapsNeeded;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.shortestSide / 2 - 6,
    );

    // Rim of the pot.
    canvas.drawCircle(
      rect.center,
      rect.width / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = color.withValues(alpha: 0.28),
    );

    // Water trace for the lap in progress.
    if (sweep > 0.02) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        sweep.clamp(0.0, math.pi * 2),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round
          ..shader = SweepGradient(
            colors: [
              Color.lerp(color, Colors.white, 0.6)!,
              color,
            ],
          ).createShader(rect),
      );
    }

    // Completed laps stack up as gold pips around the rim.
    for (var i = 0; i < lapsNeeded; i++) {
      final a = -math.pi / 2 + (i / lapsNeeded) * math.pi * 2;
      final p = rect.center + Offset.fromDirection(a, rect.width / 2);
      canvas.drawCircle(
        p,
        5,
        Paint()
          ..color = i < laps
              ? LaarishColors.sunflower
              : LaarishColors.soil.withValues(alpha: 0.25),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PourRingPainter old) =>
      old.sweep != sweep || old.laps != laps || old.color != color;
}
