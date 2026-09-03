import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app_flutter/features/local_rides/domain/models/map_trip_selection.dart';
import 'package:my_app_flutter/features/local_rides/domain/models/pickup_location_source.dart';
import 'package:my_app_flutter/features/local_rides/domain/models/ride_route_plan.dart';
import 'package:my_app_flutter/features/local_rides/domain/repositories/pickup_location_repository.dart';
import 'package:my_app_flutter/features/local_rides/presentation/screens/local_ride_home_screen.dart';
import 'package:my_app_flutter/shared/models/location_model.dart';

void main() {
  testWidgets('uses Google Maps pins instead of the previous location form', (
    tester,
  ) async {
    final pickupRepository = _FakePickupLocationRepository();
    final selection = _mapSelection();
    var mapLaunches = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: LocalRideHomeScreen(
          pickupLocationRepository: pickupRepository,
          enableGoogleMap: false,
          mapTripPlanner: (_, initialPickup, _, _) async {
            mapLaunches += 1;
            expect(initialPickup, isNull);
            return selection;
          },
        ),
      ),
    );

    expect(find.byKey(const Key('pickup-address-field')), findsNothing);
    expect(find.byKey(const Key('destination-field')), findsNothing);
    expect(find.byKey(const Key('pickup-use-gps')), findsNothing);
    expect(find.byKey(const Key('open-google-maps-button')), findsOneWidget);

    final openGoogleMaps = find.byKey(const Key('open-google-maps-button'));
    await tester.ensureVisible(openGoogleMaps);
    await tester.tap(openGoogleMaps);
    await tester.pumpAndSettle();
    expect(mapLaunches, 0);
    expect(
      find.text('Choose Bike, Auto, or Car before planning on the map.'),
      findsOneWidget,
    );

    final riksha = find.text('Riksha').first;
    await tester.ensureVisible(riksha);
    await tester.tap(riksha);
    await tester.pumpAndSettle();
    await tester.ensureVisible(openGoogleMaps);
    await tester.tap(openGoogleMaps);
    await tester.pumpAndSettle();

    expect(mapLaunches, 1);
    expect(pickupRepository.lastLatitude, 12.9279234);
    expect(pickupRepository.lastLongitude, 77.6271071);
    expect(pickupRepository.lastSource, PickupLocationSource.mapPin);
    expect(find.text('Pinned route'), findsOneWidget);
  });

  testWidgets('returns from Google Maps to review the selected ride', (
    tester,
  ) async {
    final selection = _mapSelection();

    await tester.pumpWidget(
      MaterialApp(
        home: LocalRideHomeScreen(
          pickupLocationRepository: _FakePickupLocationRepository(),
          enableGoogleMap: false,
          mapTripPlanner: (_, _, _, _) async => selection,
        ),
      ),
    );

    final car = find.text('Car').first;
    await tester.ensureVisible(car);
    await tester.tap(car);
    await tester.pumpAndSettle();
    final openGoogleMaps = find.byKey(const Key('open-google-maps-button'));
    await tester.ensureVisible(openGoogleMaps);
    await tester.tap(openGoogleMaps);
    await tester.pumpAndSettle();

    final confirmRide = find.byKey(const Key('confirm-ride-button'));
    await tester.ensureVisible(confirmRide);
    await tester.tap(confirmRide);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ride-confirmation-screen')), findsOneWidget);
    expect(find.text('Pinned pickup'), findsWidgets);
    expect(find.text('MG Road'), findsWidgets);
    expect(find.text('3.2 km'), findsWidgets);
  });

  testWidgets('keeps pinned locations and recalculates fare by vehicle', (
    tester,
  ) async {
    var mapLaunches = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: LocalRideHomeScreen(
          pickupLocationRepository: _FakePickupLocationRepository(),
          enableGoogleMap: false,
          mapTripPlanner: (_, _, _, _) async {
            mapLaunches += 1;
            return _mapSelection();
          },
        ),
      ),
    );

    await tester.tap(find.text('Bike').first);
    await tester.pumpAndSettle();
    final openGoogleMaps = find.byKey(const Key('open-google-maps-button'));
    await tester.ensureVisible(openGoogleMaps);
    await tester.tap(openGoogleMaps);
    await tester.pumpAndSettle();
    expect(mapLaunches, 1);

    await tester.tap(find.text('Car').first);
    await tester.pumpAndSettle();
    expect(find.text('Pinned route'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Pinned route, 3.2 kilometres, 12 minutes, 140 rupees',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Riksha').first);
    await tester.pumpAndSettle();
    expect(find.text('Pinned route'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Pinned route, 3.2 kilometres, 12 minutes, 90 rupees',
      ),
      findsOneWidget,
    );
    expect(mapLaunches, 1);
  });
}

MapTripSelection _mapSelection() {
  const pickup = LocationModel(
    latitude: 12.9279234,
    longitude: 77.6271071,
    label: 'Pinned pickup',
  );
  const destination = LocationModel(
    latitude: 12.9716,
    longitude: 77.5946,
    label: 'MG Road',
  );
  const route = RideRouteOption(
    id: 'map-route',
    title: 'Pinned route',
    description: 'Map route',
    distanceKm: 3.2,
    durationMinutes: 12,
    fareMultiplier: 1,
    fareEstimates: <String, double>{'AUTO': 90, 'CAR': 140},
    isRecommended: true,
    points: <RideRoutePoint>[
      RideRoutePoint(latitude: 12.9279234, longitude: 77.6271071),
      RideRoutePoint(latitude: 12.9716, longitude: 77.5946),
    ],
  );
  return MapTripSelection(
    plan: RideRoutePlan(
      pickup: pickup,
      destination: destination,
      source: RideRouteSource.estimatedPreview,
      sourceNotice: 'Map test route.',
      routes: <RideRouteOption>[route],
    ),
    selectedRoute: route,
  );
}

final class _FakePickupLocationRepository implements PickupLocationRepository {
  double? lastLatitude;
  double? lastLongitude;
  PickupLocationSource? lastSource;

  @override
  Future<void> savePickupLocation({
    required double latitude,
    required double longitude,
    required String formattedAddress,
    required PickupLocationSource source,
  }) async {
    lastLatitude = latitude;
    lastLongitude = longitude;
    lastSource = source;
  }
}
