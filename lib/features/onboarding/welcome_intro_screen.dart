import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/motion/micro_animations.dart';
import '../../core/motion/throttled_ticker.dart';
import '../../core/theme/laarish_colors.dart';
import '../../core/theme/laarish_spacing.dart';
import '../../core/theme/laarish_text.dart';
import '../../core/widgets/laarish_button.dart';
import '../../core/widgets/mascot_view.dart';
import '../../core/widgets/speech_bubble.dart';

/// S5 — layered parallax scene (sky/hills/foreground, all code-drawn) with
/// the cast introducing themselves in canon order (CANON.md §2). No image
/// assets exist yet, so hills are gradient shapes and cloud drift is the
/// "parallax" motion, throttled to 30fps per DESIGN_SYSTEM.md §5 perf rule.
class WelcomeIntroScreen extends StatefulWidget {
  const WelcomeIntroScreen({super.key});

  @override
  State<WelcomeIntroScreen> createState() => _WelcomeIntroScreenState();
}

class _Intro {
  const _Intro(this.speaker, this.line, this.color, this.asset, this.energy);
  final String speaker;
  final String line;
  final Color color;
  final String asset;
  final double energy;
}

/// CANON.md §2 verbatim introductions — cover page order. Kids use the
/// `_character` cutouts, mascots the `_mascot` cutouts; Okki's render hasn't
/// shipped yet, so MascotView fails soft to an on-brand blob for it.
const _intros = [
  _Intro('Rishi', "I'm Rishi", LaarishColors.sunflowerDeep, 'assets/images/rishi_character.png', 1.0),
  _Intro('Ayra', "I'm Ayra", LaarishColors.leafDeep, 'assets/images/ayra_character.png', 1.0),
  _Intro('Tommy', "I'm Tommy", LaarishColors.tomato, 'assets/images/tommy_mascot.png', 1.0),
  _Intro('Okki', "I'm Okki", LaarishColors.leaf, 'assets/images/okki_mascot.png', 1.45),
  _Intro('Chilly', "I'm Chilly", LaarishColors.chiliRed, 'assets/images/chilly_mascot.png', 0.6),
  _Intro('Methi', "I'm Methi", Color(0xFFA8D93C), 'assets/images/methi_mascot.png', 1.3),
];

class _WelcomeIntroScreenState extends State<WelcomeIntroScreen> with TickerProviderStateMixin {
  int _index = 0;
  late final AnimationController _popController;
  late final ThrottledTicker _cloudTicker;
  double _cloudPhase = 0;

  @override
  void initState() {
    super.initState();
    _popController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))
      ..forward();
    _cloudTicker = ThrottledTicker(
      this,
      fps: 30,
      onTick: (elapsed) => setState(() => _cloudPhase = elapsed.inMilliseconds / 6000),
    )..start();
  }

  @override
  void dispose() {
    _popController.dispose();
    _cloudTicker.dispose();
    super.dispose();
  }

  bool get _isLast => _index == _intros.length - 1;

  void _next() {
    if (_isLast) {
      context.go('/questions');
      return;
    }
    setState(() => _index++);
    _popController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final intro = _intros[_index];
    return Scaffold(
      body: GestureDetector(
        onTap: _next,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Layer 0: sky gradient.
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [LaarishColors.skyTop, LaarishColors.skyBottom],
                ),
              ),
            ),
            // Layer 1: slow-drifting clouds (far, factor 0.2).
            CustomPaint(painter: _CloudPainter(phase: _cloudPhase), size: Size.infinite),
            // Layer 2: far hills (factor 0.4).
            Align(
              alignment: Alignment.bottomCenter,
              child: CustomPaint(
                size: Size(double.infinity, 220),
                painter: _HillPainter(color: LaarishColors.leaf.withValues(alpha: 0.5), waveHeight: 30),
              ),
            ),
            // Layer 3: near hills / ground (factor 0.7-1.0).
            Align(
              alignment: Alignment.bottomCenter,
              child: CustomPaint(
                size: const Size(double.infinity, 140),
                painter: _HillPainter(color: LaarishColors.leafDeep, waveHeight: 18),
              ),
            ),
            // Foreground: speaking character + speech bubble.
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: LaarishSpacing.xl),
                  Text('Meet the Garden Crew', style: LaarishText.display28, textAlign: TextAlign.center)
                      .animate()
                      .fadeIn(duration: 450.ms)
                      .slideY(begin: -0.4, end: 0, curve: Curves.easeOutBack),
                  const Spacer(),
                  ScaleTransition(
                    scale: CurvedAnimation(parent: _popController, curve: Curves.easeOutBack),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: SpeechBubble(key: ValueKey(_index), text: intro.line),
                        ),
                        const SizedBox(height: LaarishSpacing.sm),
                        // Gentle idle float keeps the speaker "alive" between taps.
                        IdleBounce(
                          height: 8,
                          child: MascotView(
                            key: ValueKey(_index),
                            asset: intro.asset,
                            size: 200,
                            color: intro.color,
                            glow: true,
                            energy: intro.energy,
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 160.ms, duration: 500.ms)
                      .slideY(begin: 0.35, end: 0, delay: 160.ms, curve: Curves.easeOutBack),
                  const SizedBox(height: LaarishSpacing.lg),
                  Text('${_index + 1} / ${_intros.length}  ·  tap to continue',
                          style: LaarishText.body16.copyWith(color: LaarishColors.soil))
                      .animate()
                      .fadeIn(delay: 320.ms, duration: 400.ms),
                  const SizedBox(height: LaarishSpacing.md),
                  LaarishButton(
                    label: _isLast ? 'Watch Our Story' : 'Next',
                    color: LaarishColors.tomato,
                    onTap: _next,
                  )
                      .animate()
                      .fadeIn(delay: 440.ms, duration: 450.ms)
                      .slideY(begin: 0.6, end: 0, delay: 440.ms, curve: Curves.easeOutBack),
                  const SizedBox(height: LaarishSpacing.xl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CloudPainter extends CustomPainter {
  _CloudPainter({required this.phase});
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    for (var i = 0; i < 3; i++) {
      final baseX = (size.width * (0.2 + i * 0.35) + phase * 40 * (i.isEven ? 1 : -1)) % (size.width + 200) - 100;
      final y = size.height * (0.15 + i * 0.08);
      _cloud(canvas, Offset(baseX, y), paint, 1 - i * 0.15);
    }
  }

  void _cloud(Canvas canvas, Offset center, Paint paint, double scale) {
    for (final dx in [-24.0, 0.0, 24.0, 12.0, -12.0]) {
      canvas.drawCircle(center.translate(dx * scale, dx.abs() == 24 ? 6 * scale : 0), 22 * scale, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CloudPainter oldDelegate) => oldDelegate.phase != phase;
}

class _HillPainter extends CustomPainter {
  _HillPainter({required this.color, required this.waveHeight});
  final Color color;
  final double waveHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..moveTo(0, size.height);
    path.lineTo(0, waveHeight * 1.5);
    for (double x = 0; x <= size.width; x += size.width / 6) {
      path.quadraticBezierTo(
        x + size.width / 12,
        (x / size.width).round().isEven ? 0 : waveHeight,
        x + size.width / 6,
        waveHeight * 1.5,
      );
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _HillPainter oldDelegate) => false;
}
