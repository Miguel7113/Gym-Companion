import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:crop_image/crop_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

import '../theme/app_theme.dart';

/// Custom crop screen with foundry aesthetic and precise button positioning.
class CustomCropScreen extends StatefulWidget {
  final File imageFile;
  final bool isCircle;
  final String title;

  const CustomCropScreen({
    super.key,
    required this.imageFile,
    required this.isCircle,
    required this.title,
  });

  @override
  State<CustomCropScreen> createState() => _CustomCropScreenState();
}

class _CustomCropScreenState extends State<CustomCropScreen> {
  late final CropController cropController;
  bool _isProcessing = false;
  bool _imageLoaded = false;

  @override
  void initState() {
    super.initState();
    cropController = CropController(
      aspectRatio: 1, // Always 1:1 square
      defaultCrop: const Rect.fromLTRB(0.1, 0.1, 0.9, 0.9), // Default crop area
    );
  }

  @override
  void dispose() {
    cropController.dispose();
    super.dispose();
  }

  Future<ui.Image> _loadImage() async {
    final bytes = await widget.imageFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Future<void> _cropImage() async {
    if (!_imageLoaded) {
      _showError('Please wait for the image to load');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Wait a frame to ensure the crop controller is ready
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Get the crop size to validate it's ready
      final cropSize = cropController.cropSize;
      if (cropSize.width <= 0 || cropSize.height <= 0) {
        throw Exception('Invalid crop size. Please adjust the crop area.');
      }
      
      // Get the cropped image as ui.Image
      final croppedUiImage = await cropController.croppedBitmap();
      
      // Convert ui.Image to bytes
      final byteData = await croppedUiImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) {
        if (mounted) {
          setState(() => _isProcessing = false);
          _showError('Failed to process image');
        }
        return;
      }

      final pngBytes = byteData.buffer.asUint8List();
      
      // Decode and convert to JPEG with compression
      final image = img.decodeImage(pngBytes);
      if (image == null) {
        if (mounted) {
          setState(() => _isProcessing = false);
          _showError('Failed to decode image');
        }
        return;
      }

      // Resize if too large
      final maxSize = widget.isCircle ? 800 : 1600;
      final resized = image.width > maxSize || image.height > maxSize
          ? img.copyResize(
              image,
              width: image.width > image.height ? maxSize : null,
              height: image.height > image.width ? maxSize : null,
            )
          : image;

      // Encode as JPEG with 85% quality
      final jpegBytes = img.encodeJpg(resized, quality: 85);

      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final croppedFile = File('${tempDir.path}/cropped_$timestamp.jpg');
      await croppedFile.writeAsBytes(jpegBytes);

      if (mounted) {
        Navigator.of(context).pop(croppedFile);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showError('Failed to crop image: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            // Crop widget
            Column(
              children: [
                // Title bar
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      color: AppTheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                
                // Crop area
                Expanded(
                  child: FutureBuilder<ui.Image>(
                    future: _loadImage(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primary,
                          ),
                        );
                      }
                      
                      if (snapshot.hasError || !snapshot.hasData) {
                        return Center(
                          child: Text(
                            'Failed to load image',
                            style: TextStyle(color: AppTheme.onSurface),
                          ),
                        );
                      }
                      
                      // Mark image as loaded
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && !_imageLoaded) {
                          setState(() => _imageLoaded = true);
                        }
                      });
                      
                      return CropImage(
                        controller: cropController,
                        image: Image.file(
                          widget.imageFile,
                          fit: BoxFit.contain,
                        ),
                        gridColor: AppTheme.primary.withValues(alpha: 0.7),
                        scrimColor: Colors.black.withValues(alpha: 0.7),
                        gridCornerSize: 30,
                        gridThinWidth: 1,
                        gridThickWidth: 3,
                        alwaysShowThirdLines: false,
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 80), // Space for bottom buttons
              ],
            ),
            
            // Bottom action buttons - positioned inside the safe area
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Cancel button (X)
                    _ActionButton(
                      icon: Icons.close,
                      onPressed: _isProcessing
                          ? null
                          : () => Navigator.of(context).pop(null),
                      backgroundColor: AppTheme.surfaceContainerHighest,
                      iconColor: AppTheme.onSurface,
                    ),
                    
                    // Confirm button (✓)
                    _ActionButton(
                      icon: Icons.check,
                      onPressed: _isProcessing ? null : _cropImage,
                      backgroundColor: AppTheme.primary,
                      iconColor: AppTheme.onPrimary,
                      isLoading: _isProcessing,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color iconColor;
  final bool isLoading;

  const _ActionButton({
    required this.icon,
    required this.onPressed,
    required this.backgroundColor,
    required this.iconColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          child: isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: iconColor,
                    strokeWidth: 2.5,
                  ),
                )
              : Icon(
                  icon,
                  color: iconColor,
                  size: 32,
                ),
        ),
      ),
    );
  }
}
