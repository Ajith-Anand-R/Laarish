import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/theme/laarish_colors.dart';
import '../../core/theme/laarish_spacing.dart';
import '../../core/motion/micro_animations.dart';
import '../../core/theme/laarish_text.dart';
import '../../core/widgets/hud_bar.dart';
import '../../core/widgets/laarish_button.dart';
import '../../core/widgets/shader_view.dart';
import '../../core/widgets/sticker_card.dart';
import '../../data/local/entities.dart';
import '../../domain/mission_generator.dart';
import '../../domain/reward_table.dart';
import '../../domain/streak_policy.dart';
import '../../domain/unlock_policy.dart';
import '../rewards/reward_overlay.dart';
import 'notification_service.dart';
import 'widgets/plant_card.dart';

/// S10 — My Garden: per-plant live cards, today's missions, streak flame,
/// sprout countdown, all-missions-done daily chest. WS4 (AGENT.md §3
/// "Daily care", GAMIFICATION.md §3-4).
class GardenHomeScreen extends ConsumerStatefulWidget {
  const GardenHomeScreen({super.key});

  @override
  ConsumerState<GardenHomeScreen> createState() => _GardenHomeScreenState();
}

class _GardenHomeScreenState extends ConsumerState<GardenHomeScreen> {
  // ponytail: not persisted (ARCHITECTURE.md §3.1 forbids a Mission entity
  // in the save file) — a mid-day app restart loses in-progress ticks.
  // "All done today" itself survives via GameSave.streak.lastCompletedDay.
  final Set<String> _completedToday = {};
  bool _notificationsOn = false;

  @override
  Widget build(BuildContext context) {
    final save = ref.watch(gameSaveProvider);
    final today = DateTime.now();

    return Scaffold(
      backgroundColor: LaarishColors.paper,
      body: SafeArea(
        child: save.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (game) => _buildBody(context, game, today),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, GameSave game, DateTime today) {
    final activePlants = [
      for (final id in UnlockPolicy.plantOrder)
        if (game.plants[id] != null && game.plants[id]!.stage != PlantStage.locked) game.plants[id]!,
    ];

    final missionsByPlant = {
      for (final p in activePlants) p.plantId: generateDailyMissions(p, today),
    };
    final allMissionIds = [
      for (final missions in missionsByPlant.values) for (final m in missions) m.id,
    ];

    final lastDone = game.streak.lastCompletedDay;
    final alreadyDoneToday =
        lastDone != null && lastDone.year == today.year && lastDone.month == today.month && lastDone.day == today.day;
    final effectiveCompleted = alreadyDoneToday ? allMissionIds.toSet() : _completedToday;

    return ListView(
      padding: const EdgeInsets.all(LaarishSpacing.lg),
      children: [
        // Living leaf-shimmer banner (leaf_shimmer.frag) with blinking eyes.
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(
            height: 88,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ShaderView(
                    asset: 'shaders/leaf_shimmer.frag',
                    fallback: Container(color: LaarishColors.leaf),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: LaarishSpacing.lg),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text('My Garden', style: LaarishText.display28.copyWith(color: Colors.white)),
                          const SizedBox(width: LaarishSpacing.sm),
                          const BlinkingEyes(size: 20),
                        ],
                      ),
                      HudBar(
                        sunPoints: game.wallet.sunPoints,
                        seedCoins: game.wallet.seedCoins,
                        streak: game.streak.current,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: LaarishSpacing.md),
        _NotificationToggle(
          value: _notificationsOn,
          onChanged: (v) {
            setState(() => _notificationsOn = v);
            GardenNotificationService.instance.setEnabled(v);
          },
        ),
        const SizedBox(height: LaarishSpacing.lg),
        if (activePlants.isEmpty)
          StickerCard(
            child: Text(
              'Scan your kit or pick "I Am an Agriculturist" to start your first plant!',
              style: LaarishText.body18,
            ),
          )
        else ...[
          if (alreadyDoneToday)
            Padding(
              padding: const EdgeInsets.only(bottom: LaarishSpacing.md),
              child: StickerCard(
                color: LaarishColors.leaf.withValues(alpha: 0.15),
                child: Text('All done for today! Come back tomorrow 🌞', style: LaarishText.body18),
              ),
            ),
          for (final plant in activePlants)
            PlantCard(
              plant: plant,
              missions: missionsByPlant[plant.plantId] ?? const [],
              completedIds: effectiveCompleted,
              today: today,
              onToggle: alreadyDoneToday
                  ? (_) {}
                  : (id) => _onToggle(id, allMissionIds, today),
            ),
        ],
      ],
    );
  }

  void _onToggle(String missionId, List<String> allMissionIds, DateTime today) {
    setState(() {
      if (_completedToday.contains(missionId)) {
        _completedToday.remove(missionId);
      } else {
        _completedToday.add(missionId);
      }
    });
    if (allMissionIds.isNotEmpty && allMissionIds.every(_completedToday.contains)) {
      _completeDailyMissions(today);
    }
  }

  Future<void> _completeDailyMissions(DateTime today) async {
    final current = ref.read(gameSaveProvider).value;
    if (current == null) return;
    final update = updateStreakOnAllMissionsDone(current.streak, today);
    if (update.alreadyDoneToday) return;

    if (update.isWelcomeBack && mounted) {
      await _showWelcomeBack(context);
    }

    await ref.read(gameSaveProvider.notifier).mutate((save) {
      save.streak = update.streak;
      save.wallet.sunPoints += RewardTable.dailyMissionsAllDone.sunPoints;
      save.wallet.seedCoins += RewardTable.dailyMissionsAllDone.seedCoins;
      return save;
    });

    if (mounted) {
      await showRewardOverlay(context, RewardTable.dailyMissionsAllDone);
    }
  }

  Future<void> _showWelcomeBack(BuildContext context) {
    // GAMIFICATION.md §6 — gentle reset, warm copy, never guilt/shaming.
    return showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: StickerCard(
          padding: const EdgeInsets.all(LaarishSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Welcome back! 🌱', style: LaarishText.display22, textAlign: TextAlign.center),
              const SizedBox(height: LaarishSpacing.sm),
              Text(
                'Your garden missed you. Let\'s grow together again!',
                style: LaarishText.body16,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: LaarishSpacing.lg),
              LaarishButton(label: 'Let\'s go!', onTap: () => Navigator.of(ctx).pop()),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationToggle extends StatelessWidget {
  const _NotificationToggle({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return StickerCard(
      padding: const EdgeInsets.symmetric(horizontal: LaarishSpacing.md, vertical: LaarishSpacing.sm),
      child: Row(
        children: [
          const Icon(Icons.notifications_active_rounded, color: LaarishColors.sunflowerDeep),
          const SizedBox(width: LaarishSpacing.sm),
          Expanded(
            child: Text('Daily reminder (1/day, opt-in)', style: LaarishText.body16),
          ),
          GestureDetector(
            onTap: () => onChanged(!value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              height: 30,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: value ? LaarishColors.leaf : LaarishColors.paperDeep,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: LaarishColors.soil.withValues(alpha: 0.2)),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
