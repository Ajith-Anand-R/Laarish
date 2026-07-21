import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Camera shake — the impact primitive.
///
/// Wrap a screen (or the whole app) in [ShakeScope]; any descendant can then
/// call `ShakeScope.of(context)?.shake()` on a satisfying event. The shake is
/// a decaying two-frequency sine (translate + a whisper of rotation) so it
/// reads as a real camera knock rather than a stuttering jitter, and it is
/// applied with a single [Transform] over a [RepaintBoundary] — the subtree
/// is not rebuilt, only re-composited.
///
/// Haptics fire in sync with the first frame of the shake ("haptic
/// synchronization"): the hit you feel and the hit you see are one event.
class ShakeScope extends StatefulWidget {
  const ShakeScope({super.key, required this.child});

  final Widget child;

  static ShakeScopeState? of(BuildContext context) =>
      context.findAncestorStateOfType<ShakeScopeState>();

  /// Convenience — shake the nearest scope, no-op if there isn't one.
  static void go(
    BuildContext context, {
    double intensity = 8,
    Duration duration = const Duration(milliseconds: 380),
    HapticImpact haptic = HapticImpact.medium,
  }) =>
      of(context)?.shake(
        intensity: intensity,
        duration: duration,
        haptic: haptic,
      );

  @override
  State<ShakeScope> createState() => ShakeScopeState();
}

enum HapticImpact { none, selection, light, medium, heavy }

class ShakeScopeState extends State<ShakeScope>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  double _intensity = 0;
  double _seed = 0;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Knock the camera. Re-entrant: a second shake during a first one takes
  /// over with the larger amplitude instead of stacking into chaos.
  void shake({
    double intensity = 8,
    Duration duration = const Duration(milliseconds: 380),
    HapticImpact haptic = HapticImpact.medium,
  }) {
    if (!mounted) return;
    _intensity = _c.isAnimating ? math.max(_intensity, intensity) : intensity;
    _seed = (_seed + 1.7) % 100;
    _c.duration = duration;
    _c.forward(from: 0);
    switch (haptic) {
      case HapticImpact.none:
        break;
      case HapticImpact.selection:
        HapticFeedback.selectionClick();
      case HapticImpact.light:
        HapticFeedback.lightImpact();
      case HapticImpact.medium:
        HapticFeedback.mediumImpact();
      case HapticImpact.heavy:
        HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: RepaintBoundary(child: widget.child),
      builder: (context, child) {
        if (!_c.isAnimating || _c.value >= 1) return child!;
        final t = _c.value;
        // Exponential decay envelope — hard hit, quick settle.
        final decay = math.pow(1 - t, 2.2).toDouble();
        final a = t * math.pi * 2;
        final dx = math.sin(a * 7.3 + _seed) * _intensity * decay;
        final dy = math.cos(a * 5.1 + _seed * 1.3) * _intensity * 0.7 * decay;
        final rot = math.sin(a * 6.1 + _seed) * 0.006 * (_intensity / 8) * decay;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..translateByDouble(dx, dy, 0, 1)
            ..rotateZ(rot),
          child: child,
        );
      },
    );
  }
}
