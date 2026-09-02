import 'api_exception.dart';
import 'api_response.dart';

enum HttpMethod { get, post, put, patch, delete }

final class ApiRequest {
  const ApiRequest({
    required this.method,
    required this.uri,
    this.headers = const <String, String>{},
    this.body,
  });

  final HttpMethod method;
  final Uri uri;
  final Map<String, String> headers;
  final Object? body;

  ApiRequest copyWith({
    HttpMethod? method,
    Uri? uri,
    Map<String, String>? headers,
    Object? body,
  }) {
    return ApiRequest(
      method: method ?? this.method,
      uri: uri ?? this.uri,
      headers: headers ?? this.headers,
      body: body ?? this.body,
    );
  }
}

final class ApiTransportResponse {
  const ApiTransportResponse({
    required this.statusCode,
    this.body,
    this.headers = const <String, String>{},
  });

  final int statusCode;
  final Object? body;
  final Map<String, String> headers;
}

abstract interface class ApiTransport {
  Future<ApiTransportResponse> send(ApiRequest request);
}

abstract interface class ApiInterceptor {
  Future<ApiRequest> onRequest(ApiRequest request);
  Future<ApiTransportResponse> onResponse(ApiTransportResponse response);
}

final class UnsupportedApiTransport implements ApiTransport {
  const UnsupportedApiTransport();

  @override
  Future<ApiTransportResponse> send(ApiRequest request) {
    throw const ApiException(
      'No HTTP transport has been registered.',
      code: 'transport_not_configured',
    );
  }
}

final class ApiClient {
  ApiClient({
    required this.baseUri,
    this.transport = const UnsupportedApiTransport(),
    List<ApiInterceptor> interceptors = const <ApiInterceptor>[],
  }) : _interceptors = List.unmodifiable(interceptors);

  final Uri baseUri;
  final ApiTransport transport;
  final List<ApiInterceptor> _interceptors;

  Future<ApiResponse<T>> request<T>(
    String path, {
    HttpMethod method = HttpMethod.get,
    Map<String, Object?> query = const <String, Object?>{},
    Map<String, String> headers = const <String, String>{},
    Object? body,
    required T Function(Object? value) decode,
  }) async {
    var request = ApiRequest(
      method: method,
      uri: _buildUri(path, query),
      headers: {'Accept': 'application/json', ...headers},
      body: body,
    );
    for (final interceptor in _interceptors) {
      request = await interceptor.onRequest(request);
    }

    var response = await transport.send(request);
    for (final interceptor in _interceptors.reversed) {
      response = await interceptor.onResponse(response);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final payload = response.body;
      final message = payload is Map<Object?, Object?>
          ? payload['message']?.toString() ?? 'Request failed.'
          : 'Request failed.';
      throw ApiException(message, statusCode: response.statusCode);
    }

    final payload = response.body;
    if (payload is Map<Object?, Object?>) {
      final json = payload.map((key, value) => MapEntry(key.toString(), value));
      return ApiResponse<T>.fromJson(json, decode);
    }
    return ApiResponse<T>(success: true, data: decode(payload));
  }

  Uri _buildUri(String path, Map<String, Object?> query) {
    final base = baseUri.toString().replaceFirst(RegExp(r'/$'), '');
    final suffix = path.replaceFirst(RegExp(r'^/'), '');
    final uri = Uri.parse('$base/$suffix');
    if (query.isEmpty) return uri;
    return uri.replace(
      queryParameters: query.map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      ),
    );
  }
}
