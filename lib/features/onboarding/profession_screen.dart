import 'dart:ui' as ui;
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';
import '../../core/motion/micro_animations.dart';
import '../../core/theme/laarish_colors.dart';
import '../../core/theme/laarish_spacing.dart';
import '../../core/theme/laarish_text.dart';
import '../../core/widgets/ribbon_banner.dart';
import '../../core/widgets/shader_view.dart';

/// Grayscale luminance matrix — desaturates the locked "coming soon" cards.
const _desaturate = <double>[
  0.33, 0.59, 0.11, 0, 0, //
  0.33, 0.59, 0.11, 0, 0, //
  0.33, 0.59, 0.11, 0, 0, //
  0, 0, 0, 1, 0, //
];

/// S4 — "Choose Your Path". A living garden sky (roadmap_bg shader) behind a
/// glass 3D card carousel: the live Agriculturist card glows and floats
/// forward, locked professions sit back, frosted and greyed. Choosing sets
/// GameSave.kitActivated (UnlockPolicy gates Tommy on it — ARCHITECTURE.md
/// §3.2) and bursts confetti before the intro video.
class ProfessionScreen extends ConsumerStatefulWidget {
  const ProfessionScreen({super.key});

  @override
  ConsumerState<ProfessionScreen> createState() => _ProfessionScreenState();
}

class _Profession {
  const _Profession(this.title, this.subtitle, this.color, this.icon, {this.live = false});
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final bool live;
}

const _professions = [
  _Profession("I'm An Agriculturist", 'A Guidebook for Future Agriculturists', LaarishColors.leafDeep,
      Icons.agriculture_rounded, live: true),
  _Profession('Baker', 'Coming soon', Colors.grey, Icons.cake_rounded),
  _Profession('Builder', 'Coming soon', Colors.grey, Icons.construction_rounded),
  _Profession('Explorer', 'Coming soon', Colors.grey, Icons.explore_rounded),
];

class _ProfessionScreenState extends ConsumerState<ProfessionScreen> {
  late final PageController _controller = PageController(viewportFraction: 0.76);
  late final ConfettiController _confetti =
      ConfettiController(duration: const Duration(milliseconds: 900));
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final p = _controller.page ?? 0;
      if (p != _page) setState(() => _page = p);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    _confetti.play();
    await ref.read(gameSaveProvider.notifier).mutate((save) {
      save.kitActivated = true;
      return save;
    });
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (mounted) context.go('/story');
  }

  @override
  Widget build(BuildContext context) {
    const leaf = LaarishColors.leaf;
    return Scaffold(
      body: Stack(
        children: [
          // Living garden-sky background.
          Positioned.fill(
            child: ShaderView(
              asset: 'shaders/roadmap_bg.frag',
              extraFloats: [leaf.r, leaf.g, leaf.b],
              fallback: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFBFE9A8), LaarishColors.leaf, LaarishColors.leafDeep],
                  ),
                ),
              ),
            ),
          ),
          // Soft dark scrim at the bottom for text legibility.
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0x33000000)],
                  stops: [0.55, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: LaarishSpacing.xl),
                Text('Choose Your Path',
                        style: LaarishText.display34.copyWith(
                          color: Colors.white,
                          shadows: const [Shadow(color: Colors.black38, blurRadius: 12, offset: Offset(0, 3))],
                        ),
                        textAlign: TextAlign.center)
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: -0.4, end: 0, curve: Curves.easeOutBack, duration: 600.ms),
                const SizedBox(height: 4),
                Text('Swipe to explore · tap to begin',
                        style: LaarishText.body16.copyWith(color: Colors.white.withValues(alpha: 0.85)))
                    .animate()
                    .fadeIn(delay: 250.ms, duration: 500.ms),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _professions.length,
                    itemBuilder: (context, index) {
                      final offset = _page - index;
                      final angle = offset.clamp(-1.0, 1.0) * 0.55;
                      final focused = offset.abs() < 0.35;
                      final scale = (1 - offset.abs() * 0.16).clamp(0.82, 1.0) + (focused ? 0.04 : 0.0);
                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.0025)
                          ..rotateY(angle)
                          ..scaleByDouble(scale, scale, scale, 1),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: LaarishSpacing.sm, vertical: LaarishSpacing.md),
                          child: _ProfessionCard(
                            profession: _professions[index],
                            onStart: _start,
                            focused: focused,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                _PageDots(count: _professions.length, page: _page),
                const SizedBox(height: LaarishSpacing.lg),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0,
              numberOfParticles: 28,
              maxBlastForce: 24,
              minBlastForce: 8,
              gravity: 0.3,
              colors: const [
                LaarishColors.sunflower,
                LaarishColors.leaf,
                LaarishColors.tomato,
                LaarishColors.sunflowerDeep,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfessionCard extends StatelessWidget {
  const _ProfessionCard({required this.profession, required this.onStart, this.focused = false});
  final _Profession profession;
  final VoidCallback onStart;
  final bool focused;

  @override
  Widget build(BuildContext context) {
    final live = profession.live;
    final accent = live ? profession.color : Colors.grey;

    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(LaarishSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: live
                  ? [Colors.white.withValues(alpha: 0.9), Color.lerp(Colors.white, accent, 0.18)!.withValues(alpha: 0.85)]
                  : [Colors.white.withValues(alpha: 0.32), Colors.white.withValues(alpha: 0.16)],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 1.6),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RibbonBanner(
                text: live ? 'Agriculturist' : 'Coming Soon',
                color: live ? accent : Colors.grey.shade500,
              ),
              const SizedBox(height: LaarishSpacing.lg),
              Expanded(
                child: Center(
                  child: live
                      ? Breathing(
                          amount: 0.03,
                          child: Image.asset(
                            'assets/images/all_characters.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => Icon(profession.icon, size: 80, color: accent),
                          ),
                        )
                      : Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                          child: Icon(profession.icon, size: 60, color: Colors.grey.shade600),
                        ),
                ),
              ),
              const SizedBox(height: LaarishSpacing.md),
              Text(profession.title,
                  style: LaarishText.display22.copyWith(color: live ? LaarishColors.ink : LaarishColors.soil),
                  textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(profession.subtitle,
                  style: LaarishText.body16.copyWith(color: LaarishColors.soil),
                  textAlign: TextAlign.center),
              const SizedBox(height: LaarishSpacing.lg),
              if (live)
                _StartButton(color: accent, onTap: onStart)
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_rounded, color: Colors.grey.shade500, size: 20),
                    const SizedBox(width: 6),
                    Text('Locked', style: LaarishText.body16.copyWith(color: Colors.grey.shade600)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );

    if (!live) {
      return Opacity(
        opacity: 0.7,
        child: ColorFiltered(colorFilter: const ColorFilter.matrix(_desaturate), child: card),
      );
    }
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: focused ? 0.55 : 0.25),
            blurRadius: focused ? 40 : 18,
            spreadRadius: focused ? 3 : 0,
          ),
        ],
      ),
      child: card,
    );
  }
}

/// Glossy gradient CTA with a slow shine sweep.
class _StartButton extends StatelessWidget {
  const _StartButton({required this.color, required this.onTap});
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.lerp(color, Colors.white, 0.25)!, color],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Text('Start My Journey',
            textAlign: TextAlign.center,
            style: LaarishText.button.copyWith(color: Colors.white, fontSize: 17)),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 2200.ms, color: Colors.white.withValues(alpha: 0.55), angle: 0.4);
  }
}

/// Pill page indicator — the active dot stretches into the biome colour.
class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.page});
  final int count;
  final double page;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: (page.round() == i) ? 26 : 9,
            height: 9,
            decoration: BoxDecoration(
              color: (page.round() == i) ? Colors.white : Colors.white.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
      ],
    );
  }
}
