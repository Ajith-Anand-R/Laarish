/// LevelContent JSON model — ARCHITECTURE.md §3.3. One JSON file per level,
/// one LevelRunner engine for all 20 levels. Hand-written parsing (no
/// codegen — schema is small and stable; see ARCHITECTURE.md §3.1 note).
class LevelContent {
  LevelContent({
    required this.plantId,
    required this.level,
    required this.title,
    required this.biome,
    required this.steps,
  });

  final String plantId;
  final int level;
  final String title;
  final String biome;
  final List<LevelStep> steps;

  factory LevelContent.fromJson(Map<String, dynamic> j) => LevelContent(
        plantId: j['plantId'] as String,
        level: j['level'] as int,
        title: j['title'] as String,
        biome: j['biome'] as String,
        steps: (j['steps'] as List)
            .map((s) => LevelStep.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}

/// step types: mascotIntro, lesson, interaction, realTask, quiz, reward.
/// Fields beyond `type` are step-specific and kept as a raw map — each step
/// widget reads only the keys it needs (ARCHITECTURE.md §3.3).
class LevelStep {
  LevelStep({required this.type, required this.raw});

  final String type;
  final Map<String, dynamic> raw;

  factory LevelStep.fromJson(Map<String, dynamic> j) =>
      LevelStep(type: j['type'] as String, raw: j);

  String? get rive => raw['rive'] as String?;
  List<String> get lines => (raw['lines'] as List?)?.cast<String>() ?? [];
  String? get prompt => raw['prompt'] as String?;
  String? get game => raw['game'] as String?;
  String? get asset => raw['asset'] as String?;
  Map<String, dynamic>? get target => raw['target'] as Map<String, dynamic>?;
  int? get count => raw['count'] as int?;
  String? get confirm => raw['confirm'] as String?;
  String? get quizQuestion => raw['q'] as String?;
  List<String> get quizOptions => (raw['options'] as List?)?.cast<String>() ?? [];
  int? get quizAnswer => raw['answer'] as int?;
  bool get rewardStars => raw['stars'] as bool? ?? false;
  int get sunPoints => raw['sunPoints'] as int? ?? 0;
  int get seedCoins => raw['seedCoins'] as int? ?? 0;
}
