import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:laarish/data/local/entities.dart';
import 'package:laarish/data/local/json_file_progress_repository.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('laarish_progress_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('load() with no existing file returns GameSave.empty()', () async {
    final repo = JsonFileProgressRepository(directoryOverride: tempDir);
    final save = await repo.load();
    expect(save.profile.name, '');
    expect(save.plants.keys.toSet(), {'tommy', 'okki', 'chilly', 'methi'});
    expect(save.kitActivated, false);
  });

  test('save() then load() (fresh repo instance) round-trips correctly', () async {
    final writer = JsonFileProgressRepository(directoryOverride: tempDir);
    final save = GameSave.empty();
    save.profile.name = 'Ayaan';
    save.wallet.sunPoints = 120;
    save.plants['tommy']!.levelsDone = 3;
    save.kitActivated = true;
    await writer.save(save);

    final reader = JsonFileProgressRepository(directoryOverride: tempDir);
    final loaded = await reader.load();

    expect(loaded.profile.name, 'Ayaan');
    expect(loaded.wallet.sunPoints, 120);
    expect(loaded.plants['tommy']!.levelsDone, 3);
    expect(loaded.kitActivated, true);
  });

  test('load() with a corrupt file falls back to GameSave.empty() instead of crashing', () async {
    final f = File('${tempDir.path}/laarish_save.json');
    await f.writeAsString('{ not valid json ][');

    final repo = JsonFileProgressRepository(directoryOverride: tempDir);
    final save = await repo.load();

    expect(save.profile.name, '');
    expect(save.plants.keys.toSet(), {'tommy', 'okki', 'chilly', 'methi'});
  });

  test('successful save() clears hasPendingWrite', () async {
    final repo = JsonFileProgressRepository(directoryOverride: tempDir);
    expect(repo.hasPendingWrite, false);
    await repo.save(GameSave.empty());
    expect(repo.hasPendingWrite, false);
  });

  test('save() to an unwritable directory sets hasPendingWrite, keeps value in memory', () async {
    // A file path standing in for a directory is not writable-to as a dir.
    final blocker = File('${tempDir.path}/blocked');
    blocker.writeAsStringSync('x');
    final unwritable = Directory('${blocker.path}/laarish_save.json'); // dir-under-file: invalid

    final repo = JsonFileProgressRepository(directoryOverride: unwritable);
    final save = GameSave.empty();
    save.profile.name = 'Still In Memory';
    await repo.save(save);

    expect(repo.hasPendingWrite, true);
    // In-memory cache still has the latest value even though disk write failed.
    expect((await repo.load()).profile.name, 'Still In Memory');
  });

  test('GameSave JSON (de)serialization is stable for hand-authored data', () {
    final save = GameSave.empty();
    save.profile.name = 'Test';
    final decoded = GameSave.fromJson(jsonDecode(jsonEncode(save.toJson())) as Map<String, dynamic>);
    expect(decoded.profile.name, 'Test');
    expect(decoded.plants.length, 4);
  });
}
