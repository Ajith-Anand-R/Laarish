import 'package:flutter_test/flutter_test.dart';
import 'package:laarish/data/local/entities.dart';
import 'package:laarish/domain/unlock_policy.dart';

void main() {
  test('tommy is unlocked from the start; others gated on previous plant', () {
    final plants = {
      'tommy': PlantProgress(plantId: 'tommy'),
      'okki': PlantProgress(plantId: 'okki'),
      'chilly': PlantProgress(plantId: 'chilly'),
      'methi': PlantProgress(plantId: 'methi'),
    };
    expect(UnlockPolicy.plantUnlocked('tommy', plants, professionStarted: true), isTrue);
    expect(UnlockPolicy.plantUnlocked('tommy', plants, professionStarted: false), isFalse);
    expect(UnlockPolicy.plantUnlocked('okki', plants, professionStarted: true), isFalse);

    plants['tommy']!.levelsDone = 5;
    expect(UnlockPolicy.plantUnlocked('okki', plants, professionStarted: true), isTrue);
    expect(UnlockPolicy.plantUnlocked('chilly', plants, professionStarted: true), isFalse);
  });

  test('level N needs level N-1 done; level 1 needs the plant unlocked', () {
    final plants = {
      'tommy': PlantProgress(plantId: 'tommy')..levelsDone = 2,
      'okki': PlantProgress(plantId: 'okki'),
    };
    expect(UnlockPolicy.levelUnlocked('tommy', 1, plants, professionStarted: true), isTrue);
    expect(UnlockPolicy.levelUnlocked('tommy', 3, plants, professionStarted: true), isTrue);
    expect(UnlockPolicy.levelUnlocked('tommy', 4, plants, professionStarted: true), isFalse);
    expect(UnlockPolicy.levelUnlocked('okki', 1, plants, professionStarted: true), isFalse); // tommy not done
    expect(UnlockPolicy.levelUnlocked('tommy', 1, plants, professionStarted: false), isFalse);
  });

  test('nextLevel: within a plant, across plants, and end of journey', () {
    expect(UnlockPolicy.nextLevel('tommy', 1), ('tommy', 2));
    expect(UnlockPolicy.nextLevel('tommy', 4), ('tommy', 5));
    expect(UnlockPolicy.nextLevel('tommy', 5), ('okki', 1)); // roll to next plant
    expect(UnlockPolicy.nextLevel('chilly', 5), ('methi', 1));
    expect(UnlockPolicy.nextLevel('methi', 5), isNull); // journey complete
  });

  test('profession completes only when all four plants hit level 5', () {
    final plants = {
      for (final id in UnlockPolicy.plantOrder) id: PlantProgress(plantId: id)..levelsDone = 5,
    };
    expect(UnlockPolicy.professionComplete(plants), isTrue);
    plants['methi']!.levelsDone = 4;
    expect(UnlockPolicy.professionComplete(plants), isFalse);
  });
}
