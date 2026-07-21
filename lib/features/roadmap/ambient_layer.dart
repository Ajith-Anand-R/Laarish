import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/motion/throttled_ticker.dart';
import '../../core/theme/laarish_colors.dart';

/// Parallax biome world behind the scrolling path — one pre-rendered 3D
/// garden scene per plant band (Tommy/Okki/Chilly/Methi), stacked in journey
/// order and locked to the scroll so each biome sits behind its own five
/// level nodes. Seams are feathered with a vertical alpha fade, and a faster
/// foliage strip rides in front for depth (DESIGN_SYSTEM.md §5.3/§6). The
/// animated sky/rays/particle shaders overlay this in RoadmapScreen.
class ParallaxBackground extends StatefulWidget {
  const ParallaxBackground({
    super.key,
    required this.scrollController,
    required this.plantOrder,
  });

  final ScrollController scrollController;
  final List<String> plantOrder;

  /// 5 nodes per plant × PathGeometry.nodeSpacing (170) — the content height
  /// of one biome band.
  static const _band = 5 * 170.0;

  @override
  State<ParallaxBackground> createState() => _ParallaxBackgroundState();
}

class _ParallaxBackgroundState extends State<ParallaxBackground> {
  bool _precached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precache biome + foliage art once so the first scroll doesn't pop/stutter.
    // Fail-soft: missing assets are expected on disk (onError swallows them).
    if (_precached) return;
    _precached = true;
    for (final id in widget.plantOrder) {
      precacheImage(AssetImage('assets/images/biome_$id.jpg'), context, onError: (_, _) {});
      precacheImage(AssetImage('assets/images/foliage_$id.png'), context, onError: (_, _) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final plantOrder = widget.plantOrder;
    const band = ParallaxBackground._band;
    // Each image/ShaderMask is built ONCE here (stable widget identity) and
    // handed to a per-frame Transform that only re-composites the cached layer.
    return RepaintBoundary(
      child: Stack(
        children: [
          // Vertical sky wash (top→horizon) so the world has depth even before
          // the biome art loads / where a band has none.
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [LaarishColors.skyTop, LaarishColors.skyBottom],
                ),
              ),
            ),
          ),
          // Biome scenes, locked to content so biome i sits behind plant i.
          for (var i = 0; i < plantOrder.length; i++)
            _ParallaxLayer(
              controller: widget.scrollController,
              topBase: i * band,
              factor: 1.0,
              height: band + 170,
              child: RepaintBoundary(child: _BiomeBand(plantId: plantOrder[i])),
            ),
          // Foreground foliage strip, slightly faster for parallax depth.
          for (var i = 0; i < plantOrder.length; i++)
            _ParallaxLayer(
              controller: widget.scrollController,
              topBase: (i + 1) * band - 96,
              factor: 1.05,
              height: 150,
              child: RepaintBoundary(
                child: IgnorePointer(
                  child: Image.asset(
                    'assets/images/foliage_${plantOrder[i]}.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.bottomCenter,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Positions a pre-built (stable) child at `topBase` and slides it vertically
/// with the scroll offset via `Transform.translate` — the framework never
/// rebuilds the child image; only the cheap transform is recomputed per frame.
/// Parallax math preserved: effective top = topBase - offset * factor.
class _ParallaxLayer extends StatelessWidget {
  const _ParallaxLayer({
    required this.controller,
    required this.topBase,
    required this.factor,
    required this.height,
    required this.child,
  });

  final ScrollController controller;
  final double topBase;
  final double factor;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final offset = controller.hasClients ? controller.offset : 0.0;
          return Transform.translate(
            offset: Offset(0, topBase - offset * factor),
            child: child,
          );
        },
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(width: double.infinity, height: height, child: child),
        ),
      ),
    );
  }
}

/// One biome scene image with feathered top/bottom edges so neighbouring
/// bands blend instead of hard-cutting. Fails soft to the biome tint.
class _BiomeBand extends StatelessWidget {
  const _BiomeBand({required this.plantId});
  final String plantId;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, Colors.white, Colors.white, Colors.transparent],
        stops: [0.0, 0.09, 0.9, 1.0],
      ).createShader(rect),
      child: Image.asset(
        'assets/images/biome_$plantId.jpg',
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, _, _) => ColoredBox(color: LaarishColors.biome[plantId] ?? LaarishColors.leaf),
      ),
    );
  }
}

/// Soft pulsing glow behind the current-node — CustomPaint radial gradient
/// animated via ThrottledTicker(30fps), standing in for the fragment shader
/// spec'd in DESIGN_SYSTEM.md §5.5 (no .frag assets exist yet).
class CurrentNodeGlow extends StatefulWidget {
  const CurrentNodeGlow({super.key, required this.color});
  final Color color;

  @override
  State<CurrentNodeGlow> createState() => _CurrentNodeGlowState();
}

class _CurrentNodeGlowState extends State<CurrentNodeGlow> with SingleTickerProviderStateMixin {
  late final ThrottledTicker _ticker;
  double _phase = 0;

  @override
  void initState() {
    super.initState();
    _ticker = ThrottledTicker(this, onTick: (elapsed) {
      setState(() => _phase = elapsed.inMilliseconds / 1000.0);
    })
      ..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pulse = 0.5 + 0.5 * math.sin(_phase * 2 * math.pi / 2.4);
    return IgnorePointer(
      child: CustomPaint(
        size: const Size(112, 112),
        painter: _GlowPainter(color: widget.color, pulse: pulse, phase: _phase),
      ),
    );
  }
}

class _GlowPainter extends CustomPainter {
  _GlowPainter({required this.color, required this.pulse, required this.phase});
  final Color color;
  final double pulse;
  final double phase;

  static const _sparkleCount = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 * (0.75 + 0.25 * pulse);
    final gradient = RadialGradient(
      colors: [color.withValues(alpha: 0.45 * pulse), color.withValues(alpha: 0.0)],
    );
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(center, radius, Paint()..shader = gradient.createShader(rect));

    // Sparkles orbiting the node — each twinkles on its own phase so the ring
    // shimmers rather than blinking in unison. Cheap: 4 tiny 4-point stars,
    // only redrawn at the ThrottledTicker's 30fps.
    final orbit = size.shortestSide / 2 * 0.42;
    for (var i = 0; i < _sparkleCount; i++) {
      final a = phase * 0.8 + i * (2 * math.pi / _sparkleCount);
      final twinkle = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(phase * 3 + i * 1.7));
      final pos = center + Offset(math.cos(a), math.sin(a)) * orbit;
      _drawSparkle(canvas, pos, 3.2 * twinkle, twinkle);
    }
  }

  void _drawSparkle(Canvas canvas, Offset c, double r, double alpha) {
    final paint = Paint()..color = LaarishColors.sunflower.withValues(alpha: alpha.clamp(0.0, 1.0));
    final star = Path()
      ..moveTo(c.dx, c.dy - r * 2)
      ..quadraticBezierTo(c.dx, c.dy, c.dx + r * 2, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r * 2)
      ..quadraticBezierTo(c.dx, c.dy, c.dx - r * 2, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r * 2)
      ..close();
    canvas.drawPath(star, paint);
  }

  @override
  bool shouldRepaint(covariant _GlowPainter oldDelegate) =>
      oldDelegate.pulse != pulse || oldDelegate.phase != phase;
}

/// 1-2 pooled critter sprites (butterfly/bee silhouettes) flying slow bezier
/// paths across the viewport. Fixed to the viewport (not scroll content) so
/// they read as "in the air" above the garden. Throttled to 30fps.
class CritterLayer extends StatefulWidget {
  const CritterLayer({super.key});

  @override
  State<CritterLayer> createState() => _CritterLayerState();
}

class _CritterLayerState extends State<CritterLayer> with SingleTickerProviderStateMixin {
  late final ThrottledTicker _ticker;
  double _t = 0;

  @override
  void initState() {
    super.initState();
    _ticker = ThrottledTicker(this, onTick: (elapsed) {
      setState(() => _t = elapsed.inMilliseconds / 1000.0);
    })
      ..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) => CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _CrittersPainter(t: _t),
        ),
      ),
    );
  }
}

class _CrittersPainter extends CustomPainter {
  _CrittersPainter({required this.t});
  final double t;

  static const _durations = [17.0, 13.0]; // seconds per loop, offset so they never sync
  static const _phaseOffsets = [0.0, 0.5];

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 2; i++) {
      final loopT = ((t / _durations[i]) + _phaseOffsets[i]) % 1.0;
      final p0 = Offset(-20, size.height * (0.2 + 0.3 * i));
      final p1 = Offset(size.width * 0.5, size.height * (0.05 + 0.5 * i));
      final p2 = Offset(size.width + 20, size.height * (0.35 + 0.2 * i));
      final pos = _quadBezier(p0, p1, p2, loopT);
      final bob = math.sin(loopT * math.pi * 8) * 6;
      _drawCritter(canvas, pos + Offset(0, bob), i.isEven ? LaarishColors.sunflowerDeep : LaarishColors.leafDeep);
    }
  }

  Offset _quadBezier(Offset p0, Offset p1, Offset p2, double t) {
    final x = (1 - t) * (1 - t) * p0.dx + 2 * (1 - t) * t * p1.dx + t * t * p2.dx;
    final y = (1 - t) * (1 - t) * p0.dy + 2 * (1 - t) * t * p1.dy + t * t * p2.dy;
    return Offset(x, y);
  }

  void _drawCritter(Canvas canvas, Offset pos, Color color) {
    final wing = Paint()..color = color.withValues(alpha: 0.85);
    canvas.drawOval(Rect.fromCenter(center: pos + const Offset(-4, 0), width: 10, height: 6), wing);
    canvas.drawOval(Rect.fromCenter(center: pos + const Offset(4, 0), width: 10, height: 6), wing);
    canvas.drawCircle(pos, 2, Paint()..color = LaarishColors.ink);
  }

  @override
  bool shouldRepaint(covariant _CrittersPainter oldDelegate) => oldDelegate.t != t;
}
