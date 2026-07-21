import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../motion/throttled_ticker.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// Light: glows, animated gradients, sheen sweeps and depth shadows.
///
/// Everything here is composite-only (paint/shader work, no layout), and the
/// slow ambient ones run on [ThrottledTicker] at 30fps per the project perf
/// convention — full visual richness, half the CPU wake-ups.
/// ─────────────────────────────────────────────────────────────────────────

/// Breathing halo behind a widget — the "this is the thing to tap" beacon.
/// Two offset sine waves keep the pulse from looking mechanically periodic.
class PulseGlow extends StatefulWidget {
  const PulseGlow({
    super.key,
    required this.child,
    required this.color,
    this.radius = 26,
    this.intensity = 0.55,
    this.period = const Duration(milliseconds: 2200),
    this.shape = BoxShape.circle,
    this.borderRadius,
  });

  final Widget child;
  final Color color;
  final double radius;
  final double intensity;
  final Duration period;
  final BoxShape shape;
  final BorderRadius? borderRadius;

  @override
  State<PulseGlow> createState() => _PulseGlowState();
}

class _PulseGlowState extends State<PulseGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.period,
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final a = _c.value * math.pi * 2;
        // Two harmonics: a slow swell plus a faster shimmer on top.
        final pulse = 0.55 + 0.45 * (math.sin(a) * 0.7 + math.sin(a * 2.3) * 0.3);
        return DecoratedBox(
          decoration: BoxDecoration(
            shape: widget.shape,
            borderRadius:
                widget.shape == BoxShape.rectangle ? widget.borderRadius : null,
            boxShadow: [
              BoxShadow(
                color: widget.color
                    .withValues(alpha: widget.intensity * pulse * 0.85),
                blurRadius: widget.radius * (0.7 + 0.5 * pulse),
                spreadRadius: widget.radius * 0.12 * pulse,
              ),
              BoxShadow(
                color: widget.color.withValues(alpha: widget.intensity * 0.35),
                blurRadius: widget.radius * 2.1,
                spreadRadius: widget.radius * 0.3 * pulse,
              ),
            ],
          ),
          child: child,
        );
      },
    );
  }
}

/// Diagonal specular sweep that travels across a surface every few seconds —
/// the "premium glossy card" tell, straight out of Royal Match's UI.
class ShimmerSweep extends StatefulWidget {
  const ShimmerSweep({
    super.key,
    required this.child,
    this.period = const Duration(milliseconds: 3400),
    this.color = Colors.white,
    this.strength = 0.38,
    this.width = 0.22,
    this.enabled = true,
  });

  final Widget child;
  final Duration period;
  final Color color;
  final double strength;

  /// Band width as a fraction of the sweep travel.
  final double width;
  final bool enabled;

  @override
  State<ShimmerSweep> createState() => _ShimmerSweepState();
}

class _ShimmerSweepState extends State<ShimmerSweep>
    with SingleTickerProviderStateMixin {
  late final ThrottledTicker _ticker;
  final _t = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    final periodMs = widget.period.inMilliseconds;
    _ticker = ThrottledTicker(
      this,
      onTick: (e) => _t.value = (e.inMilliseconds % periodMs) / periodMs,
    );
    if (widget.enabled) _ticker.start();
  }

  @override
  void didUpdateWidget(covariant ShimmerSweep old) {
    super.didUpdateWidget(old);
    if (widget.enabled != old.enabled) {
      widget.enabled ? _ticker.start() : _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return ValueListenableBuilder<double>(
      valueListenable: _t,
      child: widget.child,
      builder: (context, t, child) {
        // The band only crosses during the first 45% of the cycle; the rest
        // is a rest beat so it reads as an occasional glint, not a strobe.
        final cross = (t / 0.45);
        if (cross > 1) return child!;
        final pos = -0.4 + cross * 1.8;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              widget.color.withValues(alpha: 0),
              widget.color.withValues(alpha: widget.strength),
              widget.color.withValues(alpha: 0),
            ],
            stops: [
              (pos - widget.width).clamp(0.0, 1.0),
              pos.clamp(0.0, 1.0),
              (pos + widget.width).clamp(0.0, 1.0),
            ],
          ).createShader(rect),
          child: child!,
        );
      },
    );
  }
}

/// A rotating multi-stop gradient ring — the premium "energised" border for
/// hero cards, current-level nodes and claim buttons.
class AuroraBorder extends StatefulWidget {
  const AuroraBorder({
    super.key,
    required this.child,
    required this.colors,
    this.thickness = 3,
    this.radius = 28,
    this.period = const Duration(milliseconds: 5200),
    this.glow = true,
  });

  final Widget child;
  final List<Color> colors;
  final double thickness;
  final double radius;
  final Duration period;
  final bool glow;

  @override
  State<AuroraBorder> createState() => _AuroraBorderState();
}

class _AuroraBorderState extends State<AuroraBorder>
    with SingleTickerProviderStateMixin {
  late final ThrottledTicker _ticker;
  final _t = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    final ms = widget.period.inMilliseconds;
    _ticker = ThrottledTicker(
      this,
      onTick: (e) => _t.value = (e.inMilliseconds % ms) / ms,
    )..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Close the loop so the sweep has no visible seam.
    final ring = [...widget.colors, widget.colors.first];
    return ValueListenableBuilder<double>(
      valueListenable: _t,
      child: widget.child,
      builder: (context, t, child) {
        final angle = t * math.pi * 2;
        return Container(
          padding: EdgeInsets.all(widget.thickness),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: SweepGradient(
              transform: GradientRotation(angle),
              colors: ring,
            ),
            boxShadow: widget.glow
                ? [
                    BoxShadow(
                      color: widget.colors[(t * widget.colors.length).floor() %
                              widget.colors.length]
                          .withValues(alpha: 0.45),
                      blurRadius: 22,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(widget.radius - widget.thickness),
            child: child,
          ),
        );
      },
    );
  }
}

/// Full-bleed animated mesh gradient — a slow, hypnotic colour field built
/// from three drifting radial blobs. Used as the base layer on hero screens
/// where a shader would be overkill (and as the shader's fail-soft).
class AnimatedMeshGradient extends StatefulWidget {
  const AnimatedMeshGradient({
    super.key,
    required this.colors,
    this.period = const Duration(seconds: 18),
    this.child,
  });

  /// Three or more colours; the first is the base wash.
  final List<Color> colors;
  final Duration period;
  final Widget? child;

  @override
  State<AnimatedMeshGradient> createState() => _AnimatedMeshGradientState();
}

class _AnimatedMeshGradientState extends State<AnimatedMeshGradient>
    with SingleTickerProviderStateMixin {
  late final ThrottledTicker _ticker;
  final _t = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    final ms = widget.period.inMilliseconds;
    _ticker = ThrottledTicker(
      this,
      onTick: (e) => _t.value = (e.inMilliseconds % ms) / ms,
    )..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _MeshPainter(t: _t, colors: widget.colors),
        size: Size.infinite,
        child: widget.child,
      ),
    );
  }
}

class _MeshPainter extends CustomPainter {
  _MeshPainter({required this.t, required this.colors}) : super(repaint: t);

  final ValueNotifier<double> t;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = colors.first);

    final a = t.value * math.pi * 2;
    final blobs = colors.length - 1;
    for (var i = 0; i < blobs; i++) {
      final phase = a + i * math.pi * 2 / blobs;
      // Lissajous drift — never repeats visibly within a session.
      final c = Offset(
        size.width * (0.5 + 0.34 * math.sin(phase * 1.0 + i)),
        size.height * (0.5 + 0.30 * math.cos(phase * 0.73 + i * 1.7)),
      );
      final r = size.longestSide * (0.42 + 0.10 * math.sin(phase * 1.4));
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [
              colors[i + 1].withValues(alpha: 0.85),
              colors[i + 1].withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromCircle(center: c, radius: r))
          ..blendMode = BlendMode.plus,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MeshPainter old) => old.colors != colors;
}

/// Layered soft shadows — one tight contact shadow plus one wide ambient
/// shadow. Real objects cast both; a single blurred shadow always reads flat.
class DepthShadow extends StatelessWidget {
  const DepthShadow({
    super.key,
    required this.child,
    this.color = const Color(0xFF7A5230),
    this.elevation = 1.0,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
  });

  final Widget child;
  final Color color;

  /// 0.5 = resting chip, 1 = card, 2 = floating hero.
  final double elevation;
  final BorderRadius? borderRadius;
  final BoxShape shape;

  static List<BoxShadow> shadows(Color color, double elevation) => [
        // Contact: tight, dark, close — grounds the object.
        BoxShadow(
          color: color.withValues(alpha: 0.22),
          blurRadius: 4 * elevation,
          offset: Offset(0, 2 * elevation),
        ),
        // Ambient: wide, soft, cheap fake GI.
        BoxShadow(
          color: color.withValues(alpha: 0.16),
          blurRadius: 18 * elevation,
          offset: Offset(0, 8 * elevation),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: shape,
        borderRadius: shape == BoxShape.rectangle ? borderRadius : null,
        boxShadow: shadows(color, elevation),
      ),
      child: child,
    );
  }
}
