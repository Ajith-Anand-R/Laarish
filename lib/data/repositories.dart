import '../content/models/level_content.dart';
import 'local/entities.dart';

/// Contract freeze — ARCHITECTURE.md §5 / PARALLEL_AGENTS.md §3.
/// Features depend on these interfaces only, never on a concrete impl.
abstract class ProgressRepository {
  Future<GameSave> load();
  Future<void> save(GameSave save);
}

abstract class AuthRepository {
  Stream<bool> authStateChanges();
  /// Stable id for the signed-in user, or null if signed out. ARCHITECTURE.md
  /// §3.5 stores synced data under `users/{uid}/...` — WS6 needs this now,
  /// before the interface freeze, rather than requesting a contract change later.
  String? get currentUserId;
  Future<void> signInWithEmail(String email, String password);
  Future<void> signInWithGoogle();
  Future<void> signOut();
}

abstract class ContentRepository {
  Future<LevelContent> loadLevel(String plantId, int level);
  /// Generic loader for other content JSON (missions.json, questions.json —
  /// AGENT.md §7 "content-driven", owned by WS4/WS1/WS7). One method covers
  /// all of it instead of freezing a method per content type.
  Future<Map<String, dynamic>> loadJson(String assetPath);
}
