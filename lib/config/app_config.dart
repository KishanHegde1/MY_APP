import 'environment.dart';
import 'flavor.dart';

final class AppConfig {
  const AppConfig({
    required this.appName,
    required this.apiBaseUri,
    required this.flavor,
    required this.enableLogging,
    required this.requestTimeout,
  });

  factory AppConfig.fromEnvironment() {
    return AppConfig(
      appName: Environment.appName,
      apiBaseUri: Environment.apiBaseUri,
      flavor: Environment.flavor,
      enableLogging: Environment.enableLogging,
      requestTimeout: Environment.requestTimeout,
    );
  }

  final String appName;
  final Uri apiBaseUri;
  final Flavor flavor;
  final bool enableLogging;
  final Duration requestTimeout;
}
