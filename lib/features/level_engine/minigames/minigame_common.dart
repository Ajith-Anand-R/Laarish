import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/fx/fx.dart';
import '../../../core/theme/laarish_colors.dart';
import '../../../core/theme/laarish_text.dart';
import '../../../core/widgets/mascot_view.dart';

/// Hero prop illustration for a minigame (`assets/images/mg_<game>.png`) — the
/// living, floating object the child is about to interact with. Fails soft to
/// an on-brand blob if that art hasn't shipped.
///
/// Now sits on a lit stage: a soft ground shadow that squashes as the prop
/// bobs, plus a biome glow pool, so the prop reads as floating in a space
/// rather than pasted onto the card.
class MinigamePropHeader extends StatelessWidget {
  const MinigamePropHeader({super.key, required this.game, required this.color});
  final String game;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SizedBox(
        height: 150,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Light pool on the ground under the prop.
            Container(
              width: 120,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(999),
                gradient: RadialGradient(
                  colors: [
                    color.withValues(alpha: 0.35),
                    color.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: MascotView(
                asset: 'assets/images/mg_$game.png',
                size: 128,
                color: color,
                energy: 0.7,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The shared "you did it" payoff for a minigame: sound, a world knock with a
/// matched haptic, and a particle burst anchored on the prop the child was
/// actually touching.
///
/// One helper so all 12 minigames finish with the *same* felt intensity — the
/// alternative (each game inventing its own confetti) is exactly how a game
/// starts to feel inconsistent.
void celebrateMinigame(
  BuildContext context,
  GlobalKey anchor,
  Color color, {
  bool big = true,
}) {
  AudioService.instance.play(Sfx.sparkle);
  ShakeScope.go(
    context,
    intensity: big ? 11 : 6,
    haptic: big ? HapticImpact.heavy : HapticImpact.medium,
  );
  FxBurst.atWidget(
    anchor,
    color: color,
    style: big ? BurstStyle.celebrate : BurstStyle.pop,
    intensity: big ? 1.2 : 0.8,
  );
}

/// Shared "juicy" tap wrapper — reused by all 12 minigames instead of each
/// rebuilding tap-press logic.
///
/// Now a thin alias over [MagneticTap], so a minigame tile, a button and a
/// map node all share one press physics: magnetic pull toward the finger,
/// squash & stretch, spring overshoot on release, ripple from the touch
/// point, plus haptic + sfx on the activation frame
/// (DESIGN_SYSTEM.md §4, AGENT.md "silence is a bug").
class JuicyTap extends StatelessWidget {
  const JuicyTap({
    super.key,
    required this.child,
    required this.onTap,
    this.enabled = true,
    this.spark = false,
    this.sparkColor,
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback onTap;
  final bool enabled;

  /// Fire a sparkle burst at the touch point — use for "correct"/collect taps.
  final bool spark;
  final Color? sparkColor;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return MagneticTap(
      enabled: enabled,
      onTap: onTap,
      spark: spark,
      sparkColor: sparkColor,
      sfx: Sfx.tap,
      borderRadius: borderRadius ?? BorderRadius.circular(18),
      rippleColor: (sparkColor ?? Colors.white).withValues(alpha: 0.5),
      child: child,
    );
  }
}

/// Round color-blob placeholder — no character/prop art exists yet
/// (AGENT.md CRITICAL CONSTRAINT), so minigames draw a clean on-brand orb
/// instead of leaving blank space.
///
/// Rendered as a lit sphere, not a flat circle: a key-light radial gradient
/// offset up-left, a rim light on the lower-right, a specular hotspot and a
/// layered drop shadow. It also breathes, so no prop on screen is ever dead.
class BiomeBlob extends StatefulWidget {
  const BiomeBlob({
    super.key,
    required this.color,
    this.size = 96,
    this.icon,
    this.animate = true,
  });

  final Color color;
  final double size;
  final IconData? icon;
  final bool animate;

  @override
  State<BiomeBlob> createState() => _BiomeBlobState();
}

class _BiomeBlobState extends State<BiomeBlob>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3000),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final orb = DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.4, -0.45),
          radius: 0.95,
          colors: [
            Color.lerp(widget.color, Colors.white, 0.62)!,
            widget.color,
            Color.lerp(widget.color, Colors.black, 0.30)!,
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
        boxShadow: [
          // Coloured bounce light — the orb lights the surface under it.
          BoxShadow(
            color: widget.color.withValues(alpha: 0.45),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: LaarishColors.soil.withValues(alpha: 0.22),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SizedBox(
        width: s,
        height: s,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Rim light along the lower-right edge.
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.transparent,
                    Colors.white.withValues(alpha: 0.28),
                  ],
                  stops: const [0.62, 1.0],
                ),
              ),
              child: const SizedBox.expand(),
            ),
            // Specular hotspot.
            Positioned(
              left: s * 0.20,
              top: s * 0.14,
              child: Container(
                width: s * 0.26,
                height: s * 0.18,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.85),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            if (widget.icon != null)
              Icon(
                widget.icon,
                color: Colors.white,
                size: s * 0.45,
                shadows: const [
                  Shadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                ],
              ),
          ],
        ),
      ),
    );

    if (!widget.animate) return orb;

    return AnimatedBuilder(
      animation: _c,
      child: orb,
      builder: (context, child) {
        final a = _c.value * 2 * math.pi;
        // Volume-preserving breathe + a slow float.
        final b = 1 + math.sin(a) * 0.035;
        return Transform.translate(
          offset: Offset(0, math.sin(a) * s * 0.03),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values(b, 2 - b, 1),
            child: child,
          ),
        );
      },
    );
  }
}

/// Prompt text shown above every minigame — always sourced from
/// `LevelStep.prompt` (content-driven; never a hardcoded canon number).
/// Springs in so each new instruction *arrives* instead of just appearing.
class MinigamePrompt extends StatelessWidget {
  const MinigamePrompt({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: SpringIn(
        from: const Offset(0, 14),
        beginScale: 0.9,
        child: Text(text, style: LaarishText.body18, textAlign: TextAlign.center),
      ),
    );
  }
}

/// Custom rounded progress fill — no raw Material `LinearProgressIndicator`
/// (AGENT.md "no default Material chrome").
///
/// Liquid look: recessed groove, gradient body, meniscus highlight and a
/// glowing bead on the leading edge, with the fill springing (not tweening)
/// to each new value so progress has weight.
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.value,
    required this.color,
    this.width = 160,
    this.height = 14,
  });

  final double value; // 0..1
  final Color color;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutBack,
      builder: (context, v, _) => SizedBox(
        width: width,
        height: height,
        child: CustomPaint(painter: _LiquidFillPainter(value: v, color: color)),
      ),
    );
  }
}

class _LiquidFillPainter extends CustomPainter {
  _LiquidFillPainter({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Radius.circular(size.height / 2);
    final track = RRect.fromRectAndRadius(Offset.zero & size, r);
    canvas.drawRRect(track, Paint()..color = color.withValues(alpha: 0.16));
    canvas.drawRRect(
      track,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = LaarishColors.soil.withValues(alpha: 0.15),
    );

    final v = value.clamp(0.0, 1.0);
    if (v <= 0.001) return;
    final w = math.max(size.height, size.width * v);
    final fillRect = Rect.fromLTWH(0, 0, w, size.height);
    final fill = RRect.fromRectAndRadius(fillRect, r);

    canvas.drawRRect(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(color, Colors.white, 0.5)!,
            color,
            Color.lerp(color, Colors.black, 0.2)!,
          ],
        ).createShader(fillRect),
    );

    // Meniscus.
    canvas.save();
    canvas.clipRRect(fill);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, size.height * 0.36),
      Paint()..color = Colors.white.withValues(alpha: 0.24),
    );
    canvas.restore();

    // Leading bead.
    final cx = w.clamp(size.height * 0.5, size.width - size.height * 0.2);
    final cy = size.height / 2;
    canvas.drawCircle(
      Offset(cx, cy),
      size.height * 0.9,
      Paint()
        ..color = color.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(
      Offset(cx, cy),
      size.height * 0.32,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _LiquidFillPainter old) =>
      old.value != value || old.color != color;
}
