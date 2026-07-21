/// Gardener Rank ladder — GAMIFICATION.md §1: "Sprout -> Helper -> Grower ->
/// Green Thumb -> Plant Hero -> Proud Agriculturist", driven by cumulative
/// `wallet.sunPoints`. Pure function, no UI/I-O.
///
/// Thresholds are ours to choose (GAMIFICATION.md doesn't specify numbers).
/// Chosen against the reward table (GAMIFICATION.md §7): a level is
/// ~50-115 Sun Points, a plant is 5 levels + a 250 completion bonus (~600-900
/// SP), profession complete is +1000 SP. Ladder is spaced so ranks land
/// roughly one per plant, with the top rank landing near/after profession
/// completion — not a grind, but not instant either.
library;

enum GardenerRank {
  sprout(0, 'Sprout'),
  helper(200, 'Helper'),
  grower(600, 'Grower'),
  greenThumb(1200, 'Green Thumb'),
  plantHero(2200, 'Plant Hero'),
  proudAgriculturist(4000, 'Proud Agriculturist');

  const GardenerRank(this.threshold, this.title);

  /// Minimum cumulative Sun Points to hold this rank.
  final int threshold;
  final String title;
}

/// Highest rank whose threshold [sunPoints] meets or exceeds.
GardenerRank gardenerRankFor(int sunPoints) {
  var current = GardenerRank.sprout;
  for (final rank in GardenerRank.values) {
    if (sunPoints >= rank.threshold) current = rank;
  }
  return current;
}
