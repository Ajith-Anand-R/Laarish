import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../core/ai/mentor_service.dart';
import '../core/audio/audio_service.dart';
import '../content/content_repository.dart';
import '../data/firebase/firebase_auth_repository.dart';
import '../data/firebase/stub_auth_repository.dart';
import '../data/local/entities.dart';
import '../data/local/json_file_progress_repository.dart';
import '../data/repositories.dart';

/// Contract-freeze providers (PARALLEL_AGENTS.md §3). Overridden in main.dart
/// once we know whether Firebase actually initialized.
final firebaseReadyProvider = Provider<bool>((ref) => false);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return ref.watch(firebaseReadyProvider) ? FirebaseAuthRepository() : StubAuthRepository();
});

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  return JsonFileProgressRepository();
});

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  return AssetContentRepository();
});

/// AI garden mentor — on-device today, swappable for a cloud model later
/// (see MentorService). Gives photo/level feedback and daily tips.
final mentorServiceProvider = Provider<MentorService>((ref) => LocalMentorService());

/// Grabs a plant photo from the camera for the level checkpoint. Returns the
/// file path, or null if the child backs out. Behind a provider so tests can
/// override it (image_picker needs a real platform camera).
final photoPickerProvider = Provider<Future<String?> Function()>((ref) {
  return () async {
    final shot = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
      maxWidth: 1280,
    );
    return shot?.path;
  };
});

final authStateProvider = StreamProvider<bool>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

/// Single source of truth for save data. Any feature mutates progress through
/// this notifier -> ProgressRepository.save, never touching storage directly.
class GameSaveController extends AsyncNotifier<GameSave> {
  @override
  Future<GameSave> build() async {
    final save = await ref.read(progressRepositoryProvider).load();
    // Apply the persisted sound preference so a child who muted last session
    // stays muted from the first tap (SFX are gated on AudioService.muted).
    AudioService.instance.setMuted(!save.settings.soundOn);
    return save;
  }

  Future<void> mutate(GameSave Function(GameSave save) update) async {
    final current = state.value;
    if (current == null) return; // still loading/erroring — see ARCHITECTURE.md §3.7, load() never throws in practice
    final next = update(current);
    // `update` conventionally mutates `current` in place and returns it — same
    // reference as `current`, so AsyncData's identity-based equality would
    // skip notifying watchers. Round-trip through JSON to force a new
    // instance (cheap at this data size, reuses the (de)serializers we
    // already have instead of hand-writing copyWith on every entity).
    final fresh = GameSave.fromJson(next.toJson());
    state = AsyncData(fresh);
    await ref.read(progressRepositoryProvider).save(fresh);
  }
}

final gameSaveProvider = AsyncNotifierProvider<GameSaveController, GameSave>(
  GameSaveController.new,
);
