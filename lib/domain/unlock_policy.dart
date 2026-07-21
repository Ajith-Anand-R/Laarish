import '../data/local/entities.dart';

/// Pure gating rules — ARCHITECTURE.md §3.2, CANON.md §1 journey order
/// (tommy -> okki -> chilly -> methi, fixed).
class UnlockPolicy {
  UnlockPolicy._();

  static const plantOrder = ['tommy', 'okki', 'chilly', 'methi'];

  /// Every plant is always open — the child can pick any vegetable, in any
  /// order, and re-enter one they've already finished. Only the LEVELS inside a
  /// plant are sequential (see [levelUnlocked]). [professionStarted] is kept for
  /// call-site compatibility but no longer gates plant access.
  static bool plantUnlocked(
    String plantId,
    Map<String, PlantProgress> plants, {
    bool professionStarted = true,
  }) {
    return true;
  }

  /// Level 1 of every plant is always open. Level N>1 opens once level N-1 is
  /// done — and a finished level stays open for replay (levelsDone >= N-1 holds
  /// for every level up to and including the last one completed).
  static bool levelUnlocked(
    String plantId,
    int level,
    Map<String, PlantProgress> plants, {
    bool professionStarted = true,
  }) {
    if (level <= 1) return true;
    return (plants[plantId]?.levelsDone ?? 0) >= level - 1;
  }

  static bool professionComplete(Map<String, PlantProgress> plants) =>
      plantOrder.every((id) => (plants[id]?.levelsDone ?? 0) >= 5);

  /// The next level of the SAME plant, or null once its level 5 is done —
  /// finishing a plant is a milestone (its own reward), and the child returns
  /// to the map to choose the next vegetable rather than auto-rolling on.
  static (String plantId, int level)? nextLevel(String plantId, int level) {
    if (level < 5) return (plantId, level + 1);
    return null;
  }
}
