import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../content/models/level_content.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/fx/fx.dart';
import '../../../core/motion/throttled_ticker.dart';
import '../../../core/theme/laarish_colors.dart';
import '../../../core/theme/laarish_text.dart';
import 'minigame_common.dart';

/// game: "fill" — drag up to fill the cup/bag with soil, stopping at the
/// canon gap left at the top (LevelStep.target['gapMm'], e.g. "leave 10 mm
/// space" CANON.md §4).
///
/// Feel: the contents are a real liquid — a sloshing surface whose wave
/// amplitude tracks how fast you are dragging, settling as you slow down. The
/// target band glows and pulses; entering it snaps a magnetic "click" haptic
/// so the child can feel the right answer before reading it.
class FillGame extends StatefulWidget {
  const FillGame({super.key, required this.step, required this.color, required this.onComplete});
  final LevelStep step;
  final Color color;
  final VoidCallback onComplete;

  @override
  State<FillGame> createState() => _FillGameState();
}

class _FillGameState extends State<FillGame>
    with SingleTickerProviderStateMixin {
  double _level = 0; // 0..1
  double _slosh = 0; // 0..1 wave energy, decays when the drag settles
  bool _done = false;
  bool _wasInBand = false;
  final _vesselKey = GlobalKey();

  static const _targetBand = 0.82; // leaves a visible gap at the top
  static const _tolerance = 0.1;

  /// 30fps ambient clock for the liquid surface (slow drift → throttled).
  late final ThrottledTicker _clock;
  final _t = ValueNotifier<double>(0);

  int get _gapMm => (widget.step.target?['gapMm'] as num?)?.toInt() ?? 10;

  bool get _inBand => (_level - _targetBand).abs() <= _tolerance;

  @override
  void initState() {
    super.initState();
    _clock = ThrottledTicker(
      this,
      onTick: (e) {
        _t.value = e.inMilliseconds / 1000.0;
        // Waves calm down on their own once the drag stops feeding them.
        if (_slosh > 0.001) {
          _slosh *= 0.90;
          setState(() {});
        }
      },
    )..start();
  }

  @override
  void dispose() {
    _clock.dispose();
    _t.dispose();
    super.dispose();
  }

  void _onDrag(DragUpdateDetails d) {
    if (_done) return;
    setState(() {
      _level = (_level - d.delta.dy / 160).clamp(0.0, 1.0);
      // Fast drags make bigger waves — the liquid has inertia.
      _slosh = math.min(1.0, _slosh + d.delta.dy.abs() / 40);
    });
    // Magnetic detent: you feel the moment you cross into the sweet spot.
    if (_inBand != _wasInBand) {
      _wasInBand = _inBand;
      if (_inBand) HapticFeedback.selectionClick();
    }
  }

  void _onDragEnd(DragEndDetails d) {
    if (_done) return;
    if (_inBand) {
      setState(() => _done = true);
      AudioService.instance.play(Sfx.water);
      ShakeScope.go(context, intensity: 8, haptic: HapticImpact.heavy);
      FxBurst.atWidget(
        _vesselKey,
        color: widget.color,
        style: BurstStyle.celebrate,
      );
      widget.onComplete();
    } else {
      // Miss is never a failure — just a nudge back to try again.
      HapticFeedback.lightImpact();
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
          child: SizedBox(
            key: _vesselKey,
            width: 110,
            height: 180,
            child: AnimatedBuilder(
              animation: _t,
              builder: (context, _) => CustomPaint(
                painter: _VesselPainter(
                  level: _level,
                  slosh: _slosh,
                  time: _t.value,
                  color: widget.color,
                  targetBand: _targetBand,
                  tolerance: _tolerance,
                  inBand: _inBand,
                  done: _done,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _done
              ? 'Perfect mix!'
              : _inBand
                  ? 'Right there — let go!'
                  : 'Drag up to fill',
          style: LaarishText.body18.copyWith(
            color: _done || _inBand ? LaarishColors.leafDeep : LaarishColors.ink,
            fontWeight: _inBand ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Glass vessel + sloshing contents, drawn in one pass: glass body, liquid
/// with a sine surface, meniscus, specular streak on the glass, and a pulsing
/// target band.
class _VesselPainter extends CustomPainter {
  _VesselPainter({
    required this.level,
    required this.slosh,
    required this.time,
    required this.color,
    required this.targetBand,
    required this.tolerance,
    required this.inBand,
    required this.done,
  });

  final double level, slosh, time, targetBand, tolerance;
  final Color color;
  final bool inBand, done;

  @override
  void paint(Canvas canvas, Size size) {
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(6, 4, size.width - 12, size.height - 8),
      const Radius.circular(14),
    );

    // Glass interior.
    canvas.drawRRect(
      body,
      Paint()..color = LaarishColors.paperDeep.withValues(alpha: 0.55),
    );

    // Target band — pulses, and lights up green the moment you're inside it.
    final pulse = 0.5 + 0.5 * math.sin(time * 3.2);
    final bandTop = body.top + body.height * (1 - (targetBand + tolerance));
    final bandBottom = body.top + body.height * (1 - (targetBand - tolerance));
    final bandColor = inBand ? LaarishColors.leaf : LaarishColors.sunflower;
    canvas.drawRect(
      Rect.fromLTRB(body.left, bandTop, body.right, bandBottom),
      Paint()..color = bandColor.withValues(alpha: 0.14 + 0.14 * pulse),
    );
    for (final y in [bandTop, bandBottom]) {
      canvas.drawLine(
        Offset(body.left, y),
        Offset(body.right, y),
        Paint()
          ..color = bandColor.withValues(alpha: 0.65 + 0.35 * pulse)
          ..strokeWidth = 2,
      );
    }

    // Liquid with a wavy surface.
    if (level > 0.002) {
      final surfaceY = body.bottom - body.height * level;
      final amp = (1.5 + 6 * slosh).clamp(0.0, 8.0);
      final path = Path()..moveTo(body.left, body.bottom);
      for (double x = body.left; x <= body.right; x += 4) {
        final phase = (x / body.width) * math.pi * 2.2;
        final y = surfaceY +
            math.sin(phase + time * 4.5) * amp +
            math.sin(phase * 1.9 - time * 3.1) * amp * 0.4;
        path.lineTo(x, y);
      }
      path
        ..lineTo(body.right, body.bottom)
        ..close();

      canvas.save();
      canvas.clipRRect(body);
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(color, Colors.white, 0.35)!,
              color,
              Color.lerp(color, Colors.black, 0.28)!,
            ],
          ).createShader(body.outerRect),
      );
      // Meniscus highlight riding the surface.
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = Colors.white.withValues(alpha: 0.55),
      );
      canvas.restore();
    }

    // Glass rim and a specular streak so it reads as glass, not an outline.
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = done ? LaarishColors.leafDeep : color,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(body.left + 8, body.top + 10, 7, body.height - 34),
        const Radius.circular(6),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );
  }

  @override
  bool shouldRepaint(covariant _VesselPainter old) =>
      old.level != level ||
      old.slosh != slosh ||
      old.time != time ||
      old.inBand != inBand ||
      old.done != done ||
      old.color != color;
}
