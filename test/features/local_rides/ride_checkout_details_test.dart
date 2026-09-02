import 'package:flutter_test/flutter_test.dart';
import 'package:my_app_flutter/features/local_rides/domain/models/ride_checkout_details.dart';
import 'package:my_app_flutter/features/local_rides/domain/models/ride_route_plan.dart';
import 'package:my_app_flutter/shared/models/location_model.dart';

void main() {
  const pickup = LocationModel(
    latitude: 12.9716,
    longitude: 77.5946,
    label: 'Central Bengaluru',
  );
  const destination = LocationModel(
    latitude: 12.9756,
    longitude: 77.6064,
    label: 'MG Road',
  );

  test('checkout keeps the backend fare selected for the ride vehicle', () {
    const route = RideRouteOption(
      id: 'value',
      title: 'Best value',
      description: 'Lower price',
      distanceKm: 4.8,
      durationMinutes: 19,
      fareMultiplier: 0.95,
      fareEstimates: <String, double>{'BIKE': 76, 'AUTO': 110, 'CAR': 185},
      points: <RideRoutePoint>[
        RideRoutePoint(latitude: 12.9716, longitude: 77.5946),
        RideRoutePoint(latitude: 12.9756, longitude: 77.6064),
      ],
    );
    const checkout = RideCheckoutDetails(
      pickup: pickup,
      destination: destination,
      route: route,
      vehicle: RideRouteVehicle.auto,
      planSource: RideRouteSource.googleRoutes,
      sourceNotice: 'Live route test data.',
    );

    expect(checkout.estimatedFare, 110);
    expect(checkout.hasBackendFare, isTrue);
    expect(checkout.vehicleLabel, 'Auto');
    expect(checkout.pickup, same(pickup));
    expect(checkout.destination, same(destination));
    expect(checkout.route, same(route));
  });

  test('checkout labels a locally calculated preview fare as estimated', () {
    const route = RideRouteOption(
      id: 'preview',
      title: 'Preview route',
      description: 'Local fallback',
      distanceKm: 4,
      durationMinutes: 10,
      fareMultiplier: 1,
      points: <RideRoutePoint>[
        RideRoutePoint(latitude: 12.9716, longitude: 77.5946),
        RideRoutePoint(latitude: 12.9756, longitude: 77.6064),
      ],
    );
    const checkout = RideCheckoutDetails(
      pickup: pickup,
      destination: destination,
      route: route,
      vehicle: RideRouteVehicle.bike,
      planSource: RideRouteSource.estimatedPreview,
      sourceNotice: 'Estimated route preview.',
    );

    expect(checkout.estimatedFare, 64.5);
    expect(checkout.hasBackendFare, isFalse);
    expect(checkout.vehicleLabel, 'Bike');
  });
}
