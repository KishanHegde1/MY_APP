final class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.meta = const <String, Object?>{},
  });

  factory ApiResponse.fromJson(
    Map<String, Object?> json,
    T Function(Object? value) decode,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool? ?? true,
      data: json.containsKey('data') ? decode(json['data']) : null,
      message: json['message'] as String?,
      meta: switch (json['meta']) {
        final Map<Object?, Object?> value => value.map(
          (key, value) => MapEntry(key.toString(), value),
        ),
        _ => const <String, Object?>{},
      },
    );
  }

  final bool success;
  final T? data;
  final String? message;
  final Map<String, Object?> meta;

  ApiResponse<R> map<R>(R Function(T value) transform) {
    return ApiResponse<R>(
      success: success,
      data: data == null ? null : transform(data as T),
      message: message,
      meta: meta,
    );
  }
}
