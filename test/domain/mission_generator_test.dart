import 'package:flutter_test/flutter_test.dart';
import 'package:laarish/data/local/entities.dart';
import 'package:laarish/domain/mission_generator.dart';

void main() {
  final today = DateTime(2026, 7, 21);

  test('nursery, not yet sprouted -> mist + check-for-sprouts', () {
    final tommy = PlantProgress(plantId: 'tommy', stage: PlantStage.nursery)
      ..realDates.plantedAt = today.subtract(const Duration(days: 2));
    final missions = generateDailyMissions(tommy, today);
    expect(missions.map((m) => m.type), containsAll([MissionType.mist, MissionType.checkSprouts]));
  });

  test('Chilly days 10-14 unsprouted -> patience mission stands alone', () {
    final chilly = PlantProgress(plantId: 'chilly', stage: PlantStage.nursery)
      ..realDates.plantedAt = today.subtract(const Duration(days: 12));
    final missions = generateDailyMissions(chilly, today);
    expect(missions, hasLength(1));
    expect(missions.single.type, MissionType.patience);
    expect(missions.single.detail, contains('nothing to do IS the job'));
  });

  test('Chilly before day 10, unsprouted -> normal mist + check, not patience', () {
    final chilly = PlantProgress(plantId: 'chilly', stage: PlantStage.nursery)
      ..realDates.plantedAt = today.subtract(const Duration(days: 3));
    final missions = generateDailyMissions(chilly, today);
    expect(missions.map((m) => m.type), containsAll([MissionType.mist, MissionType.checkSprouts]));
  });

  test('Tommy sprouted, week 3-4 -> thinning mission added', () {
    final tommy = PlantProgress(plantId: 'tommy', stage: PlantStage.nursery)
      ..realDates.plantedAt = today.subtract(const Duration(days: 24))
      ..realDates.sproutedAt = today.subtract(const Duration(days: 18));
    final missions = generateDailyMissions(tommy, today);
    expect(missions.map((m) => m.type), containsAll([MissionType.mist, MissionType.thinning]));
  });

  test('Methi never gets a thinning mission (scatter-sown)', () {
    final methi = PlantProgress(plantId: 'methi', stage: PlantStage.nursery)
      ..realDates.plantedAt = today.subtract(const Duration(days: 24))
      ..realDates.sproutedAt = today.subtract(const Duration(days: 18));
    final missions = generateDailyMissions(methi, today);
    expect(missions.any((m) => m.type == MissionType.thinning), isFalse);
  });

  test('growBag stage -> water mission with plant-specific Cuppy count', () {
    final chilly = PlantProgress(plantId: 'chilly', stage: PlantStage.growBag);
    final missions = generateDailyMissions(chilly, today);
    expect(missions.single.type, MissionType.water);
    expect(missions.single.detail, contains('3 Cuppys'));
  });

  test('locked stage -> no missions', () {
    final okki = PlantProgress(plantId: 'okki', stage: PlantStage.locked);
    expect(generateDailyMissions(okki, today), isEmpty);
  });
}
