import 'package:flutter_test/flutter_test.dart';
import 'package:laarish/data/local/entities.dart';
import 'package:laarish/domain/unlock_policy.dart';

void main() {
  test('every plant is always open (any order, even before kit / after done)', () {
    final plants = {
      'tommy': PlantProgress(plantId: 'tommy')..levelsDone = 5, // finished
      'okki': PlantProgress(plantId: 'okki'),
      'chilly': PlantProgress(plantId: 'chilly'),
      'methi': PlantProgress(plantId: 'methi'),
    };
    for (final id in UnlockPolicy.plantOrder) {
      expect(UnlockPolicy.plantUnlocked(id, plants), isTrue);
    }
  });

  test('inside a plant, level N needs level N-1 done; level 1 is always open', () {
    final plants = {
      'tommy': PlantProgress(plantId: 'tommy')..levelsDone = 2,
      'okki': PlantProgress(plantId: 'okki'), // untouched
    };
    expect(UnlockPolicy.levelUnlocked('tommy', 1, plants), isTrue);
    expect(UnlockPolicy.levelUnlocked('tommy', 3, plants), isTrue); // replay/next: 2 done
    expect(UnlockPolicy.levelUnlocked('tommy', 4, plants), isFalse);
    // Okki level 1 open even though tommy isn't done — plants are independent.
    expect(UnlockPolicy.levelUnlocked('okki', 1, plants), isTrue);
    expect(UnlockPolicy.levelUnlocked('okki', 2, plants), isFalse);
  });

  test('nextLevel: within a plant, then null when the plant is finished', () {
    expect(UnlockPolicy.nextLevel('tommy', 1), ('tommy', 2));
    expect(UnlockPolicy.nextLevel('tommy', 4), ('tommy', 5));
    expect(UnlockPolicy.nextLevel('tommy', 5), isNull); // plant done, back to map
    expect(UnlockPolicy.nextLevel('methi', 5), isNull);
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
