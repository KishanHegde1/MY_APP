import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app_flutter/config/app_config.dart';
import 'package:my_app_flutter/config/flavor.dart';
import 'package:my_app_flutter/features/local_rides/data/services/backend_destination_resolver.dart';
import 'package:my_app_flutter/features/local_rides/domain/services/route_planning_service.dart';
import 'package:my_app_flutter/shared/models/location_model.dart';

void main() {
  const near = LocationModel(
    latitude: 12.9716,
    longitude: 77.5946,
    label: 'Current location',
  );

  test('resolves a destination through the backend Places endpoint', () async {
    final dio = Dio();
    late RequestOptions capturedRequest;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedRequest = options;
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              statusCode: 200,
              data: <String, Object?>{
                'success': true,
                'data': <String, Object?>{
                  'query': 'MG Road',
                  'source': 'GOOGLE_PLACES_TEXT_SEARCH',
                  'place': <String, Object?>{
                    'placeId': 'ChIJplace',
                    'name': 'MG Road',
                    'formattedAddress': 'MG Road, Bengaluru, Karnataka, India',
                    'latitude': 12.9756,
                    'longitude': 77.6064,
                  },
                },
              },
            ),
          );
        },
      ),
    );
    final fallback = _RecordingResolver();
    final resolver = BackendDestinationResolver(
      config: _config(),
      fallback: fallback,
      dio: dio,
    );

    final destination = await resolver.resolve(query: 'MG Road', near: near);

    expect(
      capturedRequest.path,
      'http://127.0.0.1:3000/api/v1/maps/places/resolve',
    );
    expect(capturedRequest.data, <String, Object?>{
      'query': 'MG Road',
      'near': <String, double>{
        'latitude': near.latitude,
        'longitude': near.longitude,
      },
    });
    expect(destination?.latitude, 12.9756);
    expect(destination?.longitude, 77.6064);
    expect(destination?.label, 'MG Road, Bengaluru, Karnataka, India');
    expect(fallback.calls, 0);
  });

  test('uses the device resolver when the backend is unavailable', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          ),
        ),
      ),
    );
    final fallback = _RecordingResolver(
      result: const LocationModel(
        latitude: 12.98,
        longitude: 77.61,
        label: 'Fallback destination',
      ),
    );
    final resolver = BackendDestinationResolver(
      config: _config(),
      fallback: fallback,
      dio: dio,
    );

    final destination = await resolver.resolve(query: 'MG Road', near: near);

    expect(destination?.label, 'Fallback destination');
    expect(fallback.calls, 1);
  });

  test('accepts typed coordinates without a paid Places request', () async {
    final dio = Dio();
    var backendCalls = 0;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          backendCalls += 1;
          handler.next(options);
        },
      ),
    );
    final fallback = _RecordingResolver();
    final resolver = BackendDestinationResolver(
      config: _config(),
      fallback: fallback,
      dio: dio,
    );

    final destination = await resolver.resolve(
      query: '12.9756, 77.6064',
      near: near,
    );

    expect(destination?.latitude, 12.9756);
    expect(destination?.longitude, 77.6064);
    expect(backendCalls, 0);
    expect(fallback.calls, 0);
  });

  test(
    'omits the nearby bias when resolving a manually entered pickup',
    () async {
      final dio = Dio();
      late RequestOptions capturedRequest;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedRequest = options;
            handler.resolve(
              Response<Object?>(
                requestOptions: options,
                statusCode: 200,
                data: <String, Object?>{
                  'data': <String, Object?>{'place': null},
                },
              ),
            );
          },
        ),
      );
      final resolver = BackendDestinationResolver(
        config: _config(),
        fallback: _RecordingResolver(),
        dio: dio,
      );

      await resolver.resolve(query: 'Kempegowda Airport');

      expect(capturedRequest.data, <String, Object?>{
        'query': 'Kempegowda Airport',
      });
    },
  );
}

AppConfig _config() => AppConfig(
  appName: 'Test',
  apiBaseUri: Uri(
    scheme: 'http',
    host: '127.0.0.1',
    port: 3000,
    path: '/api/v1',
  ),
  flavor: Flavor.development,
  enableLogging: false,
  requestTimeout: const Duration(seconds: 2),
);

final class _RecordingResolver implements DestinationResolver {
  _RecordingResolver({this.result});

  final LocationModel? result;
  int calls = 0;

  @override
  Future<LocationModel?> resolve({
    required String query,
    LocationModel? near,
  }) async {
    calls += 1;
    return result;
  }
}
