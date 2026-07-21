import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// Camera: parallax, dynamic camera motion, motion-blur illusion.
///
/// All three read the *same* [ScrollPosition] the content is already using,
/// so nothing needs its own animation clock and everything stays perfectly in
/// phase with the finger.
/// ─────────────────────────────────────────────────────────────────────────

/// A background layer that scrolls slower (or faster) than the content in
/// front of it. [factor] < 1 = further away, > 1 = closer to the camera.
class ParallaxLayer extends StatelessWidget {
  const ParallaxLayer({
    super.key,
    required this.controller,
    required this.child,
    this.factor = 0.3,
    this.horizontal = false,
  });

  final ScrollController controller;
  final Widget child;
  final double factor;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: controller,
        child: child,
        builder: (context, child) {
          final offset = _safeOffset(controller);
          final d = -offset * factor;
          return Transform.translate(
            offset: horizontal ? Offset(d, 0) : Offset(0, d),
            child: child,
          );
        },
      ),
    );
  }
}

/// Reading `controller.offset` before the position has laid out throws a
/// null-check (the same class of crash the roadmap's `_RevealNode` guards
/// against). Every camera widget here funnels through this.
double _safeOffset(ScrollController c) {
  if (!c.hasClients) return 0;
  final p = c.position;
  if (!p.hasPixels) return 0;
  return p.pixels;
}

/// Per-frame scroll velocity, measured rather than read.
///
/// `ScrollPosition.activity.velocity` is `@protected` + `@visibleForTesting`,
/// so the supported way to get velocity outside a ScrollPosition subclass is
/// to differentiate the offset ourselves. Sampling on a [Ticker] (rather than
/// purely on the controller's listener) also means the value **decays to zero
/// when scrolling stops** — a listener-only version would freeze on its last
/// value and leave the camera stuck zoomed-out.
///
/// The sampler only runs while the view is actually moving: the controller's
/// listener wakes it, and it stops itself once the offset has been still for a
/// few frames. A permanently-running Ticker would keep a frame scheduled
/// forever — burning battery on an idle screen and hanging every
/// `pumpAndSettle`. It also notifies only on a meaningful velocity change, so
/// a slow scroll doesn't rebuild the camera every frame for nothing.
class ScrollMotion extends ChangeNotifier {
  ScrollMotion(this.controller, TickerProvider vsync) {
    _ticker = vsync.createTicker(_onFrame);
    controller.addListener(_wake);
  }

  final ScrollController controller;
  late final Ticker _ticker;

  /// Consecutive still frames seen; stop after [_stillFramesToSleep].
  int _stillFrames = 0;
  static const _stillFramesToSleep = 4;

  void _wake() {
    if (!_ticker.isActive) {
      _primed = false;
      _ticker.start();
    }
    _stillFrames = 0;
  }

  double _velocity = 0;
  double get velocity => _velocity;

  double _lastOffset = 0;
  Duration _lastStamp = Duration.zero;
  bool _primed = false;

  void _onFrame(Duration elapsed) {
    final offset = _safeOffset(controller);
    if (!_primed) {
      _primed = true;
      _lastOffset = offset;
      _lastStamp = elapsed;
      return;
    }
    final dt = (elapsed - _lastStamp).inMicroseconds / 1e6;
    _lastStamp = elapsed;
    if (dt <= 0) return;

    // Guard against a huge dt after a background/resume producing a bogus
    // velocity spike.
    final raw = dt > 0.1 ? 0.0 : (offset - _lastOffset) / dt;
    _lastOffset = offset;

    // Asymmetric smoothing: react fast to a fling, ease out slowly, so the
    // camera move has follow-through instead of snapping back.
    final k = raw.abs() > _velocity.abs() ? 0.45 : 0.12;
    final next = _velocity + (raw - _velocity) * k;
    final settled = next.abs() < 1.0 ? 0.0 : next;

    if ((settled - _velocity).abs() > 0.5 || (settled == 0 && _velocity != 0)) {
      _velocity = settled;
      notifyListeners();
    } else {
      _velocity = settled;
    }

    // Go back to sleep once the world has stopped moving.
    if (settled == 0 && raw == 0) {
      if (++_stillFrames >= _stillFramesToSleep) _ticker.stop();
    } else {
      _stillFrames = 0;
    }
  }

  @override
  void dispose() {
    controller.removeListener(_wake);
    _ticker.dispose();
    super.dispose();
  }
}

/// Rebuilds [builder] with the live scroll velocity. Owns the [ScrollMotion]
/// so callers stay stateless.
class ScrollMotionBuilder extends StatefulWidget {
  const ScrollMotionBuilder({
    super.key,
    required this.controller,
    required this.builder,
    this.child,
  });

  final ScrollController controller;
  final Widget Function(BuildContext context, double velocity, Widget? child)
      builder;
  final Widget? child;

  @override
  State<ScrollMotionBuilder> createState() => _ScrollMotionBuilderState();
}

class _ScrollMotionBuilderState extends State<ScrollMotionBuilder>
    with SingleTickerProviderStateMixin {
  late final ScrollMotion _motion = ScrollMotion(widget.controller, this);

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _motion,
        child: widget.child,
        builder: (context, child) =>
            widget.builder(context, _motion.velocity, child),
      );
}

/// Dynamic camera: the whole scroll body subtly pulls back and rolls when the
/// user flings, then eases home when it settles — the "the camera is on a
/// crane, not bolted to the wall" feel from Clash Royale's arena.
///
/// Pure composite: one [Transform] over a [RepaintBoundary]; the subtree never
/// rebuilds while the camera moves.
///
/// The [Transform] is emitted on **every** build, even at rest with an
/// identity matrix. Returning the bare child when idle would change the
/// widget structure, which re-inflates the whole subtree — and if that
/// subtree contains a scroll view, the freshly built Scrollable attaches the
/// [ScrollController] before the old one detaches, throwing
/// "ScrollController attached to multiple scroll views". A constant structure
/// is the whole reason this widget is safe to wrap a viewport with.
class ScrollCamera extends StatelessWidget {
  const ScrollCamera({
    super.key,
    required this.controller,
    required this.child,
    this.zoomOut = 0.045,
    this.roll = 0.012,
    this.maxVelocity = 4200,
  });

  final ScrollController controller;
  final Widget child;

  /// How far the camera dollies back at full fling speed (fraction of scale).
  final double zoomOut;

  /// Radians of roll at full fling speed.
  final double roll;
  final double maxVelocity;

  @override
  Widget build(BuildContext context) {
    return ScrollMotionBuilder(
      controller: controller,
      child: RepaintBoundary(child: child),
      builder: (context, v, child) {
        // Normalise with a soft knee so slow scrolls barely move the camera
        // and fast flings saturate instead of going comical.
        final t = (v.abs() / maxVelocity).clamp(0.0, 1.0);
        final e = Curves.easeOutCubic.transform(t);
        final scale = 1 - zoomOut * e;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0009)
            ..rotateZ(roll * e * v.sign)
            ..scaleByDouble(scale, scale, 1, 1),
          child: child,
        );
      },
    );
  }
}

/// Motion-blur illusion. Applies a *directional* gaussian blur whose sigma
/// tracks scroll velocity, so fast flings smear the way a real camera would
/// and a stationary list is pixel-sharp with zero cost.
///
/// **Must not wrap a scroll view.** Unlike [ScrollCamera], this widget
/// deliberately drops the [ImageFiltered] entirely below a velocity threshold
/// — an always-on filter would force a full-screen saveLayer every frame for
/// nothing. That structural change re-inflates the subtree, so a Scrollable
/// underneath would attach its controller twice
/// ("ScrollController attached to multiple scroll views"). Wrap the
/// decorative layers *behind* the scroll view instead: they smear on a fling,
/// which is where the effect reads anyway, and they own no controller.
///
/// ponytail: threshold-gated rather than always-on. If a future caller really
/// needs it around a Scrollable, give the filter a constant structure and eat
/// the idle saveLayer.
class VelocityBlur extends StatelessWidget {
  const VelocityBlur({
    super.key,
    required this.controller,
    required this.child,
    this.maxSigma = 6,
    this.maxVelocity = 5000,
    this.horizontal = false,
  });

  final ScrollController controller;
  final Widget child;
  final double maxSigma;
  final double maxVelocity;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    return ScrollMotionBuilder(
      controller: controller,
      child: child,
      builder: (context, velocity, child) {
        final v = velocity.abs();
        final t = (v / maxVelocity).clamp(0.0, 1.0);
        final sigma = maxSigma * t * t; // quadratic: only real flings smear
        if (sigma < 0.35) return child!;
        return ImageFiltered(
          imageFilter: ui.ImageFilter.blur(
            sigmaX: horizontal ? sigma : sigma * 0.15,
            sigmaY: horizontal ? sigma * 0.15 : sigma,
            tileMode: TileMode.decal,
          ),
          child: child,
        );
      },
    );
  }
}

/// Repeating scrolling band of a painted pattern — cheap infinite scenery
/// (hills, clouds, hedgerows) for parallax backdrops, no image assets needed.
class ScrollingBand extends StatelessWidget {
  const ScrollingBand({
    super.key,
    required this.controller,
    required this.color,
    this.factor = 0.18,
    this.height = 160,
    this.amplitude = 26,
    this.wavelength = 220,
    this.phase = 0,
  });

  final ScrollController controller;
  final Color color;
  final double factor;
  final double height;
  final double amplitude;
  final double wavelength;
  final double phase;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _BandPainter(
            scroll: _safeOffset(controller) * factor,
            color: color,
            height: height,
            amplitude: amplitude,
            wavelength: wavelength,
            phase: phase,
          ),
        ),
      ),
    );
  }
}

class _BandPainter extends CustomPainter {
  _BandPainter({
    required this.scroll,
    required this.color,
    required this.height,
    required this.amplitude,
    required this.wavelength,
    required this.phase,
  });

  final double scroll, height, amplitude, wavelength, phase;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Rolling hill silhouette, sampled every 8px — smooth enough at any width.
    final baseY = size.height - height + (scroll % (size.height + height));
    final path = Path()..moveTo(0, size.height);
    for (double x = 0; x <= size.width; x += 8) {
      final y = baseY +
          math.sin((x / wavelength) * math.pi * 2 + phase) * amplitude +
          math.sin((x / (wavelength * 0.37)) * math.pi * 2 + phase * 1.7) *
              amplitude *
              0.3;
      path.lineTo(x, y);
    }
    path
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _BandPainter old) =>
      old.scroll != scroll || old.color != color;
}
