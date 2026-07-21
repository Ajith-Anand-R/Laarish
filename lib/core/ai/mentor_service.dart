import 'dart:math';

/// The garden AI Mentor — gives a child warm, specific feedback on their
/// real-world progress (a photo they took, a level they finished) and daily
/// tips in a mascot voice.
///
/// This is the seam for a real vision/LLM model later: [feedbackForProgress]
/// is `async` and takes the photo path, so a cloud call can drop in behind
/// the same interface without touching any caller. Today it runs fully
/// on-device from canon (CANON.md numbers/voice) — deterministic, offline,
/// safe for kids, zero external dependency.
abstract class MentorService {
  Future<MentorFeedback> feedbackForProgress({
    required String plantId,
    required int level,
    required bool hasPhoto,
  });

  /// A short mascot-voiced tip for the daily-care home / mentor button.
  String dailyTip(String? plantId);
}

class MentorFeedback {
  const MentorFeedback({required this.headline, required this.body, required this.tip});

  /// One cheerful line (e.g. "Tommy looks strong! 💪").
  final String headline;

  /// Two-ish sentences of specific, encouraging feedback.
  final String body;

  /// One actionable next step in canon voice.
  final String tip;
}

/// On-device mentor. Feedback is drawn from per-plant canon pools, varied by
/// level so a child rarely sees a repeat, and warmed up when they actually
/// attached a progress photo.
class LocalMentorService implements MentorService {
  LocalMentorService([Random? random]) : _rng = random ?? Random();
  final Random _rng;

  @override
  Future<MentorFeedback> feedbackForProgress({
    required String plantId,
    required int level,
    required bool hasPhoto,
  }) async {
    // Simulate a moment of "thinking" so the mentor feels alive.
    await Future<void>.delayed(const Duration(milliseconds: 700));

    final name = _names[plantId] ?? 'your plant';
    final headlines = _headlines[plantId] ?? _headlines['tommy']!;
    final headline = headlines[level.clamp(1, headlines.length) - 1];

    final body = hasPhoto
        ? "Great photo of $name! ${_photoPraise[_rng.nextInt(_photoPraise.length)]}"
        : "Nice work finishing this level with $name! ${_noPhotoPraise[_rng.nextInt(_noPhotoPraise.length)]}";

    final tips = _tips[plantId] ?? _tips['tommy']!;
    final tip = tips[level.clamp(1, tips.length) - 1];

    return MentorFeedback(headline: headline, body: body, tip: tip);
  }

  @override
  String dailyTip(String? plantId) {
    final tips = _tips[plantId] ?? _tips['tommy']!;
    return tips[_rng.nextInt(tips.length)];
  }

  static const _names = {
    'tommy': 'Tommy',
    'okki': 'Okki',
    'chilly': 'Chilly',
    'methi': 'Methi',
  };

  // One upbeat headline per level (1-5), canon personality per plant.
  static const _headlines = {
    'tommy': [
      'Tommy salutes you! 🍅',
      'Strong roots, strong you! 💪',
      'Misty-master! 💦',
      'Big move, big hero! 🦸',
      'Juicy red harvest! 🍅',
    ],
    'okki': [
      'Okki zoomed in! 🌿',
      'Speedy seeding! ⚡',
      'Fast and steady! 🏃',
      'Grow-bag champion! 🌿',
      'Crunchy okra, your reward! 🥢',
    ],
    'chilly': [
      'Chilly gives a nod. 😎',
      'Cool and careful! 🌶️',
      'Patience power! 🔥',
      'Slow burn, big win! 🌶️',
      'Green or red — you chose! 🌶️',
    ],
    'methi': [
      'Methi is thrilled! 🌱',
      'Scatter star! ✨',
      'First greens, first win! 🌿',
      'Same seed, second round! ✌️',
      'Two harvests, one you! 🏆',
    ],
  };

  static const _tips = {
    'tommy': [
      'Mist Tommy 10-15 sprays from 10 cm.',
      'Poke just 6 mm deep with Diggy.',
      'One cup = one plant. Snip, never pull.',
      'Bury 2/3 of the stem — it is exactly right.',
      'Pick when fully red. Sweet and perfect!',
    ],
    'okki': [
      'Soak Okki seeds 8-12 hrs the night before.',
      'Poke 12 mm deep — Okki likes it deeper.',
      'Keep Okki warm. Okki sulks in cold!',
      'Place the cup at surface level. Water 4 Cuppys.',
      'Snip, never twist. Wash hands after!',
    ],
    'chilly': [
      'Chilly is slow — 10-14 days. Totally normal!',
      'Poke 6 mm deep. Handle tiny seeds gently.',
      'Just check and cheer. Waiting IS the job!',
      'Surface level, no deep burial. Water 3 Cuppys.',
      'Green or red, you choose. Snip, never twist!',
    ],
    'methi': [
      'Methi gives you TWO harvests!',
      'Scatter seeds, cover with 5 mm soil.',
      'Smell your hands — that is real fenugreek!',
      'Same seed again! Water 2 Cuppys.',
      'Two rounds, two harvests, better gardener!',
    ],
  };

  static const _photoPraise = [
    'I can see you are taking real care of it every day.',
    'Your little gardener hands are doing amazing work.',
    'Keep watching it a little every day — that is the secret.',
    'A real agriculturist keeps a photo diary, just like this!',
  ];

  static const _noPhotoPraise = [
    'Next time, snap a photo so we can watch it grow together!',
    'You are becoming a real agriculturist, one level at a time.',
    'Every day of care makes your plant a little happier.',
    'The real plant is the best game of all — keep going!',
  ];
}
