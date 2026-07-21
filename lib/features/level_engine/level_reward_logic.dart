import '../../data/local/entities.dart';
import '../../domain/badge_rules.dart';
import '../../domain/reward_table.dart';
import '../../domain/unlock_policy.dart';

/// Pure mutation used by LevelRunner's `reward` step — extracted from the
/// widget so the "only bump levelsDone if this level is higher" rule is
/// unit-testable without a BuildContext/Riverpod container. Mirrors the
/// pattern already used in LevelScreen._completeLevel (ARCHITECTURE.md §3.4).
GameSave applyLevelReward(
  GameSave save, {
  required String plantId,
  required int level,
  required RewardBundle bundle,
}) {
  final plant = save.plants[plantId] ?? PlantProgress(plantId: plantId);
  if (level > plant.levelsDone) plant.levelsDone = level;
  save.plants[plantId] = plant;
  save.wallet.sunPoints += bundle.sunPoints;
  save.wallet.seedCoins += bundle.seedCoins;

  final now = DateTime.now();

  void award(String? id, RewardBundle bonus) {
    if (id == null || save.badges.any((b) => b.id == id)) return;
    save.badges.add(Badge(id: id, earnedAt: now));
    save.wallet.sunPoints += bonus.sunPoints;
    save.wallet.seedCoins += bonus.seedCoins;
  }

  // Finishing all 5 levels of a plant earns that vegetable's harvest badge +
  // a plant-complete bonus. Guarded on the badge so it's credited only once.
  if (plant.levelsDone >= 5) {
    award(badgeForEvent(BadgeEvent.harvested, plantId: plantId), RewardTable.plantComplete);
  }

  // All four plants done → the whole journey is complete: Proud Agriculturist.
  if (UnlockPolicy.professionComplete(save.plants)) {
    award(badgeForEvent(BadgeEvent.professionComplete), RewardTable.professionComplete);
  }
  return save;
}
