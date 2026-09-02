import 'package:flutter_test/flutter_test.dart';
import 'package:my_app_flutter/features/local_rides/data/services/estimated_route_planning_service.dart';
import 'package:my_app_flutter/features/local_rides/domain/models/ride_route_plan.dart';
import 'package:my_app_flutter/features/local_rides/domain/services/route_planning_service.dart';
import 'package:my_app_flutter/shared/models/location_model.dart';

void main() {
  const pickup = LocationModel(latitude: 12, longitude: 77, label: 'Pickup');

  test('rejects an estimated local ride shorter than 1 km', () async {
    final service = EstimatedRoutePlanningService(
      destinationResolver: _FixedDestinationResolver(
        const LocationModel(latitude: 12.004, longitude: 77),
      ),
    );

    await expectLater(
      service.planRoutes(
        pickup: pickup,
        destinationQuery: 'Nearby point',
        vehicle: RideRouteVehicle.bike,
      ),
      throwsA(
        isA<RoutePlanningException>().having(
          (error) => error.message,
          'message',
          contains('at least 1 km'),
        ),
      ),
    );
  });

  test('rejects an estimated local ride longer than 100 km', () async {
    final service = EstimatedRoutePlanningService(
      destinationResolver: _FixedDestinationResolver(
        const LocationModel(latitude: 13, longitude: 77),
      ),
    );

    await expectLater(
      service.planRoutes(
        pickup: pickup,
        destinationQuery: 'Far destination',
        vehicle: RideRouteVehicle.car,
      ),
      throwsA(
        isA<RoutePlanningException>().having(
          (error) => error.message,
          'message',
          contains('maximum local ride distance is 100 km'),
        ),
      ),
    );
  });

  test('does not offer an alternative that exceeds 100 km', () async {
    final service = EstimatedRoutePlanningService(
      destinationResolver: _FixedDestinationResolver(
        const LocationModel(latitude: 12.7, longitude: 77),
      ),
    );

    final plan = await service.planRoutes(
      pickup: pickup,
      destinationQuery: 'Near range edge',
      vehicle: RideRouteVehicle.auto,
    );

    expect(plan.routes, isNotEmpty);
    expect(
      plan.routes.every(
        (route) => route.distanceKm >= 1 && route.distanceKm <= 100,
      ),
      isTrue,
    );
    expect(plan.routes.first.id, 'recommended');
  });
}

final class _FixedDestinationResolver implements DestinationResolver {
  const _FixedDestinationResolver(this.destination);

  final LocationModel destination;

  @override
  Future<LocationModel?> resolve({
    required String query,
    LocationModel? near,
  }) async => destination;
}
