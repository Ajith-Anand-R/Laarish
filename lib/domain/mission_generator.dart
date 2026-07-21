/// Daily mission generation — pure function, no UI/IO. WS4 Garden Home &
/// Missions (TODOLIST.md), sourced from CANON.md §3 THE 5 RULES + §5
/// per-plant schedules. Missions are generated fresh each day and never
/// persisted (ARCHITECTURE.md §3.1 — there is no `Mission` entity in
/// GameSave), so this function is the single source of truth for "what
/// does this plant need today".
library;

import '../data/local/entities.dart';

enum MissionType { mist, checkSprouts, patience, thinning, water, graduationCheck, harvestCheck }

class Mission {
  const Mission({
    required this.id,
    required this.plantId,
    required this.type,
    required this.title,
    required this.detail,
  });

  /// Stable per plant+type+day — used as the tap-to-confirm checklist key.
  final String id;
  final String plantId;
  final MissionType type;
  /// Short mascot-voice line (child-facing, ARB-able later — WS7 owns copy).
  final String title;
  /// Fuller instruction carrying the exact CANON.md number(s).
  final String detail;
}

/// CANON.md §5 "grow bag water" — Cuppy = ~100 ml (CANON.md §1).
/// Chilly uses the plant-specific glance value (300 ml) per the resolved
/// §7 conflict, not the copied 400 ml template step.
const Map<String, int> _cuppysByPlant = {'tommy': 4, 'okki': 4, 'chilly': 3, 'methi': 2};

/// Rule 4 THINNING applies to the two-seeds-per-cup plants only — Methi
/// scatters seeds on purpose (CANON.md §5, "MANY PLANTS"), so it never
/// thins. Windows are days-since-`plantedAt`, taken from each plant's
/// CANON.md §5 milestone weeks (Tommy states "Week 3-4 Thinning Day"
/// explicitly; Okki/Chilly have no dedicated thinning week in the
/// guidebook, so we use their nearest stated milestone band, "Weeks 2-3",
/// which sits right after their sprout window).
const Map<String, (int, int)> _thinningWindowDays = {
  'tommy': (21, 28),
  'okki': (14, 21),
  'chilly': (14, 21),
};

/// CANON.md §5 "sprouts" days-since-`plantedAt`, per plant. Used for the
/// sprout-countdown soil mound (GAMIFICATION.md §4).
const Map<String, (int, int)> sproutWindowDays = {
  'tommy': (5, 7),
  'okki': (5, 7),
  'chilly': (10, 14),
  'methi': (2, 4),
};

/// Public helper — days elapsed since [start] as of [today], date-only
/// (ignores time-of-day). Used by the sprout-countdown UI too.
int? daysSince(DateTime? start, DateTime today) => _daysSince(start, today);

int? _daysSince(DateTime? start, DateTime today) {
  if (start == null) return null;
  final s = DateTime(start.year, start.month, start.day);
  final t = DateTime(today.year, today.month, today.day);
  return t.difference(s).inDays;
}

Mission _mist(String plantId) => Mission(
      id: '${plantId}_mist',
      plantId: plantId,
      type: MissionType.mist,
      title: 'Mist with Misty',
      // CANON.md §3 Rule 2 Phase 1.
      detail: '10-15 sprays from 10 cm above. Never pour directly.',
    );

Mission _checkSprouts(String plantId) => Mission(
      id: '${plantId}_checkSprouts',
      plantId: plantId,
      type: MissionType.checkSprouts,
      title: 'Check for sprouts!',
      detail: 'Peek at the cup — any tiny green yet?',
    );

/// GAMIFICATION.md §4 — the literal patience-mission copy, used verbatim.
Mission _patience(String plantId) => const Mission(
      id: 'chilly_patience',
      plantId: 'chilly',
      type: MissionType.patience,
      title: 'Chilly is sleeping.',
      detail: 'Come back tomorrow — nothing to do IS the job!',
    );

Mission _thinning(String plantId) => Mission(
      id: '${plantId}_thinning',
      plantId: plantId,
      type: MissionType.thinning,
      title: 'Thinning time!',
      // CANON.md §3 Rule 4 — "One cup = One plant."
      detail: 'Two sprouts in one cup? Snip the weaker one at soil level. Never pull!',
    );

Mission _water(String plantId, {String phase = ''}) {
  final cuppys = _cuppysByPlant[plantId] ?? 4;
  return Mission(
    id: '${plantId}_water',
    plantId: plantId,
    type: MissionType.water,
    title: 'Water with Cuppy',
    // CANON.md §3 Rule 2 Phase 2.
    detail: 'Pour $cuppys Cuppys slowly in circles near the edge. Never the centre.$phase',
  );
}

Mission _graduationCheck(String plantId) => Mission(
      id: '${plantId}_graduationCheck',
      plantId: plantId,
      type: MissionType.graduationCheck,
      title: 'Check the 4 signs!',
      // CANON.md §3 Rule 5.
      detail: 'True leaves, strong stem, white roots, 80-100 mm — all 4 before the big move.',
    );

Mission _harvestCheck(String plantId) {
  const lines = {
    'tommy': 'Pick when fully red. Sweet, juicy, perfect!',
    'okki': 'Snip never twist. Wash hands after!',
    'chilly': 'Green or red, you choose! Snip never twist.',
    'methi': 'Smell your hands — that\'s real fenugreek!',
  };
  return Mission(
    id: '${plantId}_harvestCheck',
    plantId: plantId,
    type: MissionType.harvestCheck,
    title: 'Check for a harvest!',
    detail: lines[plantId] ?? 'Harvest often!',
  );
}

/// Generates 1-4 daily missions for [plant] as of [today]. Empty for
/// `PlantStage.locked` (not started yet).
List<Mission> generateDailyMissions(PlantProgress plant, DateTime today) {
  final id = plant.plantId;
  final daysPlanted = _daysSince(plant.realDates.plantedAt, today);

  switch (plant.stage) {
    case PlantStage.locked:
      return [];

    case PlantStage.nursery:
      if (plant.realDates.sproutedAt == null) {
        // Chilly's slow-sprout window is THE lesson (GAMIFICATION.md §4) —
        // on those days the patience mission stands alone, replacing
        // mist/check, because "nothing to do IS the job".
        if (id == 'chilly' && daysPlanted != null && daysPlanted >= 10 && daysPlanted <= 14) {
          return [_patience(id)];
        }
        return [_mist(id), _checkSprouts(id)];
      }
      final missions = [_mist(id)];
      final window = _thinningWindowDays[id];
      if (window != null && daysPlanted != null && daysPlanted >= window.$1 && daysPlanted <= window.$2) {
        missions.add(_thinning(id));
      }
      return missions;

    case PlantStage.thinned:
      return [_mist(id)];

    case PlantStage.graduated:
      return [_mist(id), _graduationCheck(id)];

    case PlantStage.growBag:
      return [_water(id)];

    case PlantStage.flowering:
      return [_water(id, phase: ' Watch for flowers and fruit!')];

    case PlantStage.harvested:
      return [_water(id), _harvestCheck(id)];

    case PlantStage.round2:
      // Methi Round 2 grow bag — same Rule 2 Phase 2, 200 ml (2 Cuppys).
      return [_water(id, phase: ' Same seed, second harvest!')];
  }
}
