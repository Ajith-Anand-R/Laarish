import '../data/local/entities.dart';

/// Pure gating rules — ARCHITECTURE.md §3.2, CANON.md §1 journey order
/// (tommy -> okki -> chilly -> methi, fixed).
class UnlockPolicy {
  UnlockPolicy._();

  static const plantOrder = ['tommy', 'okki', 'chilly', 'methi'];

  /// ARCHITECTURE.md §3.2: `plantUnlocked(tommy) = professionStarted`.
  /// [professionStarted] should come from `GameSave.kitActivated` — QR scan
  /// or the "I Am an Agriculturist" pick (PLAN.md flow).
  static bool plantUnlocked(
    String plantId,
    Map<String, PlantProgress> plants, {
    required bool professionStarted,
  }) {
    final index = plantOrder.indexOf(plantId);
    if (index <= 0) return professionStarted;
    final prev = plants[plantOrder[index - 1]];
    return (prev?.levelsDone ?? 0) >= 5;
  }

  static bool levelUnlocked(
    String plantId,
    int level,
    Map<String, PlantProgress> plants, {
    required bool professionStarted,
  }) {
    if (level <= 1) return plantUnlocked(plantId, plants, professionStarted: professionStarted);
    return (plants[plantId]?.levelsDone ?? 0) >= level - 1;
  }

  static bool professionComplete(Map<String, PlantProgress> plants) =>
      plantOrder.every((id) => (plants[id]?.levelsDone ?? 0) >= 5);

  /// The level to open after finishing ([plantId], [level]): the next level of
  /// the same plant, or level 1 of the next plant after level 5. Null once the
  /// last plant's level 5 is done (whole journey complete).
  static (String plantId, int level)? nextLevel(String plantId, int level) {
    if (level < 5) return (plantId, level + 1);
    final i = plantOrder.indexOf(plantId);
    if (i < 0 || i + 1 >= plantOrder.length) return null;
    return (plantOrder[i + 1], 1);
  }
}
