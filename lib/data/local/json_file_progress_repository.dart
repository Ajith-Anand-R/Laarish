import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../repositories.dart';
import 'entities.dart';

/// Local-first persistence: one JSON file in app documents dir.
/// ARCHITECTURE.md §3.1 note + §3.7 (retry-once, then keep last-good in
/// memory so a level result is never silently lost).
class JsonFileProgressRepository implements ProgressRepository {
  /// Test seam only — production always resolves via path_provider.
  /// Lets test/data/ point at a temp dir without a plugin mock setup.
  JsonFileProgressRepository({@visibleForTesting this.directoryOverride});

  final Directory? directoryOverride;
  GameSave? _cache;
  bool _hasPendingWrite = false;

  /// True when the last save() failed to reach disk (even after retry); the
  /// value is still safe in [_cache] and the next successful save() call
  /// flushes it. Banner-worthy per ARCHITECTURE.md §3.7.
  bool get hasPendingWrite => _hasPendingWrite;

  Future<File> _file() async {
    final dir = directoryOverride ?? await getApplicationDocumentsDirectory();
    return File('${dir.path}/laarish_save.json');
  }

  @override
  Future<GameSave> load() async {
    if (_cache != null) return _cache!;
    try {
      final f = await _file();
      if (!await f.exists()) {
        _cache = GameSave.empty();
        return _cache!;
      }
      final raw = await f.readAsString();
      _cache = GameSave.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      return _cache!;
    } catch (_) {
      _cache = GameSave.empty();
      return _cache!;
    }
  }

  @override
  Future<void> save(GameSave save) async {
    _cache = save; // keep in-memory copy even if the disk write below fails
    final data = jsonEncode(save.toJson());
    if (await _tryWrite(data) || await _tryWrite(data)) {
      // second _tryWrite is the one retry, ARCHITECTURE.md §3.7
      _hasPendingWrite = false;
      return;
    }
    // Save stays in _cache; next successful save() call drains the backlog
    // (it writes this same up-to-date state, so nothing is lost).
    _hasPendingWrite = true;
  }

  Future<bool> _tryWrite(String data) async {
    try {
      final f = await _file();
      await f.writeAsString(data);
      return true;
    } catch (_) {
      return false;
    }
  }
}
