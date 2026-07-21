import 'package:flutter_test/flutter_test.dart';
import 'package:laarish/data/local/entities.dart';
import 'package:laarish/domain/streak_policy.dart';

void main() {
  final today = DateTime(2026, 7, 21);

  test('first ever completion -> current 1, best 1', () {
    final result = updateStreakOnAllMissionsDone(Streak(), today);
    expect(result.streak.current, 1);
    expect(result.streak.best, 1);
    expect(result.isWelcomeBack, isFalse);
    expect(result.alreadyDoneToday, isFalse);
  });

  test('completed yesterday -> streak increments, no welcome-back', () {
    final current = Streak(current: 4, best: 4, lastCompletedDay: today.subtract(const Duration(days: 1)));
    final result = updateStreakOnAllMissionsDone(current, today);
    expect(result.streak.current, 5);
    expect(result.streak.best, 5);
    expect(result.isWelcomeBack, isFalse);
  });

  test('missed 2+ days -> gentle reset to 1, welcome-back flagged, best kept', () {
    final current = Streak(current: 10, best: 10, lastCompletedDay: today.subtract(const Duration(days: 4)));
    final result = updateStreakOnAllMissionsDone(current, today);
    expect(result.streak.current, 1);
    expect(result.streak.best, 10);
    expect(result.isWelcomeBack, isTrue);
  });

  test('already completed today -> no-op, no double reward', () {
    final current = Streak(current: 3, best: 3, lastCompletedDay: today);
    final result = updateStreakOnAllMissionsDone(current, today);
    expect(result.alreadyDoneToday, isTrue);
    expect(result.streak.current, 3);
  });
}
