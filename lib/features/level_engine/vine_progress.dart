import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/fx/fx.dart';
import '../../core/motion/laarish_motion.dart';
import '../../core/motion/throttled_ticker.dart';
import '../../core/theme/laarish_colors.dart';

/// "Growing vine" progress across the top of a level — DESIGN_SYSTEM.md §6
/// vine-sweep motif. No raw Material `LinearProgressIndicator`
/// (AGENT.md "no default Material chrome").
///
/// AAA pass: the fill is a living liquid — a gradient body with a travelling
/// specular highlight and a soft surface wave, a bright bead riding the
/// leading edge that leaves a glow trail, step pips that pop as they are
/// passed, and a leaf finial that swells and sparkles when the bar completes.
class VineProgress extends StatefulWidget {
  const VineProgress({
    super.key,
    required this.done,
    required this.total,
    this.color = LaarishColors.leaf,
  });

  final int done;
  final int total;
  final Color color;

  @override
  State<VineProgress> createState() => _VineProgressState();
}

class _VineProgressState extends State<VineProgress>
    with TickerProviderStateMixin {
  /// Drives the wave/shimmer inside the liquid — ambient, so 30fps.
  late final ThrottledClock _wave = ThrottledClock(this);

  /// The fill itself springs to its new value; it never linearly tweens.
  late final AnimationController _fill = AnimationController.unbounded(
    vsync: this,
    value: _fraction,
  );

  double get _fraction =>
      widget.total == 0 ? 0.0 : (widget.done / widget.total).clamp(0.0, 1.0);

  @override
  void didUpdateWidget(covariant VineProgress old) {
    super.didUpdateWidget(old);
    if (old.done != widget.done || old.total != widget.total) {
      _fill.animateWith(
        LaarishMotion.settle(
          _fill.value,
          _fraction,
          spring: LaarishMotion.heavy,
        ),
      );
    }
  }

  @override
  void dispose() {
    _wave.dispose();
    _fill.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final complete = widget.done >= widget.total && widget.total > 0;
    return Row(
      children: [
        Expanded(
          child: RepaintBoundary(
            child: SizedBox(
              height: 20,
              child: AnimatedBuilder(
                animation: Listenable.merge([_fill, _wave.listenable]),
                builder: (context, _) => CustomPaint(
                  size: Size.infinite,
                  painter: _VinePainter(
                    // The spring can overshoot past 1 / below 0 — clamp for
                    // painting but keep the overshoot in the bead's motion.
                    fill: _fill.value.clamp(0.0, 1.0),
                    raw: _fill.value,
                    t: _wave.value,
                    color: widget.color,
                    steps: widget.total,
                    done: widget.done,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Leaf finial: breathes normally, blooms and glows once the level's
        // steps are all done.
        PopOnChange(
          value: widget.done,
          scale: 1.4,
          child: complete
              ? PulseGlow(
                  color: LaarishColors.sunflower,
                  radius: 12,
                  intensity: 0.7,
                  child: const Icon(Icons.eco_rounded,
                      color: LaarishColors.leafDeep, size: 24),
                )
              : const Icon(Icons.eco_rounded,
                  color: LaarishColors.leafDeep, size: 22),
        ),
      ],
    );
  }
}

/// 30fps ambient clock exposed as a `Listenable`, so a widget can merge a
/// throttled ambient clock and a full-rate spring into one `AnimatedBuilder`.
/// Wraps the shared [ThrottledTicker] rather than re-implementing throttling.
class ThrottledClock {
  ThrottledClock(TickerProvider vsync, {int fps = 30}) {
    _ticker = ThrottledTicker(
      vsync,
      fps: fps,
      onTick: (elapsed) => _value.value = elapsed.inMilliseconds / 1000.0,
    )..start();
  }

  late final ThrottledTicker _ticker;
  final ValueNotifier<double> _value = ValueNotifier(0);

  double get value => _value.value;
  Listenable get listenable => _value;

  void dispose() {
    _ticker.dispose();
    _value.dispose();
  }
}

class _VinePainter extends CustomPainter {
  _VinePainter({
    required this.fill,
    required this.raw,
    required this.t,
    required this.color,
    required this.steps,
    required this.done,
  });

  final double fill;
  final double raw;
  final double t;
  final Color color;
  final int steps;
  final int done;

  @override
  void paint(Canvas canvas, Size size) {
    final barTop = size.height * 0.28;
    final barH = size.height * 0.44;
    final r = Radius.circular(barH / 2);
    final trackRect = Rect.fromLTWH(0, barTop, size.width, barH);
    final track = RRect.fromRectAndRadius(trackRect, r);

    // Track: recessed groove — dark inner edge sells the inset.
    canvas.drawRRect(track, Paint()..color = LaarishColors.paperDeep);
    canvas.drawRRect(
      track,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = LaarishColors.soil.withValues(alpha: 0.18),
    );

    if (fill > 0.001) {
      final w = math.max(barH, size.width * fill);
      final fillRect = Rect.fromLTWH(0, barTop, w, barH);
      final fillRRect = RRect.fromRectAndRadius(fillRect, r);

      canvas.save();
      canvas.clipRRect(fillRRect);

      // Liquid body.
      canvas.drawRect(
        fillRect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(color, Colors.white, 0.5)!,
              color,
              Color.lerp(color, Colors.black, 0.22)!,
            ],
          ).createShader(fillRect),
      );

      // Surface wave: a light band sliding along the top of the liquid.
      final wavePhase = (t * 0.55) % 1.0;
      final wx = fillRect.width * (wavePhase * 1.6 - 0.3);
      canvas.drawRect(
        fillRect,
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: 0.38),
              Colors.white.withValues(alpha: 0),
            ],
            stops: const [0.0, 0.5, 1.0],
            begin: Alignment(-1 + wx / math.max(1, fillRect.width) * 2 - 0.5, 0),
            end: Alignment(-1 + wx / math.max(1, fillRect.width) * 2 + 0.5, 0),
          ).createShader(fillRect),
      );

      // Top specular hairline — the meniscus.
      canvas.drawRect(
        Rect.fromLTWH(0, barTop, w, barH * 0.34),
        Paint()..color = Colors.white.withValues(alpha: 0.22),
      );
      canvas.restore();

      // Leading bead + glow trail. The bead tracks `raw`, so the spring's
      // overshoot is visible as the bead nosing past the fill and back.
      final beadX = (size.width * raw).clamp(barH * 0.5, size.width - barH * 0.2);
      final cy = barTop + barH / 2;
      canvas.drawCircle(
        Offset(beadX, cy),
        barH * 1.15,
        Paint()
          ..color = color.withValues(alpha: 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(
        Offset(beadX, cy),
        barH * 0.46,
        Paint()..color = Colors.white,
      );
    }

    // Step pips: hollow while pending, filled + haloed once passed.
    if (steps > 1) {
      for (var i = 1; i < steps; i++) {
        final x = size.width * (i / steps);
        final cy = barTop + barH / 2;
        final passed = i <= done;
        if (passed) {
          canvas.drawCircle(
            Offset(x, cy),
            barH * 0.5,
            Paint()
              ..color = Colors.white.withValues(alpha: 0.55)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
          );
        }
        canvas.drawCircle(
          Offset(x, cy),
          barH * 0.22,
          Paint()
            ..color = passed
                ? Colors.white
                : LaarishColors.soil.withValues(alpha: 0.28),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _VinePainter old) =>
      old.fill != fill ||
      old.raw != raw ||
      old.t != t ||
      old.color != color ||
      old.done != done ||
      old.steps != steps;
}
