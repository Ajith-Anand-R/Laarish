import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';
import '../../core/fx/fx.dart';
import '../../core/theme/laarish_colors.dart';
import '../../core/theme/laarish_spacing.dart';
import '../../core/theme/laarish_text.dart';
import '../../core/widgets/laarish_button.dart';
import '../../core/widgets/sticker_card.dart';
import '../../domain/badge_rules.dart';
import 'widgets/badge_rosette.dart';
import 'widgets/gardener_rank_badge.dart';

/// S11 — sticker album mirroring the guidebook badge spots (CANON.md §6).
/// Earned badges show a gold rosette (BadgeRosette, code-drawn); unearned
/// slots show the same shape faded/outlined only.
class BadgeBookScreen extends ConsumerWidget {
  const BadgeBookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final save = ref.watch(gameSaveProvider);

    // Physical/digital parity prompt (GAMIFICATION.md §2): when a canon
    // badge (has a guidebook sticker twin) newly appears in the save,
    // nudge the child to stick the real one too.
    ref.listen(gameSaveProvider, (previous, next) {
      final prevIds = previous?.value?.badges.map((b) => b.id).toSet() ?? const <String>{};
      final nextIds = next.value?.badges.map((b) => b.id).toSet() ?? const <String>{};
      final newlyEarned = nextIds.difference(prevIds).where(isCanonBadge);
      if (newlyEarned.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: LaarishColors.leafDeep,
            content: Text(
              'Stick your real badge in your book too!',
              style: LaarishText.body16.copyWith(color: Colors.white),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: LaarishColors.paper,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // A trophy room deserves light: a warm shifting field with gold
          // sparkles rising through it.
          const RepaintBoundary(
            child: AnimatedMeshGradient(
              colors: [
                LaarishColors.paper,
                Color(0x3AFFC93C),
                Color(0x22F5A623),
                Color(0x1A58A83C),
              ],
            ),
          ),
          const RepaintBoundary(
            child: ParticleField(
              color: LaarishColors.sunflower,
              style: ParticleStyle.sparkle,
              count: 20,
              speed: 0.9,
              opacity: 0.5,
            ),
          ),
          SafeArea(
        child: save.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (game) {
            final earnedIds = game.badges.map((b) => b.id).toSet();
            return Padding(
              padding: const EdgeInsets.all(LaarishSpacing.lg),
              child: Column(
                children: [
                  Text('Badge Book', style: LaarishText.display34),
                  const SizedBox(height: LaarishSpacing.sm),
                  GardenerRankBadge(sunPoints: game.wallet.sunPoints),
                  const SizedBox(height: LaarishSpacing.lg),
                  Expanded(
                    child: StickerCard(
                      color: LaarishColors.paperDeep,
                      padding: const EdgeInsets.all(LaarishSpacing.md),
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: LaarishSpacing.md,
                          crossAxisSpacing: LaarishSpacing.sm,
                          childAspectRatio: 0.78,
                        ),
                        itemCount: BadgeCatalog.allIds.length,
                        itemBuilder: (context, i) {
                          final id = BadgeCatalog.allIds[i];
                          return BadgeRosette(
                            id: id,
                            title: BadgeCatalog.titles[id] ?? id,
                            earned: earnedIds.contains(id),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: LaarishSpacing.lg),
                  LaarishButton(
                    label: 'Back to Garden',
                    color: LaarishColors.sunflowerDeep,
                    icon: Icons.local_florist_rounded,
                    onTap: () => context.go('/garden'),
                  ),
                ],
              ),
            );
          },
        ),
          ),
        ],
      ),
    );
  }
}
