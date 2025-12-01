import 'dart:html' as html;

/// Centralized API configuration
/// 
/// This class manages the base URL for all API calls.
/// - In development (flutter run): uses hardcoded server IP
/// - In production (deployed): uses the server's own origin
class ApiConfig {
  /// Development server URL (used during flutter run)
  static const String devServerUrl = 'http://100.82.42.53:5090';

  /// Determines if we're running in development mode
  /// Development = localhost or any non-production domain
  static bool get isDevelopment {
    final hostname = html.window.location.hostname;
    return hostname == 'localhost' || hostname == '127.0.0.1';
  }

  /// Gets the appropriate base URL based on environment
  /// - Development: returns devServerUrl
  /// - Production: returns current server origin
  static String get baseUrl {
    if (isDevelopment) {
      return devServerUrl;
    }
    return html.window.location.origin;
  }

  /// IPC gateway prefix (all API calls go through this)
  static const String ipcPrefix = '/ipc';

  /// Builds a complete API URL
  /// Example: buildUrl('/boards') -> 'http://100.82.42.53:5090/ipc/boards'
  static String buildUrl(String endpoint) {
    // Ensure endpoint starts with /
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return '$baseUrl$ipcPrefix$cleanEndpoint';
  }
}
