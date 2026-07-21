import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../content/models/level_content.dart';
import '../../../core/fx/fx.dart';
import '../../../core/theme/laarish_colors.dart';
import '../../../core/theme/laarish_text.dart';
import 'minigame_common.dart';

/// game: "snip" — drag scissors across the weaker sprout at soil level.
/// CANON.md Rule 4: "Never pull — pulling disturbs the roots of the one
/// you're keeping."
///
/// Feel: the scissors physically travel with the finger and rotate closed as
/// they bite, a cut line opens behind them, and a selection tick fires
/// continuously so the drag has texture rather than being a silent slide.
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
  final _propKey = GlobalKey();

  void _onDrag(DragUpdateDetails d) {
    if (_done) return;
    setState(() => _progress = (_progress + d.delta.dx.abs() / 140).clamp(0.0, 1.0));
    if (_progress >= 1.0) {
      setState(() => _done = true);
      celebrateMinigame(context, _propKey, widget.color);
      widget.onComplete();
    } else {
      // Continuous cutting feedback — the blade bites as it travels.
      HapticFeedback.selectionClick();
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
            key: _propKey,
            width: 200,
            height: 96,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, widget.color.withValues(alpha: 0.18)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: widget.color, width: 2),
              boxShadow: DepthShadow.shadows(widget.color, 0.9),
            ),
            child: CustomPaint(
              painter: _CutLinePainter(progress: _progress, color: widget.color),
              child: Align(
                // Scissors ride the cut, closing as they go.
                alignment: Alignment(-0.85 + 1.7 * _progress, 0),
                child: Transform.rotate(
                  angle: _progress * 0.9,
                  child: Icon(Icons.content_cut_rounded,
                      color: widget.color, size: 40),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ProgressBar(value: _progress, color: widget.color),
        const SizedBox(height: 8),
        Text(
          _done ? 'One cup = one plant.' : 'Drag scissors across',
          style: LaarishText.body16,
        ),
      ],
    );
  }
}

/// The severed line opening behind the blades — a dashed guide ahead of the
/// scissors, a solid cut behind them.
class _CutLinePainter extends CustomPainter {
  _CutLinePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final x0 = size.width * 0.08;
    final x1 = size.width * 0.92;
    final cutX = x0 + (x1 - x0) * progress;

    // Guide ahead: short dashes so it reads as "cut along here".
    for (double x = cutX; x < x1; x += 12) {
      canvas.drawLine(
        Offset(x, y),
        Offset((x + 6).clamp(x0, x1), y),
        Paint()
          ..color = LaarishColors.soil.withValues(alpha: 0.30)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }

    // Cut behind: a solid, slightly parted line.
    if (progress > 0.01) {
      for (final dy in [-2.0, 2.0]) {
        canvas.drawLine(
          Offset(x0, y + dy * progress),
          Offset(cutX, y + dy * progress),
          Paint()
            ..color = color
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CutLinePainter old) =>
      old.progress != progress || old.color != color;
}
