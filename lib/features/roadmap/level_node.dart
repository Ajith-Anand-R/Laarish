import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/audio/audio_service.dart';
import '../../core/fx/fx.dart';
import '../../core/motion/laarish_motion.dart';
import '../../core/theme/laarish_colors.dart';
import '../../core/theme/laarish_spacing.dart';

enum NodeState { locked, unlocked, done }

class LevelNodeData {
  const LevelNodeData({
    required this.plantId,
    required this.level,
    required this.index,
    required this.state,
    required this.stars,
    required this.isCurrent,
    required this.position,
    required this.biomeColor,
  });

  final String plantId;
  final int level;
  final int index; // 0-based global index, drives stagger delay
  final NodeState state;
  final int stars; // 0..3
  final bool isCurrent;
  final Offset position;
  final Color biomeColor;
}

/// One level stop on the garden path — DESIGN_SYSTEM.md §6 node states:
/// locked = dim bud, unlocked = colored bud + idle wobble, done = filled
/// with star count. Pops in with spring+stagger once per screen load
/// (no visibility_detector dependency available yet — see roadmap handoff
/// note for the true viewport-triggered upgrade path).
class LevelNode extends StatefulWidget {
  const LevelNode({super.key, required this.data, required this.onTap});

  final LevelNodeData data;
  final VoidCallback? onTap;

  @override
  State<LevelNode> createState() => _LevelNodeState();
}

class _LevelNodeState extends State<LevelNode>
    with SingleTickerProviderStateMixin {
  // Unbounded so the release spring can overshoot past 1.0 (~1.06) before it
  // settles — a bounded controller would clamp the juicy part off.
  late final AnimationController _press =
      AnimationController.unbounded(vsync: this, value: 1.0);

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  final _budKey = GlobalKey();

  void _down(_) {
    HapticFeedback.selectionClick();
    _press.animateTo(LaarishMotion.tapSquash,
        duration: LaarishMotion.tapDown, curve: Curves.easeOut);
  }

  void _release({bool activated = false}) {
    // Spring back to rest with a positive kick so it overshoots past 1.0 the
    // way a real released button does, then settles.
    _press.animateWith(
      SpringSimulation(
        LaarishMotion.pop,
        _press.value,
        1.0,
        activated ? 5.0 : 0,
      ),
    );
  }

  void _tap() {
    final locked = widget.data.state == NodeState.locked;
    if (locked) {
      // Denial reads as a physical bump, not a silent no-op.
      HapticFeedback.heavyImpact();
      AudioService.instance.play(Sfx.gateCreak);
      ShakeScope.go(context, intensity: 4, haptic: HapticImpact.none);
    } else {
      AudioService.instance.play(Sfx.pop);
      FxBurst.atWidget(
        _budKey,
        color: widget.data.biomeColor,
        style: BurstStyle.sparkle,
        intensity: 0.7,
      );
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final tappable = data.state != NodeState.locked;

    Widget child = SizedBox(
      key: _budKey,
      width: LaarishSpacing.minTapTarget,
      height: LaarishSpacing.minTapTarget,
      child: _NodeShape(data: data),
    );

    // The one node to tap next wears a breathing halo so the eye finds it
    // instantly on a busy map.
    if (data.isCurrent) {
      child = PulseGlow(
        color: LaarishColors.sunflower,
        radius: 20,
        intensity: 0.65,
        child: child,
      );
    }

    child = AnimatedBuilder(
      animation: _press,
      builder: (context, c) {
        final s = _press.value;
        // Squash-and-stretch: as it presses down it widens, on the
        // overshoot it stretches tall — volume-preserving feel.
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(1.0 + (1.0 - s) * 0.5, s, 1.0),
          child: c,
        );
      },
      child: child,
    );

    child = GestureDetector(
      onTap: _tap,
      // Locked nodes still react to the touch — they just bump instead of
      // opening. A dead tap target reads as a broken app to a child.
      onTapDown: _down,
      onTapUp: (_) => _release(activated: tappable),
      onTapCancel: _release,
      child: child,
    );

    // Idle wobble for unlocked-not-done nodes only — a bit of "alive" juice
    // without distracting from the one node the child should tap next.
    if (data.state == NodeState.unlocked) {
      child = Animate(
        onPlay: (c) => c.repeat(reverse: true),
        effects: [
          RotateEffect(
            begin: -0.035,
            end: 0.035,
            duration: const Duration(milliseconds: 2200),
            curve: Curves.easeInOut,
          ),
        ],
        child: child,
      );
    }

    // Entrance is handled by the scroll-reveal wrapper in roadmap_screen; here
    // we only keep the idle wobble + press squash. RepaintBoundary isolates
    // this node's per-frame repaints from its siblings on the path.
    return RepaintBoundary(child: child);
  }
}

class _NodeShape extends StatelessWidget {
  const _NodeShape({required this.data});
  final LevelNodeData data;

  @override
  Widget build(BuildContext context) {
    final locked = data.state == NodeState.locked;
    final done = data.state == NodeState.done;
    final fill = locked
        ? LaarishColors.paperDeep
        : done
            ? LaarishColors.sunflowerDeep
            : data.biomeColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: CustomPaint(
            painter: _BudPainter(
                fill: fill, locked: locked, done: done, ringGlow: data.isCurrent),
            child: Center(
              child: locked
                  ? Icon(Icons.lock_rounded, color: LaarishColors.soil.withValues(alpha: 0.5), size: 20)
                  : Text(
                      '${data.level}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        shadows: const [Shadow(color: Colors.black26, blurRadius: 2)],
                      ),
                    ),
            ),
          ),
        ),
        if (!locked)
          // Earned stars cascade in one after another — the chain reaction
          // that makes a completed node feel *awarded*, not just drawn.
          ChainReveal(
            gap: const Duration(milliseconds: 110),
            slide: 6,
            children: [
              for (var i = 0; i < 3; i++)
                i < data.stars
                    ? const Icon(Icons.star_rounded,
                        size: 13,
                        color: LaarishColors.sunflower,
                        shadows: [
                          Shadow(color: LaarishColors.sunflowerDeep, blurRadius: 4),
                        ])
                    : Icon(Icons.star_rounded,
                        size: 13,
                        color: LaarishColors.soil.withValues(alpha: 0.28)),
            ],
          ),
      ],
    );
  }
}

/// Simple bud/bloom shape: a circle with a small leaf-like point on top.
/// Placeholder art per the task's no-asset constraint — swap for a
/// pre-rendered sprite later (DESIGN_SYSTEM.md §8 pipeline).
class _BudPainter extends CustomPainter {
  _BudPainter({
    required this.fill,
    required this.locked,
    required this.done,
    required this.ringGlow,
  });
  final Color fill;
  final bool locked;
  final bool done;
  final bool ringGlow;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 4;

    // Contact shadow: an ellipse on the ground, not a circle behind the bud —
    // that difference is what makes it sit *on* the path rather than float.
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, radius * 0.92),
        width: radius * 1.7,
        height: radius * 0.5,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Sphere shading: key light up-left, body colour, terminator toward the
    // lower-right. Three stops is the minimum for a believable ball.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.38, -0.42),
          radius: 0.95,
          colors: [
            Color.lerp(fill, Colors.white, 0.55)!,
            fill,
            Color.lerp(fill, Colors.black, locked ? 0.10 : 0.32)!,
          ],
          stops: const [0.0, 0.52, 1.0],
        ).createShader(rect),
    );

    // Rim light along the shaded edge — bounce from the world behind it.
    canvas.drawArc(
      rect.deflate(1.2),
      -math.pi * 0.15,
      math.pi * 0.9,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: locked ? 0.18 : 0.42),
    );

    // Specular hotspot — an ellipse, because a sphere's highlight is never
    // a perfect circle at a glancing angle.
    if (!locked) {
      canvas.drawOval(
        Rect.fromCenter(
          center: center + Offset(-radius * 0.30, -radius * 0.36),
          width: radius * 0.62,
          height: radius * 0.42,
        ),
        Paint()
          ..color = Colors.white.withValues(alpha: done ? 0.65 : 0.42)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }

    // Outline.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = locked
            ? LaarishColors.soil.withValues(alpha: 0.25)
            : Colors.white.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Little leaf sprout on the crown — the "bud" of DESIGN_SYSTEM.md §6.
    if (!locked) {
      final tip = center + Offset(radius * 0.22, -radius * 1.16);
      final leaf = Path()
        ..moveTo(center.dx, center.dy - radius * 0.95)
        ..quadraticBezierTo(
          center.dx + radius * 0.55, center.dy - radius * 1.0, tip.dx, tip.dy)
        ..quadraticBezierTo(center.dx + radius * 0.16,
            center.dy - radius * 0.92, center.dx, center.dy - radius * 0.95)
        ..close();
      canvas.drawPath(
        leaf,
        Paint()
          ..shader = LinearGradient(
            colors: [LaarishColors.leaf, LaarishColors.leafDeep],
          ).createShader(leaf.getBounds()),
      );
    }

    if (ringGlow) {
      // Double ring: a bright inner hairline plus a blurred outer bloom.
      canvas.drawCircle(
        center,
        radius + 5,
        Paint()
          ..color = LaarishColors.sunflower.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4,
      );
      canvas.drawCircle(
        center,
        radius + 8,
        Paint()
          ..color = LaarishColors.sunflower.withValues(alpha: 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BudPainter oldDelegate) =>
      oldDelegate.fill != fill ||
      oldDelegate.locked != locked ||
      oldDelegate.done != done ||
      oldDelegate.ringGlow != ringGlow;
}
