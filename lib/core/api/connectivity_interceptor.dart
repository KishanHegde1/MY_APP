import '../network/network_info.dart';
import 'api_client.dart';
import 'api_exception.dart';

final class ConnectivityInterceptor implements ApiInterceptor {
  const ConnectivityInterceptor(this._networkInfo);

  final NetworkInfo _networkInfo;

  @override
  Future<ApiRequest> onRequest(ApiRequest request) async {
    if (!await _networkInfo.isConnected) {
      throw const ApiException(
        'No internet connection.',
        code: 'network_unavailable',
      );
    }
    return request;
  }

  @override
  Future<ApiTransportResponse> onResponse(ApiTransportResponse response) async {
    return response;
  }
}
