class AppException implements Exception {
  const AppException(this.message, {this.code, this.cause, this.stackTrace});

  final String message;
  final String? code;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() => code == null ? message : '[$code] $message';
}

final class ValidationException extends AppException {
  const ValidationException(super.message, {super.code = 'validation'});
}

final class StorageException extends AppException {
  const StorageException(super.message, {super.cause, super.stackTrace})
    : super(code: 'storage');
}

final class PermissionException extends AppException {
  const PermissionException(super.message) : super(code: 'permission');
}
