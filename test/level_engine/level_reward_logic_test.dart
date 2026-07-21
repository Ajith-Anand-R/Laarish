import 'package:flutter_test/flutter_test.dart';
import 'package:laarish/domain/unlock_policy.dart';
import 'package:laarish/data/local/entities.dart';
import 'package:laarish/domain/reward_table.dart';
import 'package:laarish/features/level_engine/level_reward_logic.dart';

void main() {
  test('bumps levelsDone only when this level is higher, always credits wallet', () {
    final save = GameSave.empty();
    save.plants['tommy']!.levelsDone = 2;

    final afterLower = applyLevelReward(
      save,
      plantId: 'tommy',
      level: 1, // already done — must not regress
      bundle: const RewardBundle(sunPoints: 10, seedCoins: 1),
    );
    expect(afterLower.plants['tommy']!.levelsDone, 2);
    expect(afterLower.wallet.sunPoints, 10);
    expect(afterLower.wallet.seedCoins, 1);

    final afterHigher = applyLevelReward(
      afterLower,
      plantId: 'tommy',
      level: 3,
      bundle: const RewardBundle(sunPoints: 50, seedCoins: 10),
    );
    expect(afterHigher.plants['tommy']!.levelsDone, 3);
    expect(afterHigher.wallet.sunPoints, 60);
    expect(afterHigher.wallet.seedCoins, 11);
  });

  test('creates the plant entry if this is its first recorded progress', () {
    final save = GameSave.empty();
    save.plants.remove('okki');

    final after = applyLevelReward(save, plantId: 'okki', level: 1, bundle: RewardTable.levelComplete);
    expect(after.plants['okki']!.levelsDone, 1);
  });

  test('awards Proud Agriculturist once when the last level finishes the journey', () {
    final save = GameSave.empty();
    for (final id in UnlockPolicy.plantOrder) {
      save.plants[id]!.levelsDone = 5;
    }
    save.plants['methi']!.levelsDone = 4; // one level short

    expect(save.badges.any((b) => b.id == 'proudAgriculturist'), isFalse);

    var after = applyLevelReward(save, plantId: 'methi', level: 5, bundle: RewardTable.levelComplete);
    expect(after.badges.where((b) => b.id == 'proudAgriculturist').length, 1);

    // Idempotent — replaying doesn't duplicate the badge.
    after = applyLevelReward(after, plantId: 'methi', level: 5, bundle: RewardTable.levelComplete);
    expect(after.badges.where((b) => b.id == 'proudAgriculturist').length, 1);
  });
}
