import '../../data/local/entities.dart';
import '../../domain/reward_table.dart';

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
  return save;
}
