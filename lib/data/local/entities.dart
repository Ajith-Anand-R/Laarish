/// Domain entities. Plain Dart, hand-written JSON (de)serialization —
/// see ARCHITECTURE.md §3.1 for why (no embedded DB / codegen needed at
/// this data size). All stored together as one [GameSave] blob.
library;

class Profile {
  Profile({this.id, required this.name, required this.buddy, this.avatarSeed = 0, DateTime? createdAt})
      : createdAt = createdAt ?? DateTime.now();

  /// AuthRepository.currentUserId once signed in; null for the local-only
  /// pre-Firestore save (ARCHITECTURE.md §3.5 `users/{uid}/...`).
  String? id;
  String name;
  /// 'rishi' | 'ayra' — CANON.md §1.
  String buddy;
  int avatarSeed;
  DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'buddy': buddy,
        'avatarSeed': avatarSeed,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        id: j['id'] as String?,
        name: j['name'] as String? ?? '',
        buddy: j['buddy'] as String? ?? 'rishi',
        avatarSeed: j['avatarSeed'] as int? ?? 0,
        createdAt: j['createdAt'] == null ? null : DateTime.parse(j['createdAt'] as String),
      );
}

class Wallet {
  Wallet({this.sunPoints = 0, this.seedCoins = 0});

  int sunPoints;
  int seedCoins;

  Map<String, dynamic> toJson() => {'sunPoints': sunPoints, 'seedCoins': seedCoins};

  factory Wallet.fromJson(Map<String, dynamic> j) => Wallet(
        sunPoints: j['sunPoints'] as int? ?? 0,
        seedCoins: j['seedCoins'] as int? ?? 0,
      );
}

/// Growth stage — canon phases per plant (CANON.md §5). Methi skips
/// growBag/flowering and instead cycles round1 -> round2.
enum PlantStage {
  locked,
  nursery,
  thinned,
  graduated,
  growBag,
  flowering,
  harvested,
  round2,
}

class RealDates {
  RealDates({this.plantedAt, this.sproutedAt, this.transplantedAt, this.harvestedAt});

  DateTime? plantedAt;
  DateTime? sproutedAt;
  DateTime? transplantedAt;
  DateTime? harvestedAt;

  Map<String, dynamic> toJson() => {
        'plantedAt': plantedAt?.toIso8601String(),
        'sproutedAt': sproutedAt?.toIso8601String(),
        'transplantedAt': transplantedAt?.toIso8601String(),
        'harvestedAt': harvestedAt?.toIso8601String(),
      };

  factory RealDates.fromJson(Map<String, dynamic> j) => RealDates(
        plantedAt: j['plantedAt'] == null ? null : DateTime.parse(j['plantedAt'] as String),
        sproutedAt: j['sproutedAt'] == null ? null : DateTime.parse(j['sproutedAt'] as String),
        transplantedAt:
            j['transplantedAt'] == null ? null : DateTime.parse(j['transplantedAt'] as String),
        harvestedAt: j['harvestedAt'] == null ? null : DateTime.parse(j['harvestedAt'] as String),
      );
}

class PlantProgress {
  PlantProgress({
    required this.plantId,
    this.levelsDone = 0,
    List<int>? stars,
    this.stage = PlantStage.locked,
    RealDates? realDates,
    List<String>? photos,
  })  : stars = stars ?? List.filled(5, 0),
        realDates = realDates ?? RealDates(),
        photos = photos ?? [];

  /// 'tommy' | 'okki' | 'chilly' | 'methi' — CANON.md §1, journey order fixed.
  final String plantId;
  int levelsDone; // 0..5
  List<int> stars; // per level, 0..3, length 5
  PlantStage stage;
  RealDates realDates;
  List<String> photos;

  Map<String, dynamic> toJson() => {
        'plantId': plantId,
        'levelsDone': levelsDone,
        'stars': stars,
        'stage': stage.name,
        'realDates': realDates.toJson(),
        'photos': photos,
      };

  factory PlantProgress.fromJson(Map<String, dynamic> j) => PlantProgress(
        plantId: j['plantId'] as String,
        levelsDone: j['levelsDone'] as int? ?? 0,
        stars: (j['stars'] as List?)?.cast<int>(),
        stage: PlantStage.values.firstWhere(
          (s) => s.name == j['stage'],
          orElse: () => PlantStage.locked,
        ),
        realDates: j['realDates'] == null
            ? null
            : RealDates.fromJson(j['realDates'] as Map<String, dynamic>),
        photos: (j['photos'] as List?)?.cast<String>(),
      );
}

class Badge {
  Badge({required this.id, required this.earnedAt});

  /// Canon badge ids — CANON.md §6, e.g. 'tommy_firstSprout', 'methi_round2Harvest'.
  final String id;
  final DateTime earnedAt;

  Map<String, dynamic> toJson() => {'id': id, 'earnedAt': earnedAt.toIso8601String()};

  factory Badge.fromJson(Map<String, dynamic> j) =>
      Badge(id: j['id'] as String, earnedAt: DateTime.parse(j['earnedAt'] as String));
}

class Streak {
  Streak({this.current = 0, this.best = 0, this.lastCompletedDay});

  int current;
  int best;
  DateTime? lastCompletedDay;

  Map<String, dynamic> toJson() => {
        'current': current,
        'best': best,
        'lastCompletedDay': lastCompletedDay?.toIso8601String(),
      };

  factory Streak.fromJson(Map<String, dynamic> j) => Streak(
        current: j['current'] as int? ?? 0,
        best: j['best'] as int? ?? 0,
        lastCompletedDay: j['lastCompletedDay'] == null
            ? null
            : DateTime.parse(j['lastCompletedDay'] as String),
      );
}

/// User-facing preferences (Settings screen). Kept in the save blob so a
/// child's sound/reminder choice survives relaunch. Defaults are chosen for
/// COPPA-mindedness: reminders OFF until explicitly opted in.
class Settings {
  Settings({this.soundOn = true, this.remindersOn = false});

  bool soundOn;
  bool remindersOn;

  Map<String, dynamic> toJson() => {'soundOn': soundOn, 'remindersOn': remindersOn};

  factory Settings.fromJson(Map<String, dynamic> j) => Settings(
        soundOn: j['soundOn'] as bool? ?? true,
        remindersOn: j['remindersOn'] as bool? ?? false,
      );
}

/// The one save blob persisted by ProgressRepository.
class GameSave {
  GameSave({
    required this.profile,
    required this.wallet,
    required this.plants,
    List<Badge>? badges,
    Streak? streak,
    Settings? settings,
    this.kitActivated = false,
  })  : badges = badges ?? [],
        streak = streak ?? Streak(),
        settings = settings ?? Settings();

  Profile profile;
  Wallet wallet;
  Map<String, PlantProgress> plants; // keyed by plantId
  List<Badge> badges;
  Streak streak;
  Settings settings;
  bool kitActivated;

  static GameSave empty() => GameSave(
        profile: Profile(name: '', buddy: 'rishi'),
        wallet: Wallet(),
        plants: {
          for (final id in const ['tommy', 'okki', 'chilly', 'methi'])
            id: PlantProgress(plantId: id),
        },
      );

  Map<String, dynamic> toJson() => {
        'profile': profile.toJson(),
        'wallet': wallet.toJson(),
        'plants': plants.map((k, v) => MapEntry(k, v.toJson())),
        'badges': badges.map((b) => b.toJson()).toList(),
        'streak': streak.toJson(),
        'settings': settings.toJson(),
        'kitActivated': kitActivated,
      };

  factory GameSave.fromJson(Map<String, dynamic> j) => GameSave(
        profile: Profile.fromJson(j['profile'] as Map<String, dynamic>),
        wallet: Wallet.fromJson(j['wallet'] as Map<String, dynamic>),
        plants: (j['plants'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, PlantProgress.fromJson(v as Map<String, dynamic>)),
        ),
        badges: (j['badges'] as List? ?? [])
            .map((b) => Badge.fromJson(b as Map<String, dynamic>))
            .toList(),
        streak: j['streak'] == null ? null : Streak.fromJson(j['streak'] as Map<String, dynamic>),
        settings: j['settings'] == null ? null : Settings.fromJson(j['settings'] as Map<String, dynamic>),
        kitActivated: j['kitActivated'] as bool? ?? false,
      );
}
