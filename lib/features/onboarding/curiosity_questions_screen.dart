import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';
import '../../core/theme/laarish_colors.dart';
import '../../core/theme/laarish_spacing.dart';
import '../../core/theme/laarish_text.dart';
import '../../core/widgets/laarish_button.dart';
import '../../core/widgets/ribbon_banner.dart';
import '../../core/widgets/sticker_card.dart';

/// S7 — swipeable curiosity-question cards in Rishi/Ayra's voice
/// (PLAN.md "Why plants? Why farming?"). Loads from
/// `assets/content/questions.json` via the frozen ContentRepository; the
/// const list below is the fail-soft fallback (ARCHITECTURE.md §3.7 — a
/// child is never blocked by a missing/corrupt asset).
class CuriosityQuestionsScreen extends ConsumerStatefulWidget {
  const CuriosityQuestionsScreen({super.key});

  @override
  ConsumerState<CuriosityQuestionsScreen> createState() => _CuriosityQuestionsScreenState();
}

const _fallbackQuestions = <Map<String, String>>[
  {'speaker': 'Rishi', 'q': 'Why do we grow plants?', 'a': 'Plants give us food, fresh air, and fun!'},
  {'speaker': 'Ayra', 'q': 'Why farming?', 'a': 'Farmers grow the food we eat every day!'},
];

class _CuriosityQuestionsScreenState extends ConsumerState<CuriosityQuestionsScreen> {
  final _controller = PageController(viewportFraction: 0.82);
  final _revealed = <int>{};
  int _page = 0;
  List<Map<String, String>> _questions = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    List<Map<String, String>> loaded;
    try {
      final json = await ref.read(contentRepositoryProvider).loadJson('assets/content/questions.json');
      loaded = (json['questions'] as List)
          .map((e) => (e as Map).map((k, v) => MapEntry(k as String, v as String)))
          .toList();
    } catch (_) {
      loaded = _fallbackQuestions; // fail-soft — never block the child
    }
    if (!mounted) return;
    setState(() => _questions = loaded);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLast => _page == _questions.length - 1;

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return const Scaffold(
        backgroundColor: LaarishColors.paper,
        body: Center(child: CircularProgressIndicator(color: LaarishColors.leaf)),
      );
    }
    return Scaffold(
      backgroundColor: LaarishColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: LaarishSpacing.lg),
            const RibbonBanner(text: 'Curious Minds', color: LaarishColors.leafDeep),
            const SizedBox(height: LaarishSpacing.sm),
            Text('Tap a card to bloom the answer', style: LaarishText.body16),
            Expanded(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return PageView.builder(
                    controller: _controller,
                    itemCount: _questions.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (context, index) {
                      double offset = index.toDouble() - _page;
                      if (_controller.hasClients && _controller.position.haveDimensions) {
                        offset = (_controller.page ?? _page.toDouble()) - index;
                      }
                      final angle = offset.clamp(-1.0, 1.0) * -0.25;
                      final scale = (1 - offset.abs() * 0.15).clamp(0.85, 1.0);
                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..rotateZ(angle * 0.3)
                          ..scaleByDouble(scale, scale, scale, 1),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: LaarishSpacing.sm, vertical: LaarishSpacing.md),
                          child: _QuestionCard(
                            data: _questions[index],
                            revealed: _revealed.contains(index),
                            onTap: () => setState(() => _revealed.add(index)),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(LaarishSpacing.lg),
              child: LaarishButton(
                label: _isLast ? 'See My Garden Path' : 'Next',
                color: LaarishColors.leaf,
                onTap: () {
                  if (_isLast) {
                    context.go('/map');
                  } else {
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Signature motion: the card physically flips over its vertical axis to turn
/// the question into the answer, and a color ripple in the speaker's hue blooms
/// out from the centre the instant it's tapped.
class _QuestionCard extends StatefulWidget {
  const _QuestionCard({required this.data, required this.revealed, required this.onTap});
  final Map<String, String> data;
  final bool revealed;
  final VoidCallback onTap;

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> with SingleTickerProviderStateMixin {
  late final AnimationController _flip =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 620));

  @override
  void initState() {
    super.initState();
    if (widget.revealed) _flip.value = 1; // already-revealed cards start flipped
  }

  @override
  void didUpdateWidget(_QuestionCard old) {
    super.didUpdateWidget(old);
    if (!old.revealed && widget.revealed) _flip.forward(from: 0);
  }

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final speaker = widget.data['speaker']!;
    final color = speaker == 'Rishi' ? LaarishColors.sunflowerDeep : LaarishColors.leafDeep;
    return GestureDetector(
      onTap: widget.revealed ? null : widget.onTap,
      child: AnimatedBuilder(
        animation: _flip,
        builder: (context, _) {
          final t = _flip.value;
          final angle = t * math.pi;
          final showBack = angle > math.pi / 2;
          final popScale = 1 + math.sin(t * math.pi) * 0.05; // satisfying mid-flip bump
          final face = showBack
              ? _face(
                  speaker,
                  color,
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _Flower(),
                      const SizedBox(height: LaarishSpacing.md),
                      Text(widget.data['a']!, style: LaarishText.body18, textAlign: TextAlign.center),
                    ],
                  ),
                )
              : _face(
                  speaker,
                  color,
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(widget.data['q']!, style: LaarishText.display22, textAlign: TextAlign.center),
                      const SizedBox(height: LaarishSpacing.md),
                      Text('Tap to find out!',
                          style: LaarishText.body16.copyWith(color: LaarishColors.soil)),
                    ],
                  ),
                );
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..scaleByDouble(popScale, popScale, popScale, 1)
              ..rotateY(angle),
            child: Transform(
              // Counter-rotate the back face so the answer text isn't mirrored.
              alignment: Alignment.center,
              transform: Matrix4.identity()..rotateY(showBack ? math.pi : 0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  face,
                  if (t > 0 && t < 1)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(painter: _RipplePainter(progress: t, color: color)),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _face(String speaker, Color color, Widget inner) {
    return StickerCard(
      padding: const EdgeInsets.all(LaarishSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          RibbonBanner(text: speaker, color: color),
          const SizedBox(height: LaarishSpacing.lg),
          inner,
        ],
      ),
    );
  }
}

/// Expanding, fading ring in the speaker's colour — the "color ripple" on tap.
class _RipplePainter extends CustomPainter {
  _RipplePainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.longestSide * 0.65;
    final r = maxR * Curves.easeOutCubic.transform(progress);
    final paint = Paint()
      ..color = color.withValues(alpha: 0.35 * (1 - progress))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10 * (1 - progress) + 2;
    canvas.drawCircle(center, r, paint);
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class _Flower extends StatelessWidget {
  const _Flower();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: CustomPaint(painter: _FlowerPainter()),
    );
  }
}

class _FlowerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final petalPaint = Paint()..color = LaarishColors.sunflower;
    const petals = 6;
    for (var i = 0; i < petals; i++) {
      final angle = (2 * math.pi / petals) * i;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      canvas.drawOval(const Rect.fromLTWH(-6, -24, 12, 20), petalPaint);
      canvas.restore();
    }
    canvas.drawCircle(center, 10, Paint()..color = LaarishColors.sunflowerDeep);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
