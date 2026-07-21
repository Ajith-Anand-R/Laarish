import 'dart:async';
import 'dart:math' as math;
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import '../../core/audio/audio_service.dart';
import '../../core/theme/laarish_colors.dart';
import '../../core/theme/laarish_text.dart';
import '../../core/widgets/sticker_card.dart';
import '../../domain/reward_table.dart';

/// The ONE celebration widget for the whole app (AGENT.md "Celebrations").
/// Level end, badge, streak, certificate all call this — no per-screen
/// bespoke confetti code. Signature is frozen (PARALLEL_AGENTS.md §3) —
/// WS1/WS3/WS4 already call `showRewardOverlay(context, bundle)`; new
/// params below are optional and default null-safe so those calls are
/// untouched.
///
/// [flyTo] — global-coordinate target (e.g. a HUD counter's center, read via
/// a GlobalKey.currentContext's RenderBox) for the DESIGN_SYSTEM.md §4
/// "fly-to-HUD" arc. When null, the overlay just fades/scales out on collect.
/// [big] — grand-celebration mode (bigger card, longer confetti) for
/// milestones like profession complete.
Future<void> showRewardOverlay(
  BuildContext context,
  RewardBundle bundle, {
  Offset? flyTo,
  bool big = false,
}) {
  AudioService.instance.play(Sfx.reward);
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'reward',
    barrierColor: Colors.black.withValues(alpha: 0.4),
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (_, _, _) => _RewardOverlayContent(bundle: bundle, flyTo: flyTo, big: big),
    transitionBuilder: (_, anim, _, child) => ScaleTransition(
      scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
      child: FadeTransition(opacity: anim, child: child),
    ),
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
    with SingleTickerProviderStateMixin {
  late final ConfettiController _confetti;
  late final AnimationController _flyController;
  final _cardKey = GlobalKey();
  Offset? _cardCenter;
  bool _flying = false;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(
      duration: Duration(milliseconds: widget.big ? 1600 : 900),
    );
    _confetti.play();
    _flyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
  }

  @override
  void dispose() {
    _confetti.dispose();
    _flyController.dispose();
    super.dispose();
  }

  Future<void> _collect() async {
    if (widget.flyTo == null || _flying) {
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
      alignment: Alignment.topCenter,
      children: [
        Center(
          child: AnimatedBuilder(
            animation: _flyController,
            builder: (context, child) {
              if (!_flying || _cardCenter == null || widget.flyTo == null) return child!;
              final t = Curves.easeInCubic.transform(_flyController.value);
              // Quadratic bezier arc from card center to the HUD target —
              // DESIGN_SYSTEM.md §4 "Fly-to-HUD" primitive.
              final start = _cardCenter!;
              final end = widget.flyTo!;
              final control = Offset((start.dx + end.dx) / 2, math.min(start.dy, end.dy) - 80);
              final oneMinusT = 1 - t;
              final pos = start * (oneMinusT * oneMinusT) +
                  control * (2 * oneMinusT * t) +
                  end * (t * t);
              return Transform.translate(
                offset: pos - start,
                child: Transform.scale(scale: 1 - 0.6 * t, child: Opacity(opacity: 1 - t, child: child)),
              );
            },
            child: StickerCard(
              key: _cardKey,
              padding: EdgeInsets.all(cardPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.big ? 'AMAZING!' : 'Great job!', style: LaarishText.display28),
                  const SizedBox(height: 16),
                  _RewardRow(
                    icon: Icons.wb_sunny_rounded,
                    value: widget.bundle.sunPoints,
                    color: LaarishColors.sunflowerDeep,
                  ),
                  const SizedBox(height: 8),
                  _RewardRow(
                    icon: Icons.eco_rounded,
                    value: widget.bundle.seedCoins,
                    color: LaarishColors.leafDeep,
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _collect,
                    child: Text('Tap to collect', style: LaarishText.body16.copyWith(color: LaarishColors.soil)),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Code-only "shine" fallback for the Lottie shine burst spec'd in
        // DESIGN_SYSTEM.md §4 — no Lottie asset files exist yet
        // (assets/lottie is empty); this is the pure-CustomPaint substitute.
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _confetti,
            builder: (context, _) => CustomPaint(
              size: Size.infinite,
              painter: _ShineBurstPainter(progress: _confetti.state == ConfettiControllerState.playing ? 1 : 0),
            ),
          ),
        ),
        ConfettiWidget(
          confettiController: _confetti,
          blastDirectionality: BlastDirectionality.explosive,
          numberOfParticles: widget.big ? 48 : 24,
          colors: const [
            LaarishColors.sunflower,
            LaarishColors.leaf,
            LaarishColors.tomato,
            LaarishColors.chiliFlame,
          ],
        ),
      ],
    );
  }
}

/// Radiating light rays behind the reward card — pure CustomPaint, no asset.
class _ShineBurstPainter extends CustomPainter {
  _ShineBurstPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final center = size.center(Offset.zero);
    final paint = Paint()
      ..color = LaarishColors.sunflower.withValues(alpha: 0.18 * progress)
      ..style = PaintingStyle.fill;
    const rayCount = 12;
    final outerRadius = size.shortestSide * 0.9;
    for (var i = 0; i < rayCount; i++) {
      final angle = (2 * math.pi / rayCount) * i;
      final halfWidth = 0.06;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(
          center.dx + outerRadius * math.cos(angle - halfWidth),
          center.dy + outerRadius * math.sin(angle - halfWidth),
        )
        ..lineTo(
          center.dx + outerRadius * math.cos(angle + halfWidth),
          center.dy + outerRadius * math.sin(angle + halfWidth),
        )
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ShineBurstPainter oldDelegate) => oldDelegate.progress != progress;
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
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 8),
        // Count-up 0 -> value over 800ms — DESIGN_SYSTEM.md §4 Celebration spec.
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: value),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (context, animatedValue, _) => Text('+$animatedValue', style: LaarishText.display22),
        ),
      ],
    );
  }
}
