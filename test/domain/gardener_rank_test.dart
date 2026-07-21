import 'package:flutter_test/flutter_test.dart';
import 'package:laarish/domain/gardener_rank.dart';

void main() {
  test('rank climbs the ladder as sun points cross thresholds', () {
    expect(gardenerRankFor(0), GardenerRank.sprout);
    expect(gardenerRankFor(199), GardenerRank.sprout);
    expect(gardenerRankFor(200), GardenerRank.helper);
    expect(gardenerRankFor(1199), GardenerRank.grower);
    expect(gardenerRankFor(4000), GardenerRank.proudAgriculturist);
    expect(gardenerRankFor(999999), GardenerRank.proudAgriculturist);
  });
}
