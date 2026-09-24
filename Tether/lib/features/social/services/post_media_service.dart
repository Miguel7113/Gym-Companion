import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class PostMediaService {
  final ImagePicker _picker;
  PostMediaService([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  Future<XFile?> pickWorkoutPhoto({
    ImageSource source = ImageSource.gallery,
  }) async {
    final file = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
      maxHeight: 1600,
    );
    if (file == null) return null;
    return file;
  }

  Future<String> uploadWorkoutPhoto(XFile file) async {
    final authUser = Supabase.instance.client.auth.currentUser;
    if (authUser == null) {
      throw StateError('You must be signed in to upload a workout photo');
    }
    final bytes = await file.readAsBytes();
    if (bytes.length > 10 * 1024 * 1024) {
      throw StateError('Photo must be smaller than 10 MB');
    }

    final mimeType = file.mimeType ?? 'image/jpeg';
    if (!const {'image/jpeg', 'image/png', 'image/webp'}.contains(mimeType)) {
      throw StateError('Choose a JPEG, PNG, or WEBP image');
    }
    final extension = mimeType.split('/').last;
    const uuid = Uuid();
    final path = '${authUser.id}/${uuid.v4()}.$extension';

    await Supabase.instance.client.storage
        .from('post-images')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: mimeType, upsert: false),
        );
    return path;
  }

  /// Backwards-compatible convenience method for callers that want to pick
  /// and upload in one step.
  Future<String?> pickAndUploadWorkoutPhoto({
    ImageSource source = ImageSource.gallery,
  }) async {
    final file = await pickWorkoutPhoto(source: source);
    if (file == null) return null;
    return uploadWorkoutPhoto(file);
  }
}

final postMediaServiceProvider = Provider<PostMediaService>((ref) {
  return PostMediaService();
});
