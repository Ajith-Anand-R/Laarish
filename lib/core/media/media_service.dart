import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Captures a plant-diary photo (camera or gallery) and persists a copy in the
/// app's documents directory so it survives even if the original is cleared.
/// Returns the saved file path, or null if the child cancelled or the pick
/// failed (fail-soft — a photo is always optional, never blocks a level).
class MediaService {
  MediaService._();
  static final instance = MediaService._();

  final _picker = ImagePicker();

  Future<String?> capture({required ImageSource source, required String plantId, required int level}) async {
    try {
      final XFile? shot = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        imageQuality: 82,
      );
      if (shot == null) return null;

      final dir = await getApplicationDocumentsDirectory();
      final photos = Directory('${dir.path}/plant_photos');
      if (!photos.existsSync()) photos.createSync(recursive: true);

      final ext = shot.path.split('.').last;
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final dest = '${photos.path}/${plantId}_l${level}_$stamp.$ext';
      await File(shot.path).copy(dest);
      return dest;
    } catch (_) {
      // Permission denied / no camera / cancelled — photos are optional.
      return null;
    }
  }
}
