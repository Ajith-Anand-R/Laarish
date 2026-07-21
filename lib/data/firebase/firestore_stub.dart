import '../local/entities.dart';
import '../repositories.dart';

/// v2 seam only (ARCHITECTURE.md §3.5) — do NOT implement sync logic here
/// (explicit YAGNI). Exists so the interface swap is visible and compiles;
/// wiring it into providers.dart is a Foundation/WS6-later decision.
class FirestoreProgressRepository implements ProgressRepository {
  @override
  Future<GameSave> load() =>
      throw UnimplementedError('Firestore sync not yet implemented — see ARCHITECTURE.md §3.5');

  @override
  Future<void> save(GameSave save) =>
      throw UnimplementedError('Firestore sync not yet implemented — see ARCHITECTURE.md §3.5');
}
