/// Pure event -> badge id mapping. CANON.md §6 (canon badges, physical
/// sticker twins in the guidebook) + GAMIFICATION.md §2 (app-only extras).
/// No UI, no I/O — testable in isolation. Additive file (WS5 may add new
/// domain/ files as long as they don't touch the frozen reward_table.dart /
/// unlock_policy.dart).
library;

/// Plants that have a canon FIRST SPROUT / FIRST HARVEST badge pair
/// (CANON.md §6). Methi instead has ROUND 1 / ROUND 2 HARVEST — no sprout
/// badge — handled separately below.
const _firstSproutHarvestPlants = ['tommy', 'okki', 'chilly'];

enum BadgeEvent {
  /// First seed ever planted, any plant.
  seedPlanted,
  /// Tommy/Okki/Chilly sprouting (canon FIRST SPROUT).
  sprouted,
  /// Snipped the weaker sprout instead of pulling it (CANON.md §3 rule 4).
  thinned,
  /// All 4 Graduation Signs present (CANON.md §3 rule 5).
  graduated,
  /// Transplanted into the grow bag.
  transplanted,
  /// First flower on the plant.
  flowered,
  /// Tommy/Okki/Chilly FIRST HARVEST, or Methi ROUND 1 HARVEST.
  harvested,
  /// Methi ROUND 2 HARVEST (second round only, same seed).
  methiRound2Harvested,
  /// Followed all 5 Rules for a full week.
  fiveRulesWeek,
  /// Chilly patience check-in during the days 10-14 slow-sprout wait.
  patienceCheckIn,
  /// Logged 5 plant photos.
  photosLogged,
  /// Answered every curiosity question.
  curiosityComplete,
  /// Daily streak hit a milestone (3/7/14/30).
  streakMilestone,
  /// All 4 plants reached level 5 (UnlockPolicy.professionComplete).
  professionComplete,
}

/// Maps a game event to the badge id it awards, or null if this particular
/// event/plant combination doesn't earn one (e.g. Methi has no "first
/// sprout" badge — CANON.md §6 only lists ROUND 1/2 HARVEST for it).
///
/// [plantId] is required for per-plant events ('tommy'|'okki'|'chilly'|'methi').
/// [streakDays] is required for [BadgeEvent.streakMilestone].
String? badgeForEvent(BadgeEvent event, {String? plantId, int? streakDays}) {
  switch (event) {
    case BadgeEvent.seedPlanted:
      return 'firstSeed';
    case BadgeEvent.sprouted:
      if (plantId == null || !_firstSproutHarvestPlants.contains(plantId)) return null;
      return '${plantId}_firstSprout';
    case BadgeEvent.harvested:
      if (plantId == null) return null;
      if (_firstSproutHarvestPlants.contains(plantId)) return '${plantId}_firstHarvest';
      if (plantId == 'methi') return 'methi_round1Harvest';
      return null;
    case BadgeEvent.methiRound2Harvested:
      return 'methi_round2Harvest';
    case BadgeEvent.thinned:
      return 'thinningBrave';
    case BadgeEvent.graduated:
      return 'graduationDay';
    case BadgeEvent.transplanted:
      return 'bigMove';
    case BadgeEvent.flowered:
      return 'firstFlower';
    case BadgeEvent.fiveRulesWeek:
      return 'fiveRulesKeeper';
    case BadgeEvent.patienceCheckIn:
      return 'patienceMaster';
    case BadgeEvent.photosLogged:
      return 'photoReporter';
    case BadgeEvent.curiosityComplete:
      return 'curiousMind';
    case BadgeEvent.streakMilestone:
      if (streakDays == null || ![3, 7, 14, 30].contains(streakDays)) return null;
      return 'streak$streakDays';
    case BadgeEvent.professionComplete:
      return 'proudAgriculturist';
  }
}

/// Canon badges (CANON.md §6) have a physical sticker twin in the guidebook
/// — these are the ones that trigger the "Stick your real badge in your
/// book too!" prompt (GAMIFICATION.md §2).
bool isCanonBadge(String badgeId) =>
    badgeId.endsWith('_firstSprout') ||
    badgeId.endsWith('_firstHarvest') ||
    badgeId == 'methi_round1Harvest' ||
    badgeId == 'methi_round2Harvest';

/// Badge Book display catalog — every badge id the app can award, in the
/// album order shown on S11, with a child-facing title. Keep in sync with
/// [badgeForEvent]'s possible outputs.
class BadgeCatalog {
  BadgeCatalog._();

  static const List<String> allIds = [
    'tommy_firstSprout', 'tommy_firstHarvest',
    'okki_firstSprout', 'okki_firstHarvest',
    'chilly_firstSprout', 'chilly_firstHarvest',
    'methi_round1Harvest', 'methi_round2Harvest',
    'firstSeed', 'thinningBrave', 'graduationDay', 'bigMove', 'firstFlower',
    'fiveRulesKeeper', 'patienceMaster', 'photoReporter', 'curiousMind',
    'streak3', 'streak7', 'streak14', 'streak30',
    'proudAgriculturist',
  ];

  static const Map<String, String> titles = {
    'tommy_firstSprout': 'Tommy\nFirst Sprout',
    'tommy_firstHarvest': 'Tommy\nFirst Harvest',
    'okki_firstSprout': 'Okki\nFirst Sprout',
    'okki_firstHarvest': 'Okki\nFirst Harvest',
    'chilly_firstSprout': 'Chilly\nFirst Sprout',
    'chilly_firstHarvest': 'Chilly\nFirst Harvest',
    'methi_round1Harvest': 'Methi\nRound 1 Harvest',
    'methi_round2Harvest': 'Methi\nRound 2 Harvest',
    'firstSeed': 'First Seed',
    'thinningBrave': 'Thinning Brave',
    'graduationDay': 'Graduation Day',
    'bigMove': 'Big Move',
    'firstFlower': 'First Flower',
    'fiveRulesKeeper': '5-Rules Keeper',
    'patienceMaster': 'Patience Master',
    'photoReporter': 'Photo Reporter',
    'curiousMind': 'Curious Mind',
    'streak3': '3-Day Streak',
    'streak7': '7-Day Streak',
    'streak14': '14-Day Streak',
    'streak30': '30-Day Streak',
    'proudAgriculturist': 'Proud\nAgriculturist',
  };
}
