import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../data/repositories.dart';
import 'models/level_content.dart';

class AssetContentRepository implements ContentRepository {
  @override
  Future<LevelContent> loadLevel(String plantId, int level) async {
    final raw = await rootBundle.loadString('assets/content/${plantId}_l$level.json');
    return LevelContent.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> loadJson(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    return jsonDecode(raw) as Map<String, dynamic>;
  }
}
