import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_theme.dart';

enum ImageCropShape {
  /// Matches the 16:9 frame workout photos are shown in on the feed.
  feedPhoto,

  /// Square crop shown as a circle, for profile pictures.
  avatar,
}

/// Lets the user crop [source] before it is uploaded.
///
/// Returns `null` when the user cancels the crop screen. Platforms without a
/// native cropper (desktop, tests) get the original file back unchanged.
Future<XFile?> cropPickedImage(
  XFile source, {
  required ImageCropShape shape,
}) async {
  if (!_cropperSupported) return source;

  final isAvatar = shape == ImageCropShape.avatar;
  final ratio = isAvatar
      ? const CropAspectRatio(ratioX: 1, ratioY: 1)
      : const CropAspectRatio(ratioX: 16, ratioY: 9);
  final maxSize = isAvatar ? 800 : 1600;
  final title = isAvatar ? 'Crop profile photo' : 'Crop photo';

  try {
    final cropped = await ImageCropper().cropImage(
      sourcePath: source.path,
      aspectRatio: ratio,
      maxWidth: maxSize,
      maxHeight: maxSize,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 85,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: title,
          toolbarColor: AppTheme.surface,
          toolbarWidgetColor: AppTheme.onSurface,
          statusBarLight: false,
          backgroundColor: AppTheme.surface,
          activeControlsWidgetColor: AppTheme.primaryContainer,
          cropFrameColor: AppTheme.primaryContainer,
          cropStyle: isAvatar ? CropStyle.circle : CropStyle.rectangle,
          lockAspectRatio: true,
          hideBottomControls: false,
        ),
        IOSUiSettings(
          title: title,
          cropStyle: isAvatar ? CropStyle.circle : CropStyle.rectangle,
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          aspectRatioPickerButtonHidden: true,
        ),
      ],
    );
    if (cropped == null) return null;
    return XFile(cropped.path, mimeType: 'image/jpeg');
  } on MissingPluginException {
    return source;
  }
}

bool get _cropperSupported {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}
