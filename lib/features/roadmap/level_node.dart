import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

  void _down(_) =>
      _press.animateTo(LaarishMotion.tapSquash,
          duration: LaarishMotion.tapDown, curve: Curves.easeOut);

  void _release() {
    // Spring back to rest — LaarishMotion.pop naturally overshoots toward
    // tapOvershoot then settles, so no manual keyframe sequence needed.
    _press.animateWith(
      SpringSimulation(LaarishMotion.pop, _press.value, 1.0, 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final tappable = data.state != NodeState.locked;

    Widget child = SizedBox(
      width: LaarishSpacing.minTapTarget,
      height: LaarishSpacing.minTapTarget,
      child: _NodeShape(data: data),
    );

    if (tappable) {
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
        onTap: widget.onTap,
        onTapDown: _down,
        onTapUp: (_) => _release(),
        onTapCancel: _release,
        child: child,
      );
    }

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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++)
                Icon(
                  i < data.stars ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 12,
                  color: LaarishColors.sunflowerDeep,
                ),
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

    // Soft ambient-occlusion / drop shadow beneath the bud so it reads as a
    // sphere sitting on the path. Drawn BEFORE the fill, offset down, blurred.
    canvas.drawCircle(
      center + const Offset(0, 3),
      radius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    final gradient = RadialGradient(
      center: const Alignment(-0.3, -0.3),
      colors: [Color.lerp(fill, Colors.white, 0.35)!, fill],
    );
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(center, radius, Paint()..shader = gradient.createShader(rect));

    // Done buds get an extra glossy sheen highlight for a ripe-sunflower pop.
    if (done) {
      canvas.drawCircle(
        center + Offset(-radius * 0.28, -radius * 0.32),
        radius * 0.34,
        Paint()..color = Colors.white.withValues(alpha: 0.45),
      );
    }

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = locked ? LaarishColors.soil.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    if (ringGlow) {
      canvas.drawCircle(
        center,
        radius + 4,
        Paint()
          ..color = LaarishColors.sunflower
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
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
