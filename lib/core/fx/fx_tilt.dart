import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../motion/laarish_motion.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// 3D depth & perspective.
///
/// [DeviceTilt]  — ONE app-wide, low-rate accelerometer stream, exposed as a
///                 smoothed [ValueListenable]. Every parallax/tilt widget
///                 listens to this single source; per-widget sensor
///                 subscriptions would be a battery and jank disaster.
/// [Tilt3D]      — a card that turns in space: follows the finger while
///                 dragged, leans with the device when idle, and springs home
///                 on release. Includes a moving specular sheen so the tilt
///                 reads as a real lit surface, not just a skewed rectangle.
/// [DepthStack]  — layered z-parallax: children drift by different amounts
///                 against the same tilt, producing real depth separation.
/// ─────────────────────────────────────────────────────────────────────────

/// App-wide device-orientation source, normalised to roughly -1..1 on each
/// axis and heavily smoothed (raw accelerometer is far too noisy to drive UI).
class DeviceTilt {
  DeviceTilt._();

  static final DeviceTilt instance = DeviceTilt._();

  /// x = left/right lean, y = forward/back lean. Both ~-1..1.
  final ValueNotifier<Offset> value = ValueNotifier(Offset.zero);

  StreamSubscription<AccelerometerEvent>? _sub;
  int _listeners = 0;

  /// Ref-counted so the sensor is only powered while something on screen
  /// actually uses tilt.
  void acquire() {
    _listeners++;
    if (_sub != null) return;
    try {
      _sub = accelerometerEventStream(
        samplingPeriod: const Duration(milliseconds: 66), // ~15Hz is plenty
      ).listen(_onEvent, onError: (_) {});
    } catch (_) {
      // No accelerometer (desktop/web/emulator) — tilt just stays neutral.
    }
  }

  void release() {
    _listeners = math.max(0, _listeners - 1);
    if (_listeners == 0) {
      _sub?.cancel();
      _sub = null;
      value.value = Offset.zero;
    }
  }

  void _onEvent(AccelerometerEvent e) {
    // Gravity is ~9.8 on the down axis; divide to normalise, clamp to a
    // comfortable range, then exponentially smooth toward the target.
    final target = Offset(
      (-e.x / 9.8).clamp(-1.0, 1.0),
      ((e.y / 9.8) - 0.4).clamp(-1.0, 1.0),
    );
    value.value = Offset.lerp(value.value, target, 0.12)!;
  }
}

/// Mixin-free helper widget that keeps [DeviceTilt] alive for its lifetime.
class _TiltSubscriber extends StatefulWidget {
  const _TiltSubscriber({required this.builder});
  final Widget Function(BuildContext, Offset) builder;

  @override
  State<_TiltSubscriber> createState() => _TiltSubscriberState();
}

class _TiltSubscriberState extends State<_TiltSubscriber> {
  @override
  void initState() {
    super.initState();
    DeviceTilt.instance.acquire();
  }

  @override
  void dispose() {
    DeviceTilt.instance.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Offset>(
        valueListenable: DeviceTilt.instance.value,
        builder: (context, tilt, _) => widget.builder(context, tilt),
      );
}

/// A surface that lives in 3D: drag it to turn it, release and it springs
/// back with follow-through. Optional device-tilt idle lean makes the card
/// feel physically present even when untouched.
class Tilt3D extends StatefulWidget {
  const Tilt3D({
    super.key,
    required this.child,
    this.maxTilt = 0.22,
    this.perspective = 0.0014,
    this.useDeviceTilt = true,
    this.deviceTiltAmount = 0.35,
    this.sheen = true,
    this.liftOnTouch = 1.04,
    this.onTap,
  });

  final Widget child;

  /// Maximum rotation in radians at full drag.
  final double maxTilt;
  final double perspective;

  /// Lean gently with the phone when the user isn't touching the card.
  final bool useDeviceTilt;
  final double deviceTiltAmount;

  /// Draw a moving specular highlight across the surface as it turns.
  final bool sheen;

  /// Scale applied while touched — the card lifts toward the viewer.
  final double liftOnTouch;
  final VoidCallback? onTap;

  @override
  State<Tilt3D> createState() => _Tilt3DState();
}

class _Tilt3DState extends State<Tilt3D> with TickerProviderStateMixin {
  // Unbounded so the release spring can overshoot through zero and back.
  late final AnimationController _x =
      AnimationController.unbounded(vsync: this, value: 0);
  late final AnimationController _y =
      AnimationController.unbounded(vsync: this, value: 0);
  late final AnimationController _lift = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  );
  bool _dragging = false;
  Size _size = Size.zero;

  @override
  void dispose() {
    _x.dispose();
    _y.dispose();
    _lift.dispose();
    super.dispose();
  }

  /// Measure from the render object rather than LayoutBuilder constraints —
  /// a card inside a scroll view has an infinite max height, which would make
  /// the normalised drag maths degenerate.
  void _measure() {
    final box = context.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) _size = box.size;
  }

  void _updateFromLocal(Offset local) {
    if (_size.isEmpty || !_size.isFinite) return;
    // -1..1 across the card, so the corner you grab is the corner that dips.
    final nx = ((local.dx / _size.width) * 2 - 1).clamp(-1.0, 1.0);
    final ny = ((local.dy / _size.height) * 2 - 1).clamp(-1.0, 1.0);
    _x.value = -ny; // pushing down at the top tips the top away
    _y.value = nx;
  }

  void _start(Offset local) {
    _dragging = true;
    _lift.forward();
    _measure();
    _updateFromLocal(local);
  }

  void _end() {
    _dragging = false;
    _lift.reverse();
    // Follow-through: springs past centre before settling, like real mass.
    _x.animateWith(SpringSimulation(LaarishMotion.magnet, _x.value, 0, 0));
    _y.animateWith(SpringSimulation(LaarishMotion.magnet, _y.value, 0, 0));
  }

  @override
  Widget build(BuildContext context) {
    Widget core = AnimatedBuilder(
      animation: Listenable.merge([_x, _y, _lift]),
      child: widget.child,
      builder: (context, child) => _build(child!, Offset.zero),
    );

    if (widget.useDeviceTilt) {
      core = _TiltSubscriber(
        builder: (context, device) => AnimatedBuilder(
          animation: Listenable.merge([_x, _y, _lift]),
          child: widget.child,
          builder: (context, child) => _build(
            child!,
            _dragging ? Offset.zero : device * widget.deviceTiltAmount,
          ),
        ),
      );
    }

    // Raw [Listener], NOT a pan GestureDetector: a pan recogniser would enter
    // the gesture arena and beat the enclosing scroll view, so a card in a
    // ScrollView could no longer be scrolled by dragging it. A Listener
    // observes pointer movement without ever claiming the gesture, so tilt
    // and scroll happen at the same time.
    return Listener(
      behavior: HitTestBehavior.deferToChild,
      onPointerDown: (e) => _start(_toLocal(e.position)),
      onPointerMove: (e) => _updateFromLocal(_toLocal(e.position)),
      onPointerUp: (_) => _end(),
      onPointerCancel: (_) => _end(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: core,
      ),
    );
  }

  /// Listener reports global coordinates; the tilt maths is in card space.
  Offset _toLocal(Offset global) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return Offset.zero;
    return box.globalToLocal(global);
  }

  Widget _build(Widget child, Offset device) {
    final rx = (_x.value + device.dy) * widget.maxTilt;
    final ry = (_y.value + device.dx) * widget.maxTilt;
    final lift = 1 + (widget.liftOnTouch - 1) * _lift.value;

    Widget surface = child;
    if (widget.sheen) {
      // Specular band whose position tracks the surface normal — this is what
      // sells "glossy 3D object" instead of "rotated PNG".
      final sx = (ry / widget.maxTilt).clamp(-1.0, 1.0);
      final sy = (-rx / widget.maxTilt).clamp(-1.0, 1.0);
      final strength = (math.sqrt(sx * sx + sy * sy) / 1.4).clamp(0.0, 1.0);
      surface = Stack(
        fit: StackFit.passthrough,
        children: [
          child,
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-sx - 0.6, -sy - 0.6),
                    end: Alignment(-sx + 0.9, -sy + 0.9),
                    colors: [
                      Colors.white.withValues(alpha: 0.0),
                      Colors.white.withValues(alpha: 0.30 * strength),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                    stops: const [0.30, 0.50, 0.70],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, widget.perspective)
        ..rotateX(rx)
        ..rotateY(ry)
        ..scaleByDouble(lift, lift, 1, 1),
      child: surface,
    );
  }
}

/// Layered depth: each child drifts by `depth * amount` against the device
/// tilt, so foreground and background separate the way a diorama does.
/// Index 0 is the furthest layer.
class DepthStack extends StatelessWidget {
  const DepthStack({
    super.key,
    required this.layers,
    this.amount = 14,
    this.alignment = Alignment.center,
  });

  /// Furthest → nearest. Depth is derived from list position.
  final List<Widget> layers;

  /// Pixels of drift for the nearest layer at full tilt.
  final double amount;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return _TiltSubscriber(
      builder: (context, tilt) => Stack(
        alignment: alignment,
        fit: StackFit.expand,
        children: [
          for (var i = 0; i < layers.length; i++)
            Transform.translate(
              // Nearer layers move more — classic parallax depth cue.
              offset: Offset(
                tilt.dx * amount * ((i + 1) / layers.length),
                tilt.dy * amount * 0.6 * ((i + 1) / layers.length),
              ),
              child: layers[i],
            ),
        ],
      ),
    );
  }
}
