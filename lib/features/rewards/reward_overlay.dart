import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/audio/audio_service.dart';
import '../../core/fx/fx.dart';
import '../../core/motion/laarish_motion.dart';
import '../../core/theme/laarish_colors.dart';
import '../../core/theme/laarish_text.dart';
import '../../core/widgets/laarish_button.dart';
import '../../core/widgets/sticker_card.dart';
import '../../domain/reward_table.dart';

/// The ONE celebration widget for the whole app (AGENT.md "Celebrations").
/// Level end, badge, streak, certificate all call this — no per-screen
/// bespoke confetti code. Signature is frozen (PARALLEL_AGENTS.md §3) —
/// WS1/WS3/WS4 already call `showRewardOverlay(context, bundle)`; the extra
/// params are optional and default null-safe so those calls are untouched.
///
/// [flyTo] — global-coordinate target (e.g. a HUD counter's center, read via
/// a GlobalKey.currentContext's RenderBox) for the DESIGN_SYSTEM.md §4
/// "fly-to-HUD" arc. When null, the overlay just fades/scales out on collect.
/// [big] — grand-celebration mode (bigger card, longer confetti) for
/// milestones like profession complete.
///
/// The AAA sequence, on a timeline rather than all at once:
///   0ms   backdrop blurs in, world knocks (heavy haptic), god-rays ignite
///   80ms  card lands from depth with an anticipation dip and overshoot
///   250ms rays begin their slow rotation, sparkle field drifts up
///   300ms reward rows chain in one by one, each with its own pop + burst
///   —     counters roll up; the collect button breathes
///   tap   card arcs to the HUD, shrinking, trailing sparkles
Future<void> showRewardOverlay(
  BuildContext context,
  RewardBundle bundle, {
  Offset? flyTo,
  bool big = false,
}) {
  AudioService.instance.play(Sfx.reward);
  ShakeScope.go(
    context,
    intensity: big ? 16 : 10,
    haptic: HapticImpact.heavy,
  );
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'reward',
    barrierColor: Colors.black.withValues(alpha: 0.45),
    transitionDuration: const Duration(milliseconds: 460),
    pageBuilder: (_, _, _) =>
        _RewardOverlayContent(bundle: bundle, flyTo: flyTo, big: big),
    transitionBuilder: (_, anim, _, child) {
      return AnimatedBuilder(
        animation: anim,
        child: child,
        builder: (context, child) {
          final t = anim.value.clamp(0.0, 1.0);
          // Anticipation + overshoot: the card is *thrown* at the viewer.
          final e = LaarishMotion.overshoot.transform(t);
          return Opacity(
            opacity: t,
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 14 * t, sigmaY: 14 * t),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0016)
                  ..translateByDouble(0, 0, -260 * (1 - e), 1)
                  ..rotateX(0.35 * (1 - e))
                  ..scaleByDouble(0.7 + 0.3 * e, 0.7 + 0.3 * e, 1, 1),
                child: child,
              ),
            ),
          );
        },
      );
    },
  );
}

class _RewardOverlayContent extends StatefulWidget {
  const _RewardOverlayContent({required this.bundle, this.flyTo, this.big = false});
  final RewardBundle bundle;
  final Offset? flyTo;
  final bool big;

  @override
  State<_RewardOverlayContent> createState() => _RewardOverlayState();
}

class _RewardOverlayState extends State<_RewardOverlayContent>
    with TickerProviderStateMixin {
  late final ConfettiController _confetti;
  late final AnimationController _flyController;

  /// Continuous clock for the god-rays and the glory halo.
  late final AnimationController _glory = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  )..repeat();

  final _cardKey = GlobalKey();
  Offset? _cardCenter;
  bool _flying = false;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(
      duration: Duration(milliseconds: widget.big ? 2000 : 1100),
    );
    _confetti.play();
    _flyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
    );
    // Second impact once the card has landed — a one-two punch reads far
    // richer than a single hit.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 220), () {
        if (!mounted) return;
        FxBurst.atWidget(
          _cardKey,
          color: LaarishColors.sunflower,
          style: BurstStyle.shock,
          intensity: widget.big ? 1.4 : 1.0,
        );
        HapticFeedback.mediumImpact();
      });
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    _flyController.dispose();
    _glory.dispose();
    super.dispose();
  }

  Future<void> _collect() async {
    if (_flying) return;
    HapticFeedback.lightImpact();
    AudioService.instance.play(Sfx.sparkle);
    FxBurst.atWidget(
      _cardKey,
      color: LaarishColors.sunflowerDeep,
      style: BurstStyle.sparkle,
    );
    if (widget.flyTo == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final box = _cardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !mounted) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _cardCenter = box.localToGlobal(box.size.center(Offset.zero));
      _flying = true;
    });
    await _flyController.forward();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cardPadding = widget.big ? 36.0 : 28.0;
    return Stack(
      alignment: Alignment.center,
      children: [
        // Rotating volumetric god-rays behind everything.
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _glory,
                builder: (context, _) => CustomPaint(
                  size: Size.infinite,
                  painter: _GloryPainter(t: _glory.value, big: widget.big),
                ),
              ),
            ),
          ),
        ),
        // Rising sparkle field — the air itself celebrates.
        const Positioned.fill(
          child: ParticleField(
            color: LaarishColors.sunflower,
            style: ParticleStyle.sparkle,
            count: 34,
            speed: 1.4,
            opacity: 0.8,
          ),
        ),
        Center(
          child: AnimatedBuilder(
            animation: _flyController,
            builder: (context, child) {
              if (!_flying || _cardCenter == null || widget.flyTo == null) {
                return child!;
              }
              final t = Curves.easeInCubic.transform(_flyController.value);
              // Quadratic bezier arc from card center to the HUD target —
              // DESIGN_SYSTEM.md §4 "Fly-to-HUD" primitive.
              final start = _cardCenter!;
              final end = widget.flyTo!;
              final control =
                  Offset((start.dx + end.dx) / 2, math.min(start.dy, end.dy) - 110);
              final oneMinusT = 1 - t;
              final pos = start * (oneMinusT * oneMinusT) +
                  control * (2 * oneMinusT * t) +
                  end * (t * t);
              return Transform.translate(
                offset: pos - start,
                child: Transform.rotate(
                  angle: t * 0.6, // tumbles as it flies
                  child: Transform.scale(
                    scale: 1 - 0.72 * t,
                    child: Opacity(opacity: 1 - t * t, child: child),
                  ),
                ),
              );
            },
            child: _card(cardPadding),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: widget.big ? 60 : 30,
            emissionFrequency: 0.04,
            gravity: 0.22,
            maxBlastForce: widget.big ? 26 : 18,
            minBlastForce: 8,
            colors: const [
              LaarishColors.sunflower,
              LaarishColors.leaf,
              LaarishColors.tomato,
              LaarishColors.chiliFlame,
              Colors.white,
            ],
          ),
        ),
      ],
    );
  }

  Widget _card(double padding) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: StickerCard(
        key: _cardKey,
        elevation: 2.4,
        glow: LaarishColors.sunflower,
        padding: EdgeInsets.all(padding),
        child: ChainReveal(
          axis: Axis.vertical,
          spacing: 14,
          gap: LaarishMotion.chainStep,
          children: [
            Text(
              widget.big ? 'AMAZING!' : 'Great job!',
              style: LaarishText.display28.copyWith(
                shadows: [
                  Shadow(
                    color: LaarishColors.sunflowerDeep.withValues(alpha: 0.5),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
            _RewardRow(
              icon: Icons.wb_sunny_rounded,
              value: widget.bundle.sunPoints,
              color: LaarishColors.sunflowerDeep,
            ),
            _RewardRow(
              icon: Icons.eco_rounded,
              value: widget.bundle.seedCoins,
              color: LaarishColors.leafDeep,
            ),
            LaarishButton(
              label: 'Collect',
              icon: Icons.auto_awesome_rounded,
              color: LaarishColors.sunflowerDeep,
              hero: true,
              sfx: Sfx.sparkle,
              onTap: _collect,
            ),
          ],
        ),
      ),
    );
  }
}

/// Rotating volumetric light behind the reward card — long soft rays plus a
/// bloom core. Pure CustomPaint, no assets (assets/lottie is still empty).
class _GloryPainter extends CustomPainter {
  _GloryPainter({required this.t, required this.big});

  final double t;
  final bool big;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outer = size.longestSide * 1.1;
    final rayCount = big ? 20 : 14;
    final spin = t * math.pi * 2;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(spin);

    for (var i = 0; i < rayCount; i++) {
      final angle = (2 * math.pi / rayCount) * i;
      // Alternating widths make the fan read as light, not a pinwheel.
      final halfWidth = i.isEven ? 0.055 : 0.028;
      final alpha = i.isEven ? 0.16 : 0.09;
      final path = Path()
        ..moveTo(0, 0)
        ..lineTo(outer * math.cos(angle - halfWidth), outer * math.sin(angle - halfWidth))
        ..lineTo(outer * math.cos(angle + halfWidth), outer * math.sin(angle + halfWidth))
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..shader = RadialGradient(
            colors: [
              LaarishColors.sunflower.withValues(alpha: alpha * 2.2),
              LaarishColors.sunflower.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: Offset.zero, radius: outer)),
      );
    }
    canvas.restore();

    // Bloom core.
    canvas.drawCircle(
      center,
      size.shortestSide * 0.34,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.28),
            LaarishColors.sunflower.withValues(alpha: 0.0),
          ],
        ).createShader(
          Rect.fromCircle(center: center, radius: size.shortestSide * 0.34),
        ),
    );
  }

  @override
  bool shouldRepaint(covariant _GloryPainter old) => old.t != t;
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({required this.icon, required this.value, required this.color});
  final IconData icon;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (value <= 0) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The icon sits in a lit 3D token well, matching the HUD chips it is
        // about to fly into.
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.35, -0.4),
              colors: [Color.lerp(color, Colors.white, 0.6)!, color],
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.55),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 10),
        // Count-up 0 -> value — DESIGN_SYSTEM.md §4 Celebration spec. Eased so
        // it sprints then savours the last few digits.
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.toDouble()),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => Text(
            '+${v.round()}',
            style: LaarishText.display22.copyWith(color: LaarishColors.ink),
          ),
        ),
      ],
    );
  }
}
