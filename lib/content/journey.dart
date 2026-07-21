/// The fixed 4-plant journey (CANON.md §1 order) and the 5 levels each plant
/// shares. Plain const data — no I/O, no codegen — so screens and the quiz
/// checkpoint read the same source of truth.
library;

/// The five level titles, in order, identical for every plant
/// (per the journey spec: Kit Introduction → Harvesting).
const levelTitles = <String>[
  'Kit Introduction',
  'Seeding',
  'Watering & Care',
  'Plant Growth',
  'Harvesting',
];

/// Child-facing name/subtitle/emoji per canon plantId.
const plantMeta = <String, ({String name, String subtitle, String emoji})>{
  'tommy': (name: 'Tommy', subtitle: 'Tomato', emoji: '🍅'),
  'okki': (name: 'Okki', subtitle: 'Cucumber', emoji: '🥒'),
  'chilly': (name: 'Chilly', subtitle: 'Chilli', emoji: '🌶️'),
  'methi': (name: 'Methi', subtitle: 'Fenugreek', emoji: '🌿'),
};

/// One check-for-understanding question per level (indexed by level-1), asked
/// at the checkpoint after the child uploads their plant photo.
class QuizQuestion {
  const QuizQuestion(this.prompt, this.options, this.answer);
  final String prompt;
  final List<String> options;
  final int answer; // index into [options]
}

const levelQuiz = <QuizQuestion>[
  QuizQuestion(
    'What do you use from your Laarish kit to begin?',
    ['Seeds and soil', 'A television', 'Some candy'],
    0,
  ),
  QuizQuestion(
    'How deep do tiny seeds usually go?',
    ['Very very deep', 'Just under the soil', 'On top, uncovered'],
    1,
  ),
  QuizQuestion(
    'When does a young plant want water?',
    ['Never', 'When the soil feels dry', 'Only once a year'],
    1,
  ),
  QuizQuestion(
    'What helps a plant grow big and strong?',
    ['Sunlight and water', 'Total darkness', 'Loud music'],
    0,
  ),
  QuizQuestion(
    'When is it time to harvest?',
    ['When the crop is ripe', 'On the very first day', 'Never'],
    0,
  ),
];
