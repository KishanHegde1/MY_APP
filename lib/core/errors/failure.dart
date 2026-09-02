enum FailureType {
  network,
  authentication,
  authorization,
  validation,
  server,
  storage,
  unknown,
}

final class Failure {
  const Failure({
    required this.message,
    this.type = FailureType.unknown,
    this.code,
    this.cause,
  });

  final String message;
  final FailureType type;
  final String? code;
  final Object? cause;
}
