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
import '../../data/local/entities.dart';
import '../../domain/unlock_policy.dart';

/// The Progress tab (replaces the old Badge Book tab): a live dashboard of how
/// far the young agriculturist has come — plants grown, levels cleared, points
/// banked, badges earned — with everything animating in.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final save = ref.watch(gameSaveProvider);
    return Scaffold(
      backgroundColor: LaarishColors.paper,
      body: save.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (game) => SafeArea(child: _Body(game: game)),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.game});
  final GameSave game;

  @override
  Widget build(BuildContext context) {
    final plants = UnlockPolicy.plantOrder;
    final levelsDone =
        plants.fold<int>(0, (sum, id) => sum + (game.plants[id]?.levelsDone ?? 0));
    final plantsDone = plants.where((id) => (game.plants[id]?.levelsDone ?? 0) >= 5).length;
    const totalLevels = 20;

    return ListView(
      padding: const EdgeInsets.all(LaarishSpacing.lg),
      children: [
        Text('My Progress', style: LaarishText.display34),
        const SizedBox(height: LaarishSpacing.lg),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.local_florist_rounded,
                value: '$plantsDone/4',
                label: 'Plants grown',
                color: LaarishColors.leaf,
              ),
            ),
            const SizedBox(width: LaarishSpacing.md),
            Expanded(
              child: _StatTile(
                icon: Icons.checklist_rounded,
                value: '$levelsDone/$totalLevels',
                label: 'Levels done',
                color: LaarishColors.sunflowerDeep,
              ),
            ),
          ],
        ),
        const SizedBox(height: LaarishSpacing.md),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.wb_sunny_rounded,
                value: '${game.wallet.sunPoints}',
                label: 'Sun points',
                color: LaarishColors.sunflowerDeep,
              ),
            ),
            const SizedBox(width: LaarishSpacing.md),
            Expanded(
              child: _StatTile(
                icon: Icons.workspace_premium_rounded,
                value: '${game.badges.length}',
                label: 'Badges',
                color: LaarishColors.tomato,
              ),
            ),
          ],
        ),
        const SizedBox(height: LaarishSpacing.lg),
        Text('Each plant', style: LaarishText.display22),
        const SizedBox(height: LaarishSpacing.md),
        for (var i = 0; i < plants.length; i++)
          _PlantProgressRow(
            plantId: plants[i],
            levelsDone: game.plants[plants[i]]?.levelsDone ?? 0,
          ).animate().fadeIn(delay: (100 * i).ms).slideX(begin: 0.15, end: 0),
        const SizedBox(height: LaarishSpacing.lg),
        if (UnlockPolicy.professionComplete(game.plants))
          LaarishButton(
            label: 'View my certificate',
            color: LaarishColors.sunflowerDeep,
            icon: Icons.workspace_premium_rounded,
            hero: true,
            onTap: () => context.go('/certificate'),
          ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LaarishSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(LaarishSpacing.cardRadius),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: LaarishSpacing.xs),
          Text(value, style: LaarishText.display28),
          Text(label, style: LaarishText.body16.copyWith(color: LaarishColors.soil)),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
  }
}

class _PlantProgressRow extends StatelessWidget {
  const _PlantProgressRow({required this.plantId, required this.levelsDone});
  final String plantId;
  final int levelsDone;

  @override
  Widget build(BuildContext context) {
    final meta = plantMeta[plantId];
    final biome = LaarishColors.biome[plantId] ?? LaarishColors.leafDeep;
    return Padding(
      padding: const EdgeInsets.only(bottom: LaarishSpacing.md),
      child: Row(
        children: [
          Image.asset(
            'assets/images/${plantId}_mascot.png',
            width: 44,
            height: 44,
            errorBuilder: (_, _, _) => Text(meta?.emoji ?? '🌱', style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: LaarishSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${meta?.name ?? plantId} · $levelsDone/5',
                    style: LaarishText.body16.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: LaarishSpacing.xs),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: (levelsDone / 5).clamp(0.0, 1.0)),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => LinearProgressIndicator(
                      value: v,
                      minHeight: 10,
                      backgroundColor: LaarishColors.paperDeep,
                      valueColor: AlwaysStoppedAnimation(biome),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (levelsDone >= 5) ...[
            const SizedBox(width: LaarishSpacing.sm),
            const Icon(Icons.check_circle_rounded, color: LaarishColors.leaf),
          ],
        ],
      ),
    );
  }
}
