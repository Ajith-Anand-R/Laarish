import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../motion/laarish_motion.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// Transitions & chain reactions — how one thing becomes the next thing.
/// ─────────────────────────────────────────────────────────────────────────

/// Swaps between children with a cinematic 3D depth push: the outgoing card
/// rotates away and recedes, the incoming one swings in from depth and
/// overshoots into place. Drop-in replacement for [AnimatedSwitcher] wherever
/// a flat cross-fade would feel cheap (level steps, mentor states, quiz
/// phases).
class DepthSwapper extends StatelessWidget {
  const DepthSwapper({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 480),
    this.direction = SwapDirection.forward,
  });

  /// Must carry a distinct [Key] per logical page, or nothing animates.
  final Widget child;
  final Duration duration;
  final SwapDirection direction;

  @override
  Widget build(BuildContext context) {
    final sign = direction == SwapDirection.forward ? 1.0 : -1.0;
    return AnimatedSwitcher(
      duration: duration,
      reverseDuration: duration * 0.7,
      switchInCurve: LaarishMotion.overshoot,
      switchOutCurve: Curves.easeInCubic,
      // Stack the two so the outgoing card visibly *travels away* instead of
      // being replaced in place.
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.center,
        children: [...previous, ?current],
      ),
      transitionBuilder: (child, animation) {
        return AnimatedBuilder(
          animation: animation,
          child: child,
          builder: (context, child) {
            final t = animation.value;
            final inv = 1 - t;
            final entering = animation.status != AnimationStatus.reverse;
            final s = entering ? (0.82 + 0.18 * t) : (0.82 + 0.18 * t);
            return Opacity(
              opacity: t.clamp(0.0, 1.0),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0014)
                  ..translateByDouble(sign * 70 * inv, 0, -140 * inv, 1)
                  ..rotateY(sign * 0.55 * inv)
                  ..scaleByDouble(s, s, 1, 1),
                child: child,
              ),
            );
          },
        );
      },
      child: child,
    );
  }
}

enum SwapDirection { forward, back }

/// Pops (scale-punch + optional colour flash) whenever [value] changes —
/// the standard "a number just went up" reaction for HUD counters, star
/// rows and score chips.
class PopOnChange extends StatefulWidget {
  const PopOnChange({
    super.key,
    required this.value,
    required this.child,
    this.scale = 1.35,
    this.duration = const Duration(milliseconds: 520),
  });

  final Object? value;
  final Widget child;
  final double scale;
  final Duration duration;

  @override
  State<PopOnChange> createState() => _PopOnChangeState();
}

class _PopOnChangeState extends State<PopOnChange>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration, value: 1);

  @override
  void didUpdateWidget(covariant PopOnChange old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _c.forward(from: 0);
  }

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
        if (_c.value >= 1) return child!;
        // Elastic settle from the punched scale back to rest.
        final e = Curves.elasticOut.transform(_c.value);
        final s = widget.scale - (widget.scale - 1) * e;
        return Transform.scale(scale: s, child: child);
      },
    );
  }
}

/// Chain reaction: reveals [children] one after another with a spring pop,
/// [gap] apart. The satisfying cascade behind star rows, reward lines and
/// option grids — one widget instead of N hand-tuned delays.
class ChainReveal extends StatefulWidget {
  const ChainReveal({
    super.key,
    required this.children,
    this.gap = const Duration(milliseconds: 90),
    this.itemDuration = const Duration(milliseconds: 520),
    this.axis = Axis.horizontal,
    this.mainAxisAlignment = MainAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.min,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.slide = 18,
    this.spacing = 0,
  });

  final List<Widget> children;
  final Duration gap;
  final Duration itemDuration;
  final Axis axis;
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;
  final CrossAxisAlignment crossAxisAlignment;

  /// Distance each item travels in on the cross axis.
  final double slide;
  final double spacing;

  @override
  State<ChainReveal> createState() => _ChainRevealState();
}

class _ChainRevealState extends State<ChainReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    final total = widget.gap * widget.children.length + widget.itemDuration;
    _c = AnimationController(vsync: this, duration: total)..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalMs = _c.duration!.inMilliseconds;
    final itemMs = widget.itemDuration.inMilliseconds;
    final gapMs = widget.gap.inMilliseconds;

    final items = <Widget>[];
    for (var i = 0; i < widget.children.length; i++) {
      if (i > 0 && widget.spacing > 0) {
        items.add(widget.axis == Axis.horizontal
            ? SizedBox(width: widget.spacing)
            : SizedBox(height: widget.spacing));
      }
      final start = (i * gapMs) / totalMs;
      final end = math.min(1.0, (i * gapMs + itemMs) / totalMs);
      items.add(
        AnimatedBuilder(
          animation: _c,
          child: widget.children[i],
          builder: (context, child) {
            final raw = ((_c.value - start) / (end - start)).clamp(0.0, 1.0);
            if (raw >= 1) return child!;
            final t = LaarishMotion.overshoot.transform(raw);
            return Opacity(
              opacity: raw.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, widget.slide * (1 - t)),
                child: Transform.scale(scale: 0.6 + 0.4 * t, child: child),
              ),
            );
          },
        ),
      );
    }

    return widget.axis == Axis.horizontal
        ? Row(
            mainAxisAlignment: widget.mainAxisAlignment,
            mainAxisSize: widget.mainAxisSize,
            crossAxisAlignment: widget.crossAxisAlignment,
            children: items,
          )
        : Column(
            mainAxisAlignment: widget.mainAxisAlignment,
            mainAxisSize: widget.mainAxisSize,
            crossAxisAlignment: widget.crossAxisAlignment,
            children: items,
          );
  }
}

/// Spring entrance for any single widget: anticipation dip, overshoot, settle.
/// Use for hero elements that should *arrive*, not fade in.
class SpringIn extends StatefulWidget {
  const SpringIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 620),
    this.from = const Offset(0, 26),
    this.beginScale = 0.72,
    this.rotate = 0.0,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset from;
  final double beginScale;
  final double rotate;

  @override
  State<SpringIn> createState() => _SpringInState();
}

class _SpringInState extends State<SpringIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration);

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

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
        if (_c.value >= 1) return child!;
        final t = LaarishMotion.overshoot.transform(_c.value);
        final inv = 1 - t;
        return Opacity(
          opacity: _c.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: widget.from * inv,
            child: Transform.rotate(
              angle: widget.rotate * inv,
              child: Transform.scale(
                scale: widget.beginScale + (1 - widget.beginScale) * t,
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
