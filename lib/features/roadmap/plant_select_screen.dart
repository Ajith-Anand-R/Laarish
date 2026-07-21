import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../content/journey.dart';
import '../../core/theme/laarish_colors.dart';
import '../../core/theme/laarish_spacing.dart';
import '../../core/theme/laarish_text.dart';
import '../../data/local/entities.dart';
import '../../domain/unlock_policy.dart';

/// The journey home (S8, the Map tab): the four plants of the agriculturist
/// path. Each is locked until the previous plant is fully harvested; tapping an
/// unlocked plant opens its five levels. Finishing all four reveals the Proud
/// Agriculturist certificate.
class PlantSelectScreen extends ConsumerWidget {
  const PlantSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final save = ref.watch(gameSaveProvider);
    return Scaffold(
      backgroundColor: LaarishColors.skyBottom,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/journey_background.png',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const ColoredBox(color: LaarishColors.skyBottom),
            ),
          ),
          // Soft scrim so the busy scene never competes with the cards/text.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    LaarishColors.paper.withValues(alpha: 0.55),
                    LaarishColors.paper.withValues(alpha: 0.30),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: save.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (game) => _Body(game: game),
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.game});
  final GameSave game;

  @override
  Widget build(BuildContext context) {
    final done = UnlockPolicy.professionComplete(game.plants);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(LaarishSpacing.lg),
        children: [
          Text('My Journey', style: LaarishText.display34),
          const SizedBox(height: LaarishSpacing.xs),
          Text(
            'Grow all four plants to become a Proud Agriculturist!',
            style: LaarishText.body16.copyWith(color: LaarishColors.soil),
          ),
          const SizedBox(height: LaarishSpacing.lg),
          for (var i = 0; i < UnlockPolicy.plantOrder.length; i++) ...[
            _PlantCard(
              plantId: UnlockPolicy.plantOrder[i],
              levelsDone: game.plants[UnlockPolicy.plantOrder[i]]?.levelsDone ?? 0,
            ).animate().fadeIn(delay: (120 * i).ms).slideY(
                  begin: 0.25,
                  end: 0,
                  delay: (120 * i).ms,
                  curve: Curves.easeOutBack,
                ),
            const SizedBox(height: LaarishSpacing.md),
          ],
          if (done) ...[
            const SizedBox(height: LaarishSpacing.sm),
            _CertificateBanner(onTap: () => context.go('/certificate')),
          ],
        ],
      ),
    );
  }
}

class _PlantCard extends StatelessWidget {
  const _PlantCard({
    required this.plantId,
    required this.levelsDone,
  });

  final String plantId;
  final int levelsDone;

  @override
  Widget build(BuildContext context) {
    final meta = plantMeta[plantId];
    final biome = LaarishColors.biome[plantId] ?? LaarishColors.leafDeep;
    final complete = levelsDone >= 5;

    // Every plant is always open and re-enterable — solid, opaque card.
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(LaarishSpacing.cardRadius),
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      child: InkWell(
        borderRadius: BorderRadius.circular(LaarishSpacing.cardRadius),
        onTap: () => context.go('/plant/$plantId'),
        child: Padding(
            padding: const EdgeInsets.all(LaarishSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Color.lerp(biome, Colors.white, 0.6)!, biome],
                    ),
                  ),
                  child: Image.asset(
                    'assets/images/${plantId}_mascot.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) =>
                        Center(child: Text(meta?.emoji ?? '🌱', style: const TextStyle(fontSize: 30))),
                  ),
                ),
                const SizedBox(width: LaarishSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(meta?.name ?? plantId, style: LaarishText.display22),
                      Text('${meta?.subtitle ?? ''} · $levelsDone/5 levels',
                          style: LaarishText.body16.copyWith(color: LaarishColors.soil)),
                      const SizedBox(height: LaarishSpacing.sm),
                      _ProgressBar(value: levelsDone / 5, color: biome),
                    ],
                  ),
                ),
                const SizedBox(width: LaarishSpacing.sm),
                Icon(
                  complete ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
                  color: complete ? LaarishColors.leaf : LaarishColors.soil,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value, required this.color});
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: 8,
        backgroundColor: LaarishColors.paperDeep,
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}

class _CertificateBanner extends StatelessWidget {
  const _CertificateBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LaarishColors.sunflower,
      borderRadius: BorderRadius.circular(LaarishSpacing.cardRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(LaarishSpacing.cardRadius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(LaarishSpacing.lg),
          child: Row(
            children: [
              Image.asset(
                'assets/images/badge_proud_agriculturist.png',
                width: 48,
                height: 48,
                errorBuilder: (_, _, _) => const Text('🏆', style: TextStyle(fontSize: 32)),
              ),
              const SizedBox(width: LaarishSpacing.md),
              Expanded(
                child: Text('Proud Agriculturist!\nSee your certificate',
                    style: LaarishText.display22),
              ),
              const Icon(Icons.chevron_right_rounded, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}
