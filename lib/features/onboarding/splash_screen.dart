import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/fx/fx.dart';
import '../../core/motion/micro_animations.dart';
import '../../core/theme/laarish_colors.dart';

/// S1 — seed-to-logo growth animation, fully code-drawn (no asset needed).
/// A seed cracks, a sprout grows out of it, then blooms into the "Laarish"
/// wordmark with a spring pop + sparkle burst. DESIGN_SYSTEM.md §4 motion.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  final _logoKey = GlobalKey();
  bool _bloomed = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))
      ..addListener(_watchBloom)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) context.go('/login');
      })
      ..forward();
  }

  /// The instant the wordmark lands is the app's first impression — fire the
  /// full payoff there (burst + world knock + haptic), once.
  void _watchBloom() {
    if (_bloomed || _c.value < 0.68 || !mounted) return;
    _bloomed = true;
    ShakeScope.go(context, intensity: 7, haptic: HapticImpact.medium);
    FxBurst.atWidget(
      _logoKey,
      color: LaarishColors.sunflower,
      style: BurstStyle.celebrate,
      intensity: 1.1,
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Living sky behind the scene photo, so even a missing asset gives
          // a rich animated backdrop.
          const RepaintBoundary(
            child: AnimatedMeshGradient(
              colors: [
                LaarishColors.skyBottom,
                Color(0x5AFFC93C),
                Color(0x4458A83C),
                Color(0x3387CEEB),
              ],
            ),
          ),
          Image.asset(
            'assets/images/splash_scene.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
          const RepaintBoundary(
            child: ParticleField(
              color: LaarishColors.sunflower,
              style: ParticleStyle.bokeh,
              count: 14,
              speed: 0.6,
              opacity: 0.35,
            ),
          ),
          Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xCCB3E0F2), Color(0xE6FDF6E7)],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, child) {
              final t = _c.value;
              // 0.0-0.65: seed cracks + sprout grows. 0.55-1.0: logo pops in.
              final logoT = Curves.easeOutBack.transform(((t - 0.55) / 0.45).clamp(0.0, 1.0));
              final sparkleT = ((t - 0.65) / 0.35).clamp(0.0, 1.0);
              return SizedBox(
                width: 260,
                height: 320,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    RepaintBoundary(
                      child: CustomPaint(
                        size: const Size(260, 220),
                        painter: _SeedSproutPainter(growth: t, sparkle: sparkleT, bloom: logoT),
                      ),
                    ),
                    Positioned(
                      bottom: 24,
                      child: Transform.scale(
                        scale: logoT,
                        child: Opacity(
                          opacity: logoT.clamp(0.0, 1.0),
                          child: Breathing(
                            amount: 0.025,
                            child: PulseGlow(
                              color: LaarishColors.sunflower,
                              radius: 20,
                              intensity: 0.45,
                              shape: BoxShape.rectangle,
                              borderRadius: BorderRadius.circular(24),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: ShimmerSweep(
                                  strength: 0.5,
                                  period: const Duration(milliseconds: 2400),
                                  child: Container(
                                    key: _logoKey,
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: DepthShadow.shadows(
                                          LaarishColors.leafDeep, 1.6),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Image.asset('assets/images/logo.png',
                                          width: 150, fit: BoxFit.contain),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
          ),
        ],
      ),
    );
  }
}

class _SeedSproutPainter extends CustomPainter {
  _SeedSproutPainter({required this.growth, required this.sparkle, required this.bloom});

  /// 0..1 overall splash progress.
  final double growth;
  /// 0..1 sparkle-burst progress (only meaningful once logo has popped).
  final double sparkle;
  /// 0..1 logo-bloom progress — drives radiating light rays + glow.
  final double bloom;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.72);

    // Radiating light rays + soft bloom glow blossom behind the logo as it
    // lands — the "grand reveal" beat of the seed→sprout→bloom arc.
    if (bloom > 0) {
      final rayOrigin = center.translate(0, -78);
      final rayLen = 96 * Curves.easeOutCubic.transform(bloom.clamp(0.0, 1.0));
      final rayPaint = Paint()
        ..color = LaarishColors.sunflower.withValues(alpha: 0.30 * (1 - bloom * 0.35))
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      const rays = 12;
      for (var i = 0; i < rays; i++) {
        final a = (2 * math.pi / rays) * i + bloom * 0.5;
        const inner = 26.0;
        canvas.drawLine(
          rayOrigin.translate(math.cos(a) * inner, math.sin(a) * inner),
          rayOrigin.translate(math.cos(a) * (inner + rayLen), math.sin(a) * (inner + rayLen)),
          rayPaint,
        );
      }
      canvas.drawCircle(
        rayOrigin,
        46 * bloom,
        Paint()..color = LaarishColors.sunflower.withValues(alpha: 0.16 * (1 - bloom * 0.5)),
      );
    }

    // Soil mound.
    final soilPaint = Paint()..color = LaarishColors.soil.withValues(alpha: 0.85);
    canvas.drawArc(
      Rect.fromCenter(center: center, width: 140, height: 40),
      0,
      math.pi,
      false,
      soilPaint..style = PaintingStyle.fill,
    );

    // Seed fades out as the sprout takes over (0.0 -> 0.4).
    final seedAlpha = (1 - (growth / 0.4)).clamp(0.0, 1.0);
    if (seedAlpha > 0) {
      final seedPaint = Paint()..color = LaarishColors.soil.withValues(alpha: seedAlpha);
      canvas.drawOval(
        Rect.fromCenter(center: center.translate(0, -6), width: 20, height: 26),
        seedPaint,
      );
    }

    // Sprout stem grows from 0.25 -> 0.65.
    final stemT = ((growth - 0.25) / 0.4).clamp(0.0, 1.0);
    if (stemT > 0) {
      final stemHeight = 120 * stemT;
      final stemPaint = Paint()
        ..color = LaarishColors.leaf
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;
      final top = center.translate(0, -stemHeight);
      // gentle sway so it doesn't look like a straight ruler
      final sway = math.sin(stemT * math.pi) * 10;
      final control = Offset(center.dx + sway, center.dy - stemHeight * 0.5);
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..quadraticBezierTo(control.dx, control.dy, top.dx, top.dy);
      canvas.drawPath(path, stemPaint..style = PaintingStyle.stroke);

      // Two leaves pop in once the stem is mostly grown.
      final leafT = ((growth - 0.45) / 0.25).clamp(0.0, 1.0);
      if (leafT > 0) {
        final leafPaint = Paint()..color = LaarishColors.leaf;
        final leafSize = 32 * Curves.easeOutBack.transform(leafT);
        for (final side in [-1.0, 1.0]) {
          canvas.save();
          canvas.translate(top.dx, top.dy + 14);
          canvas.rotate(side * 0.5);
          canvas.drawOval(
            Rect.fromCenter(center: Offset(side * leafSize * 0.6, 0), width: leafSize, height: leafSize * 0.55),
            leafPaint,
          );
          canvas.restore();
        }
      }
    }

    // Pollen burst that drifts out then settles under gravity as it fades —
    // the particles "land" rather than just vanishing.
    if (sparkle > 0) {
      final ease = Curves.easeOutCubic.transform(sparkle);
      final sparklePaint = Paint()..color = LaarishColors.sunflower.withValues(alpha: (1 - sparkle));
      const count = 10;
      for (var i = 0; i < count; i++) {
        final angle = (2 * math.pi / count) * i + i * 0.4;
        final r = 66 * ease;
        final gravity = 34 * sparkle * sparkle; // settle downward over time
        final p = center.translate(
          math.cos(angle) * r,
          math.sin(angle) * r - 62 + gravity,
        );
        canvas.drawCircle(p, 2.5 + 3 * (1 - sparkle), sparklePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SeedSproutPainter oldDelegate) =>
      oldDelegate.growth != growth ||
      oldDelegate.sparkle != sparkle ||
      oldDelegate.bloom != bloom;
}
