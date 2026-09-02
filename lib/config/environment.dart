import 'flavor.dart';

abstract final class Environment {
  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'Multi Service',
  );

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api/v1',
  );

  static const String flavorName = String.fromEnvironment(
    'APP_FLAVOR',
    defaultValue: 'development',
  );

  static const bool enableLogging = bool.fromEnvironment(
    'ENABLE_LOGGING',
    defaultValue: true,
  );

  static const Duration requestTimeout = Duration(
    milliseconds: int.fromEnvironment('API_TIMEOUT_MS', defaultValue: 30000),
  );

  static Flavor get flavor => Flavor.fromName(flavorName);

  static Uri get apiBaseUri {
    final uri = Uri.tryParse(apiBaseUrl);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw const FormatException(
        'API_BASE_URL must be an absolute http(s) URL.',
      );
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      throw const FormatException('API_BASE_URL must use http or https.');
    }
    return uri;
  }
}
