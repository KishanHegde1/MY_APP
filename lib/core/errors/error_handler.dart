import '../api/api_exception.dart';
import 'app_exception.dart';
import 'failure.dart';

abstract final class ErrorHandler {
  static Failure toFailure(Object error) {
    if (error is ApiException) {
      return Failure(
        message: error.message,
        type: error.isAuthenticationError
            ? FailureType.authentication
            : FailureType.server,
        code: error.code,
        cause: error,
      );
    }
    if (error is ValidationException) {
      return Failure(
        message: error.message,
        type: FailureType.validation,
        code: error.code,
        cause: error,
      );
    }
    if (error is StorageException) {
      return Failure(
        message: error.message,
        type: FailureType.storage,
        code: error.code,
        cause: error,
      );
    }
    if (error is AppException) {
      return Failure(message: error.message, code: error.code, cause: error);
    }
    return Failure(message: 'Something went wrong.', cause: error);
  }
}
