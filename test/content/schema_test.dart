import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:laarish/content/models/level_content.dart';

/// Guards WS7: every JSON dropped into assets/content/ must parse as
/// LevelContent. Passes vacuously until content exists (TODOLIST.md WS7).
void main() {
  // Level files are named `<plant>_l<n>.json`. Other content data files in
  // the same dir (questions.json, etc.) are not LevelContent and are skipped.
  final levelFile = RegExp(r'_l\d+\.json$');

  test('every assets/content/<plant>_l<n>.json parses as LevelContent', () {
    final dir = Directory('assets/content');
    final files = dir.existsSync()
        ? dir.listSync().whereType<File>().where((f) => levelFile.hasMatch(f.path))
        : <File>[];

    for (final file in files) {
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(
        () => LevelContent.fromJson(json),
        returnsNormally,
        reason: 'Failed to parse ${file.path}',
      );
    }
  });
}
