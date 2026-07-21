import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../content/journey.dart';
import '../../core/theme/laarish_colors.dart';
import '../../core/theme/laarish_spacing.dart';
import '../../core/theme/laarish_text.dart';
import '../../core/widgets/laarish_button.dart';
import '../../domain/unlock_policy.dart';

/// Shown when a child finishes all five levels of a plant. It celebrates the
/// specific vegetable they grew (its mascot + harvest badge, both awarded in
/// applyLevelReward) with confetti and a spring-in reveal, then sends them back
/// to the map — or to the certificate if this was the fourth and final plant.
class PlantCompleteScreen extends ConsumerStatefulWidget {
  const PlantCompleteScreen({super.key, required this.plantId});
  final String plantId;

  @override
  ConsumerState<PlantCompleteScreen> createState() => _PlantCompleteScreenState();
}

class _PlantCompleteScreenState extends ConsumerState<PlantCompleteScreen> {
  final _confetti = ConfettiController(duration: const Duration(milliseconds: 1600));

  @override
  void initState() {
    super.initState();
    _confetti.play();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  static const _harvestBadge = <String, String>{
    'tommy': 'badge_tommy_harvest',
    'okki': 'badge_okki_harvest',
    'chilly': 'badge_chilly_harvest',
    'methi': 'badge_methi_round2',
  };

  @override
  Widget build(BuildContext context) {
    final meta = plantMeta[widget.plantId];
    final biome = LaarishColors.biome[widget.plantId] ?? LaarishColors.leafDeep;
    final game = ref.watch(gameSaveProvider).valueOrNull;
    final allDone = game != null && UnlockPolicy.professionComplete(game.plants);

    return Scaffold(
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.lerp(biome, Colors.white, 0.5)!,
                    Color.lerp(biome, Colors.black, 0.25)!,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(LaarishSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Harvest time! 🎉',
                            style: LaarishText.display34.copyWith(color: Colors.white))
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: -0.3, end: 0, curve: Curves.easeOutBack),
                    const SizedBox(height: LaarishSpacing.lg),
                    // The vegetable the child grew.
                    Image.asset(
                      'assets/images/${widget.plantId}_mascot.png',
                      width: 200,
                      height: 200,
                      errorBuilder: (_, _, _) => Text(meta?.emoji ?? '🌱',
                          style: const TextStyle(fontSize: 120)),
                    )
                        .animate()
                        .scale(
                          begin: const Offset(0.4, 0.4),
                          end: const Offset(1, 1),
                          duration: 700.ms,
                          curve: Curves.elasticOut,
                        )
                        .then()
                        .shimmer(duration: 1400.ms, color: Colors.white54),
                    const SizedBox(height: LaarishSpacing.md),
                    Text('You grew ${meta?.name ?? widget.plantId}!',
                            style: LaarishText.display28.copyWith(color: Colors.white))
                        .animate()
                        .fadeIn(delay: 300.ms),
                    const SizedBox(height: LaarishSpacing.lg),
                    // The vegetable's harvest badge — the reward for this plant.
                    _RewardBadge(asset: _harvestBadge[widget.plantId])
                        .animate()
                        .fadeIn(delay: 600.ms)
                        .scale(
                          begin: const Offset(0.5, 0.5),
                          end: const Offset(1, 1),
                          delay: 600.ms,
                          curve: Curves.elasticOut,
                        ),
                    const SizedBox(height: LaarishSpacing.xl),
                    LaarishButton(
                      label: allDone ? 'See my certificate' : 'Back to my journey',
                      color: LaarishColors.sunflowerDeep,
                      hero: true,
                      icon: allDone ? Icons.workspace_premium_rounded : Icons.map_rounded,
                      onTap: () => context.go(allDone ? '/certificate' : '/map'),
                    ).animate().fadeIn(delay: 900.ms),
                  ],
                ),
              ),
            ),
          ),
          ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 40,
            colors: const [
              LaarishColors.sunflower,
              LaarishColors.leaf,
              LaarishColors.tomato,
              LaarishColors.chiliFlame,
            ],
          ),
        ],
      ),
    );
  }
}

class _RewardBadge extends StatelessWidget {
  const _RewardBadge({required this.asset});
  final String? asset;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(LaarishSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: LaarishColors.sunflower.withValues(alpha: 0.7),
                blurRadius: 28,
                spreadRadius: 2,
              ),
            ],
          ),
          child: asset == null
              ? const Icon(Icons.emoji_events_rounded, size: 72, color: LaarishColors.sunflowerDeep)
              : Image.asset(
                  'assets/images/$asset.png',
                  width: 96,
                  height: 96,
                  errorBuilder: (_, _, _) => const Icon(Icons.emoji_events_rounded,
                      size: 72, color: LaarishColors.sunflowerDeep),
                ),
        ),
        const SizedBox(height: LaarishSpacing.sm),
        Text('New badge earned!',
            style: LaarishText.body16.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
      ],
    );
  }
}
