import 'api_client.dart';

typedef AccessTokenProvider = Future<String?> Function();

final class AuthInterceptor implements ApiInterceptor {
  const AuthInterceptor(this._accessTokenProvider);

  final AccessTokenProvider _accessTokenProvider;

  @override
  Future<ApiRequest> onRequest(ApiRequest request) async {
    final token = await _accessTokenProvider();
    if (token == null || token.isEmpty) return request;
    return request.copyWith(
      headers: {...request.headers, 'Authorization': 'Bearer $token'},
    );
  }

  @override
  Future<ApiTransportResponse> onResponse(ApiTransportResponse response) async {
    return response;
  }
}
