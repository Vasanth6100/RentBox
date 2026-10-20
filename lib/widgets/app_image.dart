import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../config/api_config.dart';

/// Renders asset images, local file images, or network images with immediate asset fallback.
class AppImageWidget extends StatelessWidget {
  final String pathOrUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const AppImageWidget({
    super.key,
    required this.pathOrUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  bool get _isAsset => pathOrUrl.startsWith('assets/');
  bool get _isNetwork =>
      pathOrUrl.startsWith('http://') ||
      pathOrUrl.startsWith('https://') ||
      pathOrUrl.startsWith('/uploads/') ||
      pathOrUrl.startsWith('uploads/');
  bool get _isBase64 => pathOrUrl.startsWith('data:image/');

  String get _resolvedUrl => ApiConfig.resolveMediaUrl(pathOrUrl);

  String _resolveAssetFallback(String input) {
    final lower = input.toLowerCase();
    if (lower.contains('camera') || lower.contains('fx3') || lower.contains('alpha') || lower.contains('1516035069371') || lower.contains('1502920917128')) {
      return 'assets/images/camera.jpg';
    }
    if (lower.contains('ps5') || lower.contains('playstation') || lower.contains('game') || lower.contains('1606813907291')) {
      return 'assets/images/ps5.jpg';
    }
    if (lower.contains('projector') || lower.contains('epson') || lower.contains('1535016120720')) {
      return 'assets/images/projector.jpg';
    }
    if (lower.contains('speaker') || lower.contains('audio') || lower.contains('party') || lower.contains('1545454675')) {
      return 'assets/images/speaker.jpg';
    }
    if (lower.contains('drone') || lower.contains('dji') || lower.contains('1508614589041')) {
      return 'assets/images/drone.jpg';
    }
    if (lower.contains('avatar') || lower.contains('user') || lower.contains('person') || lower.contains('1534528741775')) {
      return 'assets/images/avatar.jpg';
    }
    return 'assets/images/camera.jpg';
  }

  @override
  Widget build(BuildContext context) {
    Widget image;

    if (pathOrUrl.trim().isEmpty) {
      image = Image.asset(
        'assets/images/camera.jpg',
        width: width,
        height: height,
        fit: fit,
      );
    } else if (_isAsset) {
      image = Image.asset(
        pathOrUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          'assets/images/camera.jpg',
          width: width,
          height: height,
          fit: fit,
        ),
      );
    } else if (_isBase64) {
      try {
        final commaIdx = pathOrUrl.indexOf(',');
        final base64Clean = commaIdx != -1 ? pathOrUrl.substring(commaIdx + 1) : pathOrUrl;
        final bytes = base64Decode(base64Clean);
        image = Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => Image.asset('assets/images/camera.jpg', width: width, height: height, fit: fit),
        );
      } catch (_) {
        image = Image.asset('assets/images/camera.jpg', width: width, height: height, fit: fit);
      }
    } else if (_isNetwork) {
      image = Image.network(
        _resolvedUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          final fallback = _resolveAssetFallback(pathOrUrl);
          return Image.asset(
            fallback,
            width: width,
            height: height,
            fit: fit,
          );
        },
      );
    } else {
      final file = File(pathOrUrl);
      if (file.existsSync()) {
        image = Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            final fallback = _resolveAssetFallback(pathOrUrl);
            return Image.asset(
              fallback,
              width: width,
              height: height,
              fit: fit,
            );
          },
        );
      } else {
        final fallback = _resolveAssetFallback(pathOrUrl);
        image = Image.asset(
          fallback,
          width: width,
          height: height,
          fit: fit,
        );
      }
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }
}

ImageProvider getAppImageProvider(String pathOrUrl) {
  if (pathOrUrl.trim().isEmpty) {
    return const AssetImage('assets/images/avatar.jpg');
  } else if (pathOrUrl.startsWith('assets/')) {
    return AssetImage(pathOrUrl);
  } else if (pathOrUrl.startsWith('data:image/')) {
    try {
      final commaIdx = pathOrUrl.indexOf(',');
      final base64Clean = commaIdx != -1 ? pathOrUrl.substring(commaIdx + 1) : pathOrUrl;
      return MemoryImage(base64Decode(base64Clean));
    } catch (_) {
      return const AssetImage('assets/images/avatar.jpg');
    }
  } else if (pathOrUrl.startsWith('/uploads/') || pathOrUrl.startsWith('uploads/')) {
    // Server-relative upload path — resolve to full URL
    final resolved = ApiConfig.resolveMediaUrl(pathOrUrl);
    return NetworkImage(resolved);
  } else if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
    final resolved = ApiConfig.resolveMediaUrl(pathOrUrl);
    return NetworkImage(resolved);
  } else {
    // Local file path (e.g. picked from gallery before upload)
    final file = File(pathOrUrl);
    if (file.existsSync()) {
      return FileImage(file);
    }
    return const AssetImage('assets/images/avatar.jpg');
  }
}
