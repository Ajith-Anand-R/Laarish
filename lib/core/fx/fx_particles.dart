import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../motion/throttled_ticker.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// Particle FX — two systems, one file, zero packages.
///
/// 1. [ParticleField]  — ambient, always-on atmosphere (pollen, embers, snow,
///    fireflies, rising bubbles). Slow drift, so it runs on [ThrottledTicker]
///    at 30fps per the project perf convention (DESIGN_SYSTEM.md §5) — the
///    visuals are NOT reduced, only the update cadence of the drift.
///
/// 2. [FxBurst]        — imperative one-shot explosions fired at a screen
///    point on every satisfying event (correct answer, reward collect, node
///    unlock). Runs at full display rate because it is interaction feedback,
///    and lives in the root [Overlay] so it can paint above dialogs.
///
/// Both paint through a single [CustomPainter] over a [RepaintBoundary]: one
/// draw call per particle batch, no widget-per-particle, no layout cost.
/// ─────────────────────────────────────────────────────────────────────────

enum ParticleStyle {
  /// Drifting warm motes, gently rising — default garden air.
  pollen,

  /// Sparse cool sparkles that twinkle in and out.
  sparkle,

  /// Fast upward embers with a flicker — for chilli/heat biomes.
  ember,

  /// Slow floating orbs with soft edges — dreamy hero screens.
  bokeh,
}

/// Full-bleed ambient particle atmosphere. Drop into a [Stack] behind content.
///
/// Cheap by construction: [count] particles, one painter, one 30fps ticker,
/// wrapped in its own [RepaintBoundary] so it never dirties siblings.
class ParticleField extends StatefulWidget {
  const ParticleField({
    super.key,
    this.color = Colors.white,
    this.count = 26,
    this.style = ParticleStyle.pollen,
    this.speed = 1.0,
    this.opacity = 0.55,
    this.seed = 7,
  });

  final Color color;
  final int count;
  final ParticleStyle style;

  /// Multiplier on drift velocity — 0.5 dreamy, 2.0 lively.
  final double speed;
  final double opacity;

  /// Deterministic layout seed, so two fields on one screen differ.
  final int seed;

  @override
  State<ParticleField> createState() => _ParticleFieldState();
}

class _ParticleFieldState extends State<ParticleField>
    with SingleTickerProviderStateMixin {
  late final ThrottledTicker _ticker;
  final _time = ValueNotifier<double>(0);
  late List<_Mote> _motes;

  @override
  void initState() {
    super.initState();
    _motes = _buildMotes();
    _ticker = ThrottledTicker(
      this,
      onTick: (elapsed) => _time.value = elapsed.inMilliseconds / 1000.0,
    )..start();
  }

  List<_Mote> _buildMotes() {
    final rnd = math.Random(widget.seed);
    return List.generate(widget.count, (_) => _Mote.random(rnd, widget.style));
  }

  @override
  void didUpdateWidget(covariant ParticleField old) {
    super.didUpdateWidget(old);
    if (old.count != widget.count ||
        old.style != widget.style ||
        old.seed != widget.seed) {
      _motes = _buildMotes();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _FieldPainter(
            motes: _motes,
            time: _time,
            color: widget.color,
            style: widget.style,
            speed: widget.speed,
            opacity: widget.opacity,
          ),
        ),
      ),
    );
  }
}

/// One ambient particle. Position is a *function of time*, not integrated
/// state — so a dropped frame can never desync the field, and the painter
/// stays pure (no per-frame list mutation, no allocation in paint).
class _Mote {
  _Mote({
    required this.x,
    required this.y0,
    required this.size,
    required this.driftPhase,
    required this.driftAmp,
    required this.rise,
    required this.twinklePhase,
  });

  factory _Mote.random(math.Random r, ParticleStyle style) {
    final base = switch (style) {
      ParticleStyle.pollen => (0.9, 2.6, 0.030),
      ParticleStyle.sparkle => (0.7, 2.0, 0.018),
      ParticleStyle.ember => (0.8, 2.2, 0.085),
      ParticleStyle.bokeh => (3.0, 9.0, 0.012),
    };
    return _Mote(
      x: r.nextDouble(),
      y0: r.nextDouble(),
      size: base.$1 + r.nextDouble() * (base.$2 - base.$1),
      driftPhase: r.nextDouble() * math.pi * 2,
      driftAmp: 0.012 + r.nextDouble() * 0.05,
      rise: base.$3 * (0.6 + r.nextDouble() * 0.8),
      twinklePhase: r.nextDouble() * math.pi * 2,
    );
  }

  final double x; // 0..1 of width
  final double y0; // 0..1 start height
  final double size; // logical px radius
  final double driftPhase;
  final double driftAmp; // horizontal sway, fraction of width
  final double rise; // fraction of height per second, upward
  final double twinklePhase;
}

class _FieldPainter extends CustomPainter {
  _FieldPainter({
    required this.motes,
    required this.time,
    required this.color,
    required this.style,
    required this.speed,
    required this.opacity,
  }) : super(repaint: time);

  final List<_Mote> motes;
  final ValueNotifier<double> time;
  final Color color;
  final ParticleStyle style;
  final double speed;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final paint = Paint()..isAntiAlias = true;
    final soft = style == ParticleStyle.bokeh || style == ParticleStyle.pollen;
    if (soft) {
      paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2);
    }

    for (final m in motes) {
      // Wrap upward travel into 0..1 so motes cycle forever with no bookkeeping.
      final progress = (m.y0 - t * m.rise * speed) % 1.0;
      final y = progress * size.height;
      final sway = math.sin(t * 0.6 * speed + m.driftPhase) * m.driftAmp;
      final x = ((m.x + sway) % 1.0) * size.width;

      // Twinkle: sparkles blink hard, everything else pulses gently.
      final tw = math.sin(t * (style == ParticleStyle.sparkle ? 2.4 : 0.9) +
          m.twinklePhase);
      final alphaScale = style == ParticleStyle.sparkle
          ? (0.15 + 0.85 * (tw * 0.5 + 0.5)).clamp(0.0, 1.0)
          : (0.6 + 0.4 * (tw * 0.5 + 0.5));
      // Fade at the very top and bottom so nothing pops in/out at an edge.
      final edge = (math.min(progress, 1 - progress) / 0.12).clamp(0.0, 1.0);

      paint.color = color.withValues(alpha: opacity * alphaScale * edge);

      if (style == ParticleStyle.sparkle) {
        _drawSparkle(canvas, Offset(x, y), m.size * 2.2, paint);
      } else {
        canvas.drawCircle(Offset(x, y), m.size, paint);
      }
    }
  }

  /// Four-point star — the classic "shine" glyph, drawn as two thin lozenges.
  static void _drawSparkle(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx + r * 0.18, c.dy - r * 0.18, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx + r * 0.18, c.dy + r * 0.18, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx - r * 0.18, c.dy + r * 0.18, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx - r * 0.18, c.dy - r * 0.18, c.dx, c.dy - r)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _FieldPainter old) =>
      old.color != color ||
      old.opacity != opacity ||
      old.speed != speed ||
      old.style != style ||
      !identical(old.motes, motes);
}

/// ─────────────────────────────────────────────────────────────────────────
/// One-shot bursts
/// ─────────────────────────────────────────────────────────────────────────

enum BurstStyle {
  /// Radial confetti-ish shards with gravity — generic "yes!" pop.
  pop,

  /// Fine twinkling dust that floats up — gentle, for micro-interactions.
  sparkle,

  /// Heavy multi-colour celebration — reward collect, level complete.
  celebrate,

  /// A ring shock-wave plus shards — impact/unlock.
  shock,
}

/// Fires a particle burst at a **global** screen point, above everything else.
///
/// Safe to call from anywhere with a [BuildContext] under the app's [Overlay];
/// it self-removes when the animation finishes and no-ops if the overlay has
/// gone away. Fire-and-forget: callers never await or dispose anything.
///
/// ```dart
/// FxBurst.at(context, globalPosition, color: biome, style: BurstStyle.pop);
/// ```
class FxBurst {
  FxBurst._();

  static void at(
    BuildContext context,
    Offset globalPosition, {
    Color color = const Color(0xFFFFC93C),
    BurstStyle style = BurstStyle.pop,
    double intensity = 1.0,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _BurstLayer(
        origin: globalPosition,
        color: color,
        style: style,
        intensity: intensity,
        onDone: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  /// Convenience: burst from the centre of the widget owning [key].
  static void atWidget(
    GlobalKey key, {
    Color color = const Color(0xFFFFC93C),
    BurstStyle style = BurstStyle.pop,
    double intensity = 1.0,
  }) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    at(
      ctx,
      box.localToGlobal(box.size.center(Offset.zero)),
      color: color,
      style: style,
      intensity: intensity,
    );
  }
}

class _BurstLayer extends StatefulWidget {
  const _BurstLayer({
    required this.origin,
    required this.color,
    required this.style,
    required this.intensity,
    required this.onDone,
  });

  final Offset origin;
  final Color color;
  final BurstStyle style;
  final double intensity;
  final VoidCallback onDone;

  @override
  State<_BurstLayer> createState() => _BurstLayerState();
}

class _BurstLayerState extends State<_BurstLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final List<_Shard> _shards;
  late final List<Color> _palette;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random(widget.origin.dx.toInt() ^ widget.origin.dy.toInt());
    final spec = switch (widget.style) {
      BurstStyle.pop => (18, 900, 320.0, 1.0),
      BurstStyle.sparkle => (12, 750, 150.0, 0.15),
      BurstStyle.celebrate => (40, 1400, 460.0, 1.15),
      BurstStyle.shock => (24, 800, 420.0, 0.85),
    };
    final n = (spec.$1 * widget.intensity).round().clamp(4, 64);
    _c = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: spec.$2),
    );
    _shards = List.generate(
      n,
      (i) => _Shard.random(rnd, i, n, spec.$3 * widget.intensity, spec.$4),
    );
    final c = widget.color;
    _palette = [
      c,
      Color.lerp(c, Colors.white, 0.55)!,
      Color.lerp(c, const Color(0xFFFFC93C), 0.5)!,
      Colors.white,
    ];
    _c.forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _BurstPainter(
              origin: widget.origin,
              shards: _shards,
              palette: _palette,
              style: widget.style,
              t: _c,
            ),
          ),
        ),
      ),
    );
  }
}

/// A single burst shard with a launch velocity; motion is closed-form
/// (ballistic + drag), so the painter never mutates state.
class _Shard {
  _Shard({
    required this.vx,
    required this.vy,
    required this.size,
    required this.spin,
    required this.colorIndex,
    required this.gravity,
    required this.square,
  });

  factory _Shard.random(
    math.Random r,
    int i,
    int n,
    double speed,
    double gravity,
  ) {
    // Even angular spread + jitter, so a burst never looks clumped.
    final angle = (i / n) * math.pi * 2 + (r.nextDouble() - 0.5) * 0.6;
    final v = speed * (0.45 + r.nextDouble() * 0.75);
    return _Shard(
      vx: math.cos(angle) * v,
      vy: math.sin(angle) * v,
      size: 3.0 + r.nextDouble() * 5.0,
      spin: (r.nextDouble() - 0.5) * 10,
      colorIndex: r.nextInt(4),
      gravity: gravity * (260 + r.nextDouble() * 200),
      square: r.nextBool(),
    );
  }

  final double vx, vy, size, spin, gravity;
  final int colorIndex;
  final bool square;
}

class _BurstPainter extends CustomPainter {
  _BurstPainter({
    required this.origin,
    required this.shards,
    required this.palette,
    required this.style,
    required this.t,
  }) : super(repaint: t);

  final Offset origin;
  final List<_Shard> shards;
  final List<Color> palette;
  final BurstStyle style;
  final Animation<double> t;

  @override
  void paint(Canvas canvas, Size size) {
    final p = t.value;
    if (p <= 0) return;
    final paint = Paint()..isAntiAlias = true;

    // Shock-wave ring expands and thins out first, behind the shards.
    if (style == BurstStyle.shock) {
      final r = 12 + p * 130;
      canvas.drawCircle(
        origin,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8 * (1 - p)
          ..color = palette[1].withValues(alpha: (1 - p) * 0.7)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }

    // Flash at t≈0 — the "impact" frame that sells the hit.
    if (p < 0.22) {
      final f = 1 - p / 0.22;
      canvas.drawCircle(
        origin,
        30 + 60 * (1 - f),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.5 * f * f)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );
    }

    // Drag-damped ballistic travel: position eases out while gravity pulls in.
    final travel = Curves.easeOutCubic.transform(p);
    final fade = (1 - Curves.easeInCubic.transform(p)).clamp(0.0, 1.0);

    for (final s in shards) {
      final dx = s.vx * travel;
      final dy = s.vy * travel + s.gravity * travel * travel * 0.5;
      final pos = origin + Offset(dx, dy);
      paint.color = palette[s.colorIndex].withValues(alpha: fade);

      if (style == BurstStyle.sparkle) {
        _FieldPainter._drawSparkle(canvas, pos, s.size * (1.4 - 0.6 * p), paint);
      } else if (s.square) {
        canvas.save();
        canvas.translate(pos.dx, pos.dy);
        canvas.rotate(s.spin * travel);
        // Squash on the spin axis — reads as a tumbling flat confetti chip.
        final w = s.size * (0.4 + 0.6 * math.cos(s.spin * travel * 2).abs());
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: w * 2, height: s.size * 2),
            const Radius.circular(1.5),
          ),
          paint,
        );
        canvas.restore();
      } else {
        canvas.drawCircle(pos, s.size * (1 - 0.45 * p), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) => false; // repaint: t drives it
}
