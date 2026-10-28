import 'package:flutter/foundation.dart';

/// Central API Configuration for RentBox
///
/// Supports:
/// 1. Production deployments with build-time environment flags:
///    `flutter run --dart-define=ENVIRONMENT=production --dart-define=API_URL=https://your-api-domain.com/api`
///    `flutter build apk --dart-define=ENVIRONMENT=production --dart-define=API_URL=https://your-api-domain.com/api`
///
/// 2. Local development across:
///    - Web / Desktop: http://localhost:5000/api
///    - Android Emulator: http://10.0.2.2:5000/api
///    - Physical Mobile Device: PC LAN IP or auto-fallback
class ApiConfig {
  ApiConfig._();

  /// Environment mode: 'development', 'staging', or 'production'
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: kReleaseMode ? 'production' : 'development',
  );

  /// User-defined API URL passed at build time via --dart-define=API_URL=https://...
  static const String _definedApiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: '',
  );

  /// Default production API endpoint when running in release/production mode
  /// without an explicit --dart-define=API_URL flag.
  /// Update this to your deployed domain (e.g. on Railway, Render, Fly.io, or VPS).
  static const String defaultProductionApiUrl = 'https://rentbox-api-production.up.railway.app/api';

  /// Local development IP for Android emulator (10.0.2.2 maps to host localhost).
  static String activeLocalHost = '10.0.2.2';

  /// Optional runtime override (useful for runtime testing or custom server settings).
  static String? runtimeBaseUrlOverride;

  /// Returns true if currently operating in production mode.
  static bool get isProduction =>
      environment.toLowerCase() == 'production' ||
      (_definedApiUrl.isNotEmpty && !_definedApiUrl.contains('localhost') && !_definedApiUrl.contains('10.0.2.2') && !_definedApiUrl.contains('192.168.'));

  /// Resolves the active REST API base URL.
  static String get baseUrl {
    // 1. Check runtime override
    if (runtimeBaseUrlOverride != null && runtimeBaseUrlOverride!.trim().isNotEmpty) {
      final override = runtimeBaseUrlOverride!.trim();
      return override.endsWith('/api') ? override : (override.endsWith('/') ? '${override}api' : '$override/api');
    }

    // 2. Check build-time --dart-define=API_URL flag
    if (_definedApiUrl.isNotEmpty) {
      final url = _definedApiUrl.trim();
      return url.endsWith('/api') ? url : (url.endsWith('/') ? '${url}api' : '$url/api');
    }

    // 3. If in production or release mode, use the default production URL
    if (isProduction) {
      return defaultProductionApiUrl;
    }

    // 4. Local Development Fallbacks
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      // Connects to local development machine
      return 'http://$activeLocalHost:5000/api';
    }

    return 'http://localhost:5000/api';
  }

  /// Returns the base server root without the '/api' suffix (e.g., https://domain.com or http://192.168.x.x:5000).
  static String get serverRootUrl {
    final base = baseUrl;
    if (base.endsWith('/api')) {
      return base.substring(0, base.length - 4);
    }
    return base;
  }

  /// Returns the full URL to the Admin Web Portal.
  static String getAdminPortalUrl([String? token]) {
    final root = serverRootUrl;
    final tokenParam = (token != null && token.isNotEmpty) ? '?token=$token' : '';
    return '$root/admin.html$tokenParam';
  }

  /// Resolves an image/media URL:
  /// - Full URLs (https://...) are returned as-is
  /// - Server uploads (/uploads/...) are prefixed with the current serverRootUrl
  /// - Assets (assets/...) are returned as-is
  static String resolveMediaUrl(String pathOrUrl) {
    if (pathOrUrl.trim().isEmpty) return 'assets/images/camera.jpg';
    final trimmed = pathOrUrl.trim();

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      // If a URL was stored with localhost, 127.0.0.1, or 10.0.2.2, rewrite to the active serverRootUrl
      if (trimmed.contains('localhost:5000') ||
          trimmed.contains('127.0.0.1:5000') ||
          trimmed.contains('10.0.2.2:5000')) {
        return trimmed.replaceAll(
          RegExp(r'https?:\/\/(localhost|127\.0\.0\.1|10\.0\.2\.2):5000'),
          serverRootUrl,
        );
      }
      return trimmed;
    }

    if (trimmed.startsWith('/uploads/') || trimmed.startsWith('uploads/')) {
      final clean = trimmed.startsWith('/') ? trimmed : '/$trimmed';
      return '$serverRootUrl$clean';
    }

    return trimmed;
  }
}
