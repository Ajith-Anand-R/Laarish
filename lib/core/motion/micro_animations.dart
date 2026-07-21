import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Reusable "living" micro-animations — each wraps any child so the whole app
/// can breathe, bob, blink and glance without bespoke controllers per screen
/// (DESIGN_SYSTEM.md §4 "something is always alive"). All are single-controller
/// and sine-driven, cheap enough to stack.

/// Gentle breathing scale — for logos, cards, idle characters.
class Breathing extends StatefulWidget {
  const Breathing({
    super.key,
    required this.child,
    this.amount = 0.03,
    this.period = const Duration(milliseconds: 3200),
  });
  final Widget child;
  final double amount;
  final Duration period;

  @override
  State<Breathing> createState() => _BreathingState();
}

class _BreathingState extends State<Breathing> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.period)..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final s = 1 + math.sin(_c.value * 2 * math.pi) * widget.amount;
        return Transform.scale(scale: s, child: child);
      },
      child: widget.child,
    );
  }
}

/// Soft vertical idle bounce (float up and down).
class IdleBounce extends StatefulWidget {
  const IdleBounce({
    super.key,
    required this.child,
    this.height = 6,
    this.period = const Duration(milliseconds: 2600),
  });
  final Widget child;
  final double height;
  final Duration period;

  @override
  State<IdleBounce> createState() => _IdleBounceState();
}

class _IdleBounceState extends State<IdleBounce> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.period)..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final dy = -math.sin(_c.value * 2 * math.pi) * widget.height;
        return Transform.translate(offset: Offset(0, dy), child: child);
      },
      child: widget.child,
    );
  }
}

/// Periodic blink — squashes the child vertically for a beat each cycle.
/// Works on any eye/face widget; [interval] is the full period between blinks.
class Blink extends StatefulWidget {
  const Blink({
    super.key,
    required this.child,
    this.interval = const Duration(milliseconds: 3800),
    this.alignment = Alignment.center,
  });
  final Widget child;
  final Duration interval;
  final Alignment alignment;

  @override
  State<Blink> createState() => _BlinkState();
}

class _BlinkState extends State<Blink> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.interval)..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        // Closed for a short window near the end of each cycle.
        final d = (_c.value - 0.92).abs();
        final open = d < 0.045 ? (d / 0.045) : 1.0;
        final scaleY = 0.08 + 0.92 * Curves.easeOut.transform(open.clamp(0.0, 1.0));
        return Transform(
          alignment: widget.alignment,
          transform: Matrix4.identity()..scaleByDouble(1, scaleY, 1, 1),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Slow wandering gaze — translates the child along a lissajous path so eyes
/// (or a whole face) glance around naturally.
class WanderGaze extends StatefulWidget {
  const WanderGaze({
    super.key,
    required this.child,
    this.radius = 3,
    this.period = const Duration(milliseconds: 5200),
  });
  final Widget child;
  final double radius;
  final Duration period;

  @override
  State<WanderGaze> createState() => _WanderGazeState();
}

class _WanderGazeState extends State<WanderGaze> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.period)..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final a = _c.value * 2 * math.pi;
        final dx = math.sin(a) * widget.radius;
        final dy = math.sin(a * 0.7 + 1.3) * widget.radius * 0.6;
        return Transform.translate(offset: Offset(dx, dy), child: child);
      },
      child: widget.child,
    );
  }
}

/// A pair of code-drawn googly eyes that blink and glance — a ready-made
/// "alive" accent (e.g. mascots peeking from bushes on the login gate, S2).
class BlinkingEyes extends StatelessWidget {
  const BlinkingEyes({super.key, this.size = 22, this.color = const Color(0xFF3A2E24), this.gap = 10});
  final double size;
  final Color color;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Blink(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [_eye(), SizedBox(width: gap), _eye()],
      ),
    );
  }

  Widget _eye() {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [
        BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 1)),
      ]),
      alignment: Alignment.center,
      child: WanderGaze(
        radius: size * 0.14,
        child: Container(
          width: size * 0.45,
          height: size * 0.45,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
