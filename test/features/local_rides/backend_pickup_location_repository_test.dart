import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app_flutter/features/local_rides/data/repositories/backend_pickup_location_repository.dart';
import 'package:my_app_flutter/features/local_rides/domain/models/pickup_location_source.dart';
import 'package:my_app_flutter/features/local_rides/domain/repositories/pickup_location_repository.dart';

void main() {
  test(
    'saves exact confirmed pin coordinates for the authenticated user',
    () async {
      final dio = Dio();
      late RequestOptions capturedRequest;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedRequest = options;
            handler.resolve(
              Response<Object?>(requestOptions: options, statusCode: 200),
            );
          },
        ),
      );
      final repository = BackendPickupLocationRepository(
        apiBaseUri: Uri.parse('http://127.0.0.1:3000/api/v1'),
        bearerTokenProvider: () async => 'verified-token',
        dio: dio,
      );

      await repository.savePickupLocation(
        latitude: 12.9279234,
        longitude: 77.6271071,
        formattedAddress: 'Exact pickup address',
        source: PickupLocationSource.mapPin,
      );

      expect(
        capturedRequest.path,
        'http://127.0.0.1:3000/api/v1/users/me/pickup-location',
      );
      expect(capturedRequest.headers['Authorization'], 'Bearer verified-token');
      expect(capturedRequest.data, <String, Object>{
        'latitude': 12.9279234,
        'longitude': 77.6271071,
        'formattedAddress': 'Exact pickup address',
        'source': 'MAP_PIN',
      });
    },
  );

  test('does not make an unauthenticated database write', () async {
    final dio = Dio();
    var calls = 0;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          calls += 1;
          handler.next(options);
        },
      ),
    );
    final repository = BackendPickupLocationRepository(
      apiBaseUri: Uri.parse('http://127.0.0.1:3000/api/v1'),
      bearerTokenProvider: () async => null,
      dio: dio,
    );

    await expectLater(
      repository.savePickupLocation(
        latitude: 12.9279234,
        longitude: 77.6271071,
        formattedAddress: 'Exact pickup address',
        source: PickupLocationSource.mapPin,
      ),
      throwsA(
        isA<PickupLocationPersistenceException>().having(
          (error) => error.failure,
          'failure',
          PickupLocationPersistenceFailure.authenticationRequired,
        ),
      ),
    );
    expect(calls, 0);
  });
}
