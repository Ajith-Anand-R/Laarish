/// Pure reward math — GAMIFICATION.md §7. No UI, no I/O: testable in isolation.
class RewardBundle {
  const RewardBundle({required this.sunPoints, required this.seedCoins});
  final int sunPoints;
  final int seedCoins;

  RewardBundle operator +(RewardBundle other) => RewardBundle(
        sunPoints: sunPoints + other.sunPoints,
        seedCoins: seedCoins + other.seedCoins,
      );

  static const zero = RewardBundle(sunPoints: 0, seedCoins: 0);
}

class RewardTable {
  RewardTable._();

  static const lessonStep = RewardBundle(sunPoints: 10, seedCoins: 0);
  static const interactionStep = RewardBundle(sunPoints: 15, seedCoins: 0);
  static const realTaskConfirmed = RewardBundle(sunPoints: 30, seedCoins: 5);
  static const quizCorrectFirstTry = RewardBundle(sunPoints: 20, seedCoins: 2);
  static const levelComplete = RewardBundle(sunPoints: 50, seedCoins: 10);
  static const levelThreeStar = RewardBundle(sunPoints: 30, seedCoins: 10);
  static const dailyMissionsAllDone = RewardBundle(sunPoints: 25, seedCoins: 5);
  static const badgeEarned = RewardBundle(sunPoints: 100, seedCoins: 20);
  static const plantComplete = RewardBundle(sunPoints: 250, seedCoins: 50);
  static const professionComplete = RewardBundle(sunPoints: 1000, seedCoins: 200);
}
