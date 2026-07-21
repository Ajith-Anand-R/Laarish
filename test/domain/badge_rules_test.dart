import 'package:flutter_test/flutter_test.dart';
import 'package:laarish/domain/badge_rules.dart';

void main() {
  test('canon first-sprout/first-harvest badges use exact CANON.md §6 ids', () {
    expect(badgeForEvent(BadgeEvent.sprouted, plantId: 'tommy'), 'tommy_firstSprout');
    expect(badgeForEvent(BadgeEvent.sprouted, plantId: 'okki'), 'okki_firstSprout');
    expect(badgeForEvent(BadgeEvent.sprouted, plantId: 'chilly'), 'chilly_firstSprout');
    expect(badgeForEvent(BadgeEvent.harvested, plantId: 'tommy'), 'tommy_firstHarvest');
    expect(badgeForEvent(BadgeEvent.harvested, plantId: 'okki'), 'okki_firstHarvest');
    expect(badgeForEvent(BadgeEvent.harvested, plantId: 'chilly'), 'chilly_firstHarvest');
  });

  test('methi has no first-sprout badge but has round 1/2 harvest', () {
    expect(badgeForEvent(BadgeEvent.sprouted, plantId: 'methi'), isNull);
    expect(badgeForEvent(BadgeEvent.harvested, plantId: 'methi'), 'methi_round1Harvest');
    expect(badgeForEvent(BadgeEvent.methiRound2Harvested), 'methi_round2Harvest');
  });

  test('app-only extras map to GAMIFICATION.md §2 ids', () {
    expect(badgeForEvent(BadgeEvent.seedPlanted), 'firstSeed');
    expect(badgeForEvent(BadgeEvent.thinned), 'thinningBrave');
    expect(badgeForEvent(BadgeEvent.graduated), 'graduationDay');
    expect(badgeForEvent(BadgeEvent.patienceCheckIn), 'patienceMaster');
    expect(badgeForEvent(BadgeEvent.curiosityComplete), 'curiousMind');
    expect(badgeForEvent(BadgeEvent.professionComplete), 'proudAgriculturist');
  });

  test('streak milestone only fires on 3/7/14/30', () {
    expect(badgeForEvent(BadgeEvent.streakMilestone, streakDays: 7), 'streak7');
    expect(badgeForEvent(BadgeEvent.streakMilestone, streakDays: 5), isNull);
    expect(badgeForEvent(BadgeEvent.streakMilestone), isNull);
  });

  test('isCanonBadge flags only the guidebook sticker twins', () {
    expect(isCanonBadge('tommy_firstSprout'), isTrue);
    expect(isCanonBadge('methi_round2Harvest'), isTrue);
    expect(isCanonBadge('firstSeed'), isFalse);
    expect(isCanonBadge('proudAgriculturist'), isFalse);
  });

  test('badge catalog has a title for every id it lists', () {
    for (final id in BadgeCatalog.allIds) {
      expect(BadgeCatalog.titles.containsKey(id), isTrue, reason: 'missing title for $id');
    }
  });
}
