import 'package:flutter_test/flutter_test.dart';
import 'package:laarish/domain/reward_table.dart';

void main() {
  test('reward bundles add up (level complete + 3 star)', () {
    final total = RewardTable.levelComplete + RewardTable.levelThreeStar;
    expect(total.sunPoints, 80);
    expect(total.seedCoins, 20);
  });
}
