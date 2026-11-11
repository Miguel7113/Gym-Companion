import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'custom_crop_screen.dart';

enum ImageCropShape {
  /// Matches the 1:1 square frame photos are shown in on the feed.
  feedPhoto,

  /// Square crop shown as a circle, for profile pictures.
  avatar,
}

/// Lets the user crop [source] before it is uploaded.
///
/// Returns `null` when the user cancels the crop screen.
Future<XFile?> cropPickedImage(
  XFile source, {
  required ImageCropShape shape,
  required BuildContext context,
}) async {
  final isAvatar = shape == ImageCropShape.avatar;
  final title = isAvatar ? 'Crop profile photo' : 'Crop photo';

  // Navigate to custom crop screen
  final File? croppedFile = await Navigator.of(context).push<File>(
    MaterialPageRoute(
      builder: (context) => CustomCropScreen(
        imageFile: File(source.path),
        isCircle: isAvatar,
        title: title,
      ),
      fullscreenDialog: true,
    ),
  );

  if (croppedFile == null) return null;
  return XFile(croppedFile.path, mimeType: 'image/jpeg');
}
