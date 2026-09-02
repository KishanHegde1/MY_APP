import 'dart:developer' as developer;

final class AppLogger {
  const AppLogger({this.enabled = true});
  final bool enabled;

  void debug(String message, {Object? error, StackTrace? stackTrace}) {
    if (!enabled) return;
    developer.log(
      message,
      name: 'MultiService',
      error: error,
      stackTrace: stackTrace,
    );
  }

  void warning(String message, {Object? error, StackTrace? stackTrace}) {
    if (!enabled) return;
    developer.log(
      message,
      name: 'MultiService',
      level: 900,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void error(String message, {Object? error, StackTrace? stackTrace}) {
    if (!enabled) return;
    developer.log(
      message,
      name: 'MultiService',
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
