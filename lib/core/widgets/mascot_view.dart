import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/laarish_colors.dart';

/// Premium living-mascot presenter. Takes a pre-cut transparent character PNG
/// (assets/images/*.png) and gives it AAA-casual-game life: a spring entrance,
/// then a continuous idle of vertical bob + breathing squash-&-stretch + a
/// subtle 3D perspective sway — one AnimationController, foreground-smooth
/// (NOT throttled; the perf convention only throttles slow-drift backgrounds).
///
/// Foundation-owned core widget (PARALLEL_AGENTS.md §2) so every workstream
/// celebrates its characters through one door. Missing art (e.g. Okki, whose
/// render hasn't shipped) fails soft to an on-brand biome blob.
/// Idle liveliness per canon personality (CANON.md §1): Okki the Speedster
/// bounces hot, Chilly the Slow Burn stays cool and still.
const Map<String, double> _energyByPlant = {
  'tommy': 1.0,
  'okki': 1.45,
  'chilly': 0.6,
  'methi': 1.3,
};
double mascotEnergy(String plantId) => _energyByPlant[plantId] ?? 1.0;

class MascotView extends StatefulWidget {
  const MascotView({
    super.key,
    required this.asset,
    this.size = 140,
    this.color = LaarishColors.leaf,
    this.glow = false,
    this.animate = true,
    this.energy = 1.0,
    this.onTap,
  });

  /// Convenience for the four plant mascots: `MascotView.plant('tommy')`.
  factory MascotView.plant(
    String plantId, {
    Key? key,
    double size = 140,
    bool glow = false,
    bool animate = true,
    double energy = 1.0,
    VoidCallback? onTap,
  }) =>
      MascotView(
        key: key,
        asset: 'assets/images/${plantId}_mascot.png',
        size: size,
        color: LaarishColors.biome[plantId] ?? LaarishColors.leaf,
        glow: glow,
        animate: animate,
        energy: energy,
        onTap: onTap,
      );

  /// Full asset path of a transparent character PNG.
  final String asset;
  final double size;

  /// Biome tint for the glow halo and the fail-soft fallback.
  final Color color;

  /// Radial biome glow behind the character — for hero moments.
  final bool glow;

  /// When false, holds a still pose (list rows, thumbnails) to save cycles.
  final bool animate;

  /// Idle liveliness multiplier — Okki runs hot (1.4), Chilly cool (0.6).
  final double energy;
  final VoidCallback? onTap;

  @override
  State<MascotView> createState() => _MascotViewState();
}

class _MascotViewState extends State<MascotView> with TickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  );
  late final AnimationController _bounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    value: 1,
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _c.repeat();
  }

  @override
  void didUpdateWidget(covariant MascotView old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.animate && _c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    _bounce.dispose();
    super.dispose();
  }

  void _tap() {
    if (widget.onTap == null) return;
    // squash-and-stretch pop on press, then settle
    _bounce.forward(from: 0.0);
    widget.onTap!.call();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    Widget mascot = AnimatedBuilder(
      animation: Listenable.merge([_c, _bounce]),
      builder: (context, child) {
        final t = _c.value * 2 * math.pi;
        final e = widget.energy;
        final bob = math.sin(t) * s * 0.035 * e; // vertical float
        final breathe = 1 + math.sin(t) * 0.03 * e; // breathing scale
        final swayZ = math.sin(t * 0.7) * 0.02 * e; // gentle tilt
        final swayY = math.sin(t * 0.5) * 0.10 * e; // 3D turn
        // press bounce: 0->1 elastic settle back to rest
        final b = Curves.elasticOut.transform(_bounce.value);
        final pressSquash = 1 - (1 - b) * 0.12;

        return Transform.translate(
          offset: Offset(0, bob),
          child: Transform(
            alignment: Alignment.bottomCenter,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateY(swayY)
              ..rotateZ(swayZ)
              ..scaleByDouble(breathe * pressSquash, (2 - breathe) * pressSquash, 1, 1),
            child: child,
          ),
        );
      },
      child: Image.asset(
        widget.asset,
        width: s,
        height: s,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, _, _) => _FallbackBlob(color: widget.color, size: s),
      ),
    );

    if (widget.glow) {
      mascot = Container(
        width: s * 1.35,
        height: s * 1.35,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              widget.color.withValues(alpha: 0.35),
              widget.color.withValues(alpha: 0.0),
            ],
            stops: const [0.35, 1.0],
          ),
        ),
        child: mascot,
      );
    }

    if (widget.onTap != null) {
      mascot = GestureDetector(onTap: _tap, behavior: HitTestBehavior.opaque, child: mascot);
    }

    // Spring entrance — every mascot pops into being (LaarishMotion.enter feel).
    return mascot
        .animate()
        .scale(begin: const Offset(0.6, 0.6), end: const Offset(1, 1), curve: Curves.easeOutBack, duration: 520.ms)
        .fadeIn(duration: 300.ms);
  }
}

/// On-brand stand-in when a character render hasn't shipped (Okki today).
class _FallbackBlob extends StatelessWidget {
  const _FallbackBlob({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size * 0.8,
      height: size * 0.8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color.withValues(alpha: 0.95), color.withValues(alpha: 0.6)]),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Icon(Icons.eco_rounded, color: Colors.white, size: size * 0.4),
    );
  }
}
