import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A bounded, resilient image primitive for server-owned media.
///
/// It deliberately renders a placeholder and never makes the surrounding
/// screen wait for a remote image. Cached bytes are reused on subsequent
/// launches and the fallback remains useful when the device is offline.
class AppCachedImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius borderRadius;
  final Widget? fallback;

  const AppCachedImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = BorderRadius.zero,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = url?.trim();
    final child = imageUrl == null || imageUrl.isEmpty
        ? _fallback()
        : CachedNetworkImage(
            imageUrl: imageUrl,
            width: width,
            height: height,
            fit: fit,
            fadeInDuration: const Duration(milliseconds: 180),
            placeholder: (_, __) => _placeholder(),
            errorWidget: (_, __, ___) => _fallback(),
          );

    if (borderRadius == BorderRadius.zero) return child;
    return ClipRRect(borderRadius: borderRadius, child: child);
  }

  Widget _placeholder() => _MediaSurface(
        width: width,
        height: height,
        child: const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );

  Widget _fallback() =>
      fallback ?? _MediaSurface(width: width, height: height);
}

class _MediaSurface extends StatelessWidget {
  final double? width;
  final double? height;
  final Widget? child;

  const _MediaSurface({this.width, this.height, this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.surfaceContainerHigh,
            AppTheme.surfaceContainer,
          ],
        ),
      ),
      alignment: Alignment.center,
      child: child ??
          Icon(
            Icons.image_not_supported_outlined,
            color: AppTheme.onSurfaceVariant.withOpacity(0.55),
          ),
    );
  }
}
