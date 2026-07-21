/// Streak-on-completion math — pure, testable. GAMIFICATION.md §6: streak
/// resets are gentle (never guilt/shame) and only fire once per day.
library;

import '../data/local/entities.dart';

class StreakUpdate {
  const StreakUpdate({required this.streak, required this.isWelcomeBack, required this.alreadyDoneToday});
  final Streak streak;
  /// True when the gap since the last completed day was more than 1 day —
  /// caller should show warm "welcome back" copy, never a guilt message.
  final bool isWelcomeBack;
  /// True when today was already marked complete — caller should no-op
  /// (no double reward).
  final bool alreadyDoneToday;
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Call once, when every generated daily mission for every active plant is
/// checked off. Returns the next [Streak] plus flags for the caller to
/// decide reward/copy — never mutates [current].
StreakUpdate updateStreakOnAllMissionsDone(Streak current, DateTime today) {
  final todayDate = _dateOnly(today);
  final last = current.lastCompletedDay == null ? null : _dateOnly(current.lastCompletedDay!);

  if (last == todayDate) {
    return StreakUpdate(streak: current, isWelcomeBack: false, alreadyDoneToday: true);
  }

  final gapDays = last == null ? null : todayDate.difference(last).inDays;
  final nextCurrent = (gapDays == 1) ? current.current + 1 : 1;
  final isWelcomeBack = gapDays != null && gapDays > 1;

  return StreakUpdate(
    streak: Streak(
      current: nextCurrent,
      best: nextCurrent > current.best ? nextCurrent : current.best,
      lastCompletedDay: todayDate,
    ),
    isWelcomeBack: isWelcomeBack,
    alreadyDoneToday: false,
  );
}
