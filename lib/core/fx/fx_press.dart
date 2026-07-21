import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import '../audio/audio_service.dart';
import '../motion/laarish_motion.dart';
import 'fx_particles.dart';

/// The one press primitive for the whole app.
///
/// Every tappable surface gets, for free:
///   • **magnetic pull** — the control slides a few px toward your finger
///     while held, so it feels attracted to the touch;
///   • **squash & stretch** — volume-preserving, wide on the press, tall on
///     the overshoot;
///   • **anticipation + follow-through** — release runs a real spring
///     simulation that overshoots and settles, never a linear tween;
///   • **ripple** — an expanding ring from the exact touch point;
///   • **particle spark** — optional burst on activation;
///   • **haptic + sfx** — fired on the same frame as the visual.
///
/// Replaces the old ad-hoc `AnimatedScale`-on-a-bool pattern; [JuicyTap] and
/// [LaarishButton] both delegate here so press physics are identical
/// everywhere.
class MagneticTap extends StatefulWidget {
  const MagneticTap({
    super.key,
    required this.child,
    required this.onTap,
    this.enabled = true,
    this.magnetStrength = 7,
    this.squash = 0.94,
    this.ripple = true,
    this.rippleColor,
    this.spark = false,
    this.sparkColor,
    this.haptic = true,
    this.sfx = Sfx.tap,
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback onTap;
  final bool enabled;

  /// Max pixels the control slides toward the finger.
  final double magnetStrength;

  /// Scale at full press (before the squash-and-stretch redistribution).
  final double squash;

  final bool ripple;
  final Color? rippleColor;

  /// Fire a particle burst at the touch point on activation.
  final bool spark;
  final Color? sparkColor;

  final bool haptic;
  final Sfx? sfx;

  /// Clips the ripple to the control's shape. Defaults to a 20px rounding.
  final BorderRadius? borderRadius;

  @override
  State<MagneticTap> createState() => _MagneticTapState();
}

class _MagneticTapState extends State<MagneticTap>
    with TickerProviderStateMixin {
  // Unbounded: the release spring must be free to overshoot past 1.0.
  late final AnimationController _press =
      AnimationController.unbounded(vsync: this, value: 1.0);
  late final AnimationController _ripple = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  Offset _pull = Offset.zero;
  Offset _touch = Offset.zero;
  Size _size = Size.zero;

  @override
  void dispose() {
    _press.dispose();
    _ripple.dispose();
    super.dispose();
  }

  /// Real laid-out size, read from the render object. Deliberately NOT
  /// `LayoutBuilder(constraints.biggest)` — buttons sit in unbounded Rows,
  /// where `biggest` is infinite and would blow up the magnet math.
  void _measure() {
    final box = context.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) _size = box.size;
  }

  void _down(TapDownDetails d) {
    if (!widget.enabled) return;
    _touch = d.localPosition;
    _measure();
    if (!_size.isEmpty && _size.isFinite) {
      // Pull toward the finger, normalised by the control's own size so a
      // small chip and a wide button feel equally "magnetic".
      final c = _size.center(Offset.zero);
      final v = _touch - c;
      final norm = Offset(
        (v.dx / (_size.width / 2)).clamp(-1.0, 1.0),
        (v.dy / (_size.height / 2)).clamp(-1.0, 1.0),
      );
      _pull = norm * widget.magnetStrength;
    }
    _press.animateTo(
      widget.squash,
      duration: LaarishMotion.tapDown,
      curve: Curves.easeOut,
    );
    if (widget.ripple) _ripple.forward(from: 0);
    setState(() {});
  }

  void _release({required bool activate}) {
    if (!widget.enabled) return;
    _pull = Offset.zero;
    // Kick the spring with a positive velocity so it *overshoots* the way a
    // real released button does, then settles — this is the "juice".
    _press.animateWith(
      SpringSimulation(LaarishMotion.pop, _press.value, 1.0, activate ? 4.5 : 0),
    );
    if (activate) {
      if (widget.haptic) HapticFeedback.lightImpact();
      if (widget.sfx != null) AudioService.instance.play(widget.sfx!);
      if (widget.spark) {
        final box = context.findRenderObject() as RenderBox?;
        if (box != null && box.hasSize) {
          FxBurst.at(
            context,
            box.localToGlobal(_touch),
            color: widget.sparkColor ?? Theme.of(context).colorScheme.primary,
            style: BurstStyle.sparkle,
            intensity: 0.8,
          );
        }
      }
      widget.onTap();
    }
    // onTap frequently navigates (or pops a dialog), which disposes this
    // State — so the trailing rebuild must be guarded.
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(20);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.enabled ? _down : null,
      onTapUp: widget.enabled ? (_) => _release(activate: true) : null,
      onTapCancel: widget.enabled ? () => _release(activate: false) : null,
      child: AnimatedBuilder(
        animation: Listenable.merge([_press, _ripple]),
        child: widget.child,
        builder: (context, child) {
          final s = _press.value;
          // Volume preservation: squashing vertically widens horizontally.
          final sx = 1 + (1 - s) * 0.55;
          final sy = s;
          // The magnet eases in/out with the press amount so letting go
          // releases the pull smoothly instead of snapping.
          final pullT = ((1 - s) / (1 - widget.squash)).clamp(0.0, 1.0);
          return Transform.translate(
            offset: _pull * pullT,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.diagonal3Values(sx, sy, 1),
              child: widget.ripple && _ripple.isAnimating
                  ? ClipRRect(
                      borderRadius: radius,
                      child: Stack(
                        fit: StackFit.passthrough,
                        children: [
                          child!,
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: _RipplePainter(
                                  origin: _touch,
                                  t: _ripple.value,
                                  color: widget.rippleColor ??
                                      Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : child,
            ),
          );
        },
      ),
    );
  }
}

/// Expanding ring + soft fill from the touch point — a hand-drawn ripple that
/// matches the game's look instead of Material's ink splash.
class _RipplePainter extends CustomPainter {
  _RipplePainter({required this.origin, required this.t, required this.color});

  final Offset origin;
  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    // Reach the far corner so the ripple always covers the whole control.
    final maxR = math.sqrt(size.width * size.width + size.height * size.height);
    final e = Curves.easeOutCubic.transform(t);
    final r = maxR * e;
    final fade = (1 - t) * (1 - t);

    canvas.drawCircle(
      origin,
      r,
      Paint()..color = color.withValues(alpha: color.a * 0.22 * fade),
    );
    canvas.drawCircle(
      origin,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * fade + 0.5
        ..color = color.withValues(alpha: color.a * 0.8 * fade),
    );
  }

  @override
  bool shouldRepaint(covariant _RipplePainter old) =>
      old.t != t || old.origin != origin || old.color != color;
}
