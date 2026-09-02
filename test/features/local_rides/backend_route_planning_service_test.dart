import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app_flutter/config/app_config.dart';
import 'package:my_app_flutter/config/flavor.dart';
import 'package:my_app_flutter/features/local_rides/data/services/backend_route_planning_service.dart';
import 'package:my_app_flutter/features/local_rides/domain/models/ride_route_plan.dart';
import 'package:my_app_flutter/features/local_rides/domain/services/route_planning_service.dart';
import 'package:my_app_flutter/shared/models/location_model.dart';

void main() {
  test(
    'parses the backend envelope, requested vehicle fare, and polyline',
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
                  'success': true,
                  'data': <String, Object?>{
                    'routes': <Object?>[
                      <String, Object?>{
                        'id': 'route-1',
                        'isRecommended': true,
                        'distanceMeters': 12345,
                        'distanceKilometers': 12.35,
                        'durationSeconds': 1800,
                        'durationMinutes': 30,
                        'encodedPolyline': '_p~iF~ps|U_ulLnnqC_mqNvxq`@',
                        'fareEstimates': <Object?>[
                          <String, Object?>{
                            'vehicleType': 'BIKE',
                            'currency': 'INR',
                            'estimatedAmount': 142,
                            'isEstimate': true,
                          },
                        ],
                      },
                    ],
                  },
                },
              ),
            );
          },
        ),
      );
      final service = BackendRoutePlanningService(
        config: AppConfig(
          appName: 'Test',
          apiBaseUri: Uri(
            scheme: 'http',
            host: '127.0.0.1',
            port: 3000,
            path: '/api/v1',
          ),
          flavor: Flavor.development,
          enableLogging: false,
          requestTimeout: Duration(seconds: 2),
        ),
        destinationResolver: const _DestinationResolver(),
        dio: dio,
      );

      final plan = await service.planRoutes(
        pickup: const LocationModel(
          latitude: 12.9716,
          longitude: 77.5946,
          label: 'Pickup',
        ),
        destinationQuery: 'MG Road',
        vehicle: RideRouteVehicle.bike,
      );

      expect(capturedRequest.path, 'http://127.0.0.1:3000/api/v1/maps/routes');
      final requestBody = capturedRequest.data! as Map<String, Object?>;
      expect(requestBody['vehicleType'], 'BIKE');
      expect(requestBody['alternatives'], isTrue);
      expect(plan.source, RideRouteSource.googleRoutes);
      expect(plan.routes, hasLength(1));
      expect(plan.routes.single.distanceKm, 12.35);
      expect(plan.routes.single.durationMinutes, 30);
      expect(plan.routes.single.fareFor('bike'), 142);
      expect(plan.routes.single.points, hasLength(3));
      expect(plan.routes.single.points.first.latitude, closeTo(38.5, 0.00001));
      expect(
        plan.routes.single.points.first.longitude,
        closeTo(-120.2, 0.00001),
      );
    },
  );
}

final class _DestinationResolver implements DestinationResolver {
  const _DestinationResolver();

  @override
  Future<LocationModel?> resolve({
    required String query,
    LocationModel? near,
  }) async => const LocationModel(
    latitude: 12.9756,
    longitude: 77.6064,
    label: 'MG Road',
  );
}
