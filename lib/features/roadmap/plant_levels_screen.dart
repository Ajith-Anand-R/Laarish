import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../content/journey.dart';
import '../../core/theme/laarish_colors.dart';
import '../../core/theme/laarish_spacing.dart';
import '../../core/theme/laarish_text.dart';
import '../../data/local/entities.dart';
import '../../domain/unlock_policy.dart';

/// The five levels of one plant. Reached by tapping a plant on the journey
/// map. Level N is locked until level N-1 is done; tapping an available level
/// opens its video lesson (`/level/:plant/:n`).
class PlantLevelsScreen extends ConsumerWidget {
  const PlantLevelsScreen({super.key, required this.plantId});
  final String plantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final save = ref.watch(gameSaveProvider);
    final meta = plantMeta[plantId];
    final biome = LaarishColors.biome[plantId] ?? LaarishColors.leafDeep;
    return Scaffold(
      backgroundColor: LaarishColors.paper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: LaarishColors.ink,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/map'),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/${plantId}_mascot.png',
              width: 36,
              height: 36,
              errorBuilder: (_, _, _) =>
                  Text(meta?.emoji ?? '', style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: LaarishSpacing.sm),
            Text(meta?.name ?? plantId, style: LaarishText.display22),
          ],
        ),
      ),
      body: save.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (game) => _Body(plantId: plantId, biome: biome, game: game),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.plantId, required this.biome, required this.game});
  final String plantId;
  final Color biome;
  final GameSave game;

  @override
  Widget build(BuildContext context) {
    final done = game.plants[plantId]?.levelsDone ?? 0;
    return SafeArea(
      child: ListView.separated(
        padding: const EdgeInsets.all(LaarishSpacing.lg),
        itemCount: levelTitles.length,
        separatorBuilder: (_, _) => const SizedBox(height: LaarishSpacing.md),
        itemBuilder: (context, i) {
          final level = i + 1;
          final isDone = level <= done;
          final unlocked = UnlockPolicy.levelUnlocked(plantId, level, game.plants,
              professionStarted: game.kitActivated);
          return _LevelTile(
            plantId: plantId,
            level: level,
            title: levelTitles[i],
            biome: biome,
            done: isDone,
            unlocked: unlocked,
          );
        },
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.plantId,
    required this.level,
    required this.title,
    required this.biome,
    required this.done,
    required this.unlocked,
  });

  final String plantId;
  final int level;
  final String title;
  final Color biome;
  final bool done;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final open = unlocked || done;
    return Opacity(
      opacity: open ? 1 : 0.5,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(LaarishSpacing.cardRadius),
        elevation: 2,
        shadowColor: biome.withValues(alpha: 0.3),
        child: InkWell(
          borderRadius: BorderRadius.circular(LaarishSpacing.cardRadius),
          onTap: open ? () => context.go('/level/$plantId/$level') : null,
          child: Padding(
            padding: const EdgeInsets.all(LaarishSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? LaarishColors.leaf : biome,
                  ),
                  child: done
                      ? const Icon(Icons.check_rounded, color: Colors.white)
                      : Text('$level',
                          style: LaarishText.display22.copyWith(color: Colors.white)),
                ),
                const SizedBox(width: LaarishSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Level $level', style: LaarishText.body16.copyWith(color: LaarishColors.soil)),
                      Text(title, style: LaarishText.display22),
                    ],
                  ),
                ),
                Icon(
                  done
                      ? Icons.replay_rounded
                      : unlocked
                          ? Icons.play_arrow_rounded
                          : Icons.lock_rounded,
                  color: LaarishColors.soil,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
