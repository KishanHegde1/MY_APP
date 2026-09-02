import '../errors/app_exception.dart';

final class ApiException extends AppException {
  const ApiException(
    super.message, {
    this.statusCode,
    super.code,
    super.cause,
    super.stackTrace,
  });

  final int? statusCode;

  bool get isAuthenticationError => statusCode == 401;
  bool get isAuthorizationError => statusCode == 403;
}
