import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app_flutter/core/services/location_service.dart';
import 'package:my_app_flutter/features/local_rides/domain/models/pickup_location_source.dart';
import 'package:my_app_flutter/features/local_rides/domain/models/map_trip_selection.dart';
import 'package:my_app_flutter/features/local_rides/domain/models/ride_route_plan.dart';
import 'package:my_app_flutter/features/local_rides/domain/repositories/pickup_location_repository.dart';
import 'package:my_app_flutter/features/local_rides/domain/services/route_planning_service.dart';
import 'package:my_app_flutter/features/local_rides/presentation/screens/local_ride_home_screen.dart';
import 'package:my_app_flutter/shared/models/location_model.dart';

void main() {
  testWidgets('vehicle choice does not force GPS and shows pickup options', (
    tester,
  ) async {
    final locationService = _FakeLocationService(
      const LocationAccessResult.success(
        LocationModel(
          latitude: 12.9716,
          longitude: 77.5946,
          label: 'Central Bengaluru',
        ),
      ),
    );
    final pickupRepository = _FakePickupLocationRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: LocalRideHomeScreen(
          locationService: locationService,
          pickupLocationRepository: pickupRepository,
        ),
      ),
    );

    await tester.ensureVisible(find.text('Bike').first);
    await tester.tap(find.text('Bike').first);
    await tester.pumpAndSettle();

    expect(locationService.requestCount, 0);
    expect(find.byKey(const Key('pickup-address-field')), findsOneWidget);
    expect(find.byKey(const Key('pickup-use-gps')), findsOneWidget);
    expect(find.byKey(const Key('pickup-pin-map')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('pickup-use-gps')));
    await tester.tap(find.byKey(const Key('pickup-use-gps')));
    await tester.pumpAndSettle();

    expect(locationService.requestCount, 1);
    expect(pickupRepository.saveCount, 1);
    expect(pickupRepository.lastSource, PickupLocationSource.gps);
    expect(find.text('Central Bengaluru'), findsWidgets);
    expect(find.text('Route choices will appear here'), findsOneWidget);
  });

  testWidgets('asks the user to turn on GPS only after the GPS action', (
    tester,
  ) async {
    final locationService = _FakeLocationService(
      const LocationAccessResult.failure(LocationAccessIssue.serviceDisabled),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LocalRideHomeScreen(
          locationService: locationService,
          pickupLocationRepository: _FakePickupLocationRepository(),
        ),
      ),
    );

    await tester.ensureVisible(find.text('Car').first);
    await tester.tap(find.text('Car').first);
    await tester.pumpAndSettle();
    expect(locationService.requestCount, 0);

    await tester.ensureVisible(find.byKey(const Key('pickup-use-gps')));
    await tester.tap(find.byKey(const Key('pickup-use-gps')));
    await tester.pumpAndSettle();

    expect(locationService.requestCount, 1);
    expect(find.text('Turn on GPS'), findsWidgets);
  });

  testWidgets('compares routes using an explicitly confirmed GPS pickup', (
    tester,
  ) async {
    final locationService = _FakeLocationService(
      const LocationAccessResult.success(
        LocationModel(
          latitude: 12.9716,
          longitude: 77.5946,
          label: 'Central Bengaluru',
        ),
      ),
    );
    final routePlanningService = _FakeRoutePlanningService();

    await tester.pumpWidget(
      MaterialApp(
        home: LocalRideHomeScreen(
          locationService: locationService,
          routePlanningService: routePlanningService,
          pickupLocationRepository: _FakePickupLocationRepository(),
          enableGoogleMap: false,
        ),
      ),
    );

    await tester.ensureVisible(find.text('Bike').first);
    await tester.tap(find.text('Bike').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('pickup-use-gps')));
    await tester.tap(find.byKey(const Key('pickup-use-gps')));
    await tester.pumpAndSettle();

    final destinationField = find.byKey(const Key('destination-field'));
    await tester.ensureVisible(destinationField);
    await tester.enterText(destinationField, 'MG Road');
    final compareButton = find.byKey(const Key('compare-routes-button'));
    await tester.ensureVisible(compareButton);
    await tester.tap(compareButton);
    await tester.pumpAndSettle();

    expect(routePlanningService.requestCount, 1);
    expect(routePlanningService.lastVehicle, RideRouteVehicle.bike);
    expect(find.text('2 route choices'), findsOneWidget);
    expect(find.textContaining('82'), findsWidgets);
    expect(find.byKey(const Key('route-choice-recommended')), findsOneWidget);

    await tester.ensureVisible(find.text('Car').first);
    await tester.tap(find.text('Car').first);
    await tester.pumpAndSettle();

    expect(locationService.requestCount, 1);
    expect(find.text('2 route choices'), findsNothing);
    expect(find.text('Route choices will appear here'), findsOneWidget);
  });

  testWidgets('typed pickup is resolved, saved, and used for routing', (
    tester,
  ) async {
    final locationService = _FakeLocationService(
      const LocationAccessResult.failure(LocationAccessIssue.serviceDisabled),
    );
    const typedPickup = LocationModel(
      latitude: 12.9352,
      longitude: 77.6245,
      label: 'Koramangala, Bengaluru',
    );
    final pickupResolver = _FakeDestinationResolver(typedPickup);
    final pickupRepository = _FakePickupLocationRepository();
    final routePlanningService = _FakeRoutePlanningService();

    await tester.pumpWidget(
      MaterialApp(
        home: LocalRideHomeScreen(
          locationService: locationService,
          routePlanningService: routePlanningService,
          pickupResolver: pickupResolver,
          pickupLocationRepository: pickupRepository,
          enableGoogleMap: false,
        ),
      ),
    );

    await tester.ensureVisible(find.text('Riksha').first);
    await tester.tap(find.text('Riksha').first);
    await tester.pumpAndSettle();
    final pickupField = find.byKey(const Key('pickup-address-field'));
    await tester.ensureVisible(pickupField);
    await tester.enterText(pickupField, 'Koramangala 5th Block');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(locationService.requestCount, 0);
    expect(pickupResolver.calls, 1);
    expect(find.text('Koramangala, Bengaluru'), findsWidgets);
    expect(pickupRepository.lastSource, PickupLocationSource.manual);

    final destinationField = find.byKey(const Key('destination-field'));
    await tester.ensureVisible(destinationField);
    await tester.enterText(destinationField, 'MG Road');
    final compareButton = find.byKey(const Key('compare-routes-button'));
    await tester.ensureVisible(compareButton);
    await tester.tap(compareButton);
    await tester.pumpAndSettle();

    expect(routePlanningService.lastPickup?.latitude, typedPickup.latitude);
    expect(routePlanningService.lastPickup?.longitude, typedPickup.longitude);
    expect(routePlanningService.lastVehicle, RideRouteVehicle.auto);
  });

  testWidgets('confirmed map pin becomes the exact saved pickup', (
    tester,
  ) async {
    const pinnedPickup = LocationModel(
      latitude: 12.9279234,
      longitude: 77.6271071,
      label: 'Pinned pickup',
    );
    final pickupRepository = _FakePickupLocationRepository();
    final locationService = _FakeLocationService(
      const LocationAccessResult.failure(LocationAccessIssue.serviceDisabled),
    );
    const route = RideRouteOption(
      id: 'map-route',
      title: 'Pinned route',
      description: 'Map route',
      distanceKm: 3.2,
      durationMinutes: 12,
      fareMultiplier: 1,
      fareEstimates: <String, double>{'AUTO': 90},
      isRecommended: true,
      points: <RideRoutePoint>[
        RideRoutePoint(latitude: 12.9279234, longitude: 77.6271071),
        RideRoutePoint(latitude: 12.9716, longitude: 77.5946),
      ],
    );
    final selection = MapTripSelection(
      plan: RideRoutePlan(
        pickup: pinnedPickup,
        destination: LocationModel(
          latitude: 12.9716,
          longitude: 77.5946,
          label: 'MG Road',
        ),
        source: RideRouteSource.estimatedPreview,
        sourceNotice: 'Map test route.',
        routes: <RideRouteOption>[route],
      ),
      selectedRoute: route,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LocalRideHomeScreen(
          locationService: locationService,
          pickupLocationRepository: pickupRepository,
          mapTripPlanner: (_, _, _, _) async => selection,
          enableGoogleMap: false,
        ),
      ),
    );

    await tester.ensureVisible(find.text('Riksha').first);
    await tester.tap(find.text('Riksha').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('pickup-pin-map')));
    await tester.tap(find.byKey(const Key('pickup-pin-map')));
    await tester.pumpAndSettle();

    expect(locationService.requestCount, 0);
    expect(pickupRepository.lastLatitude, pinnedPickup.latitude);
    expect(pickupRepository.lastLongitude, pinnedPickup.longitude);
    expect(pickupRepository.lastSource, PickupLocationSource.mapPin);
    expect(find.text('Pinned pickup'), findsWidgets);
  });

  testWidgets(
    'selected route is reviewed before payment without creating a fake booking',
    (tester) async {
      final locationService = _FakeLocationService(
        const LocationAccessResult.success(
          LocationModel(
            latitude: 12.9716,
            longitude: 77.5946,
            label: 'Central Bengaluru',
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: LocalRideHomeScreen(
            locationService: locationService,
            routePlanningService: _FakeRoutePlanningService(),
            pickupLocationRepository: _FakePickupLocationRepository(),
            enableGoogleMap: false,
          ),
        ),
      );

      await tester.ensureVisible(find.text('Riksha').first);
      await tester.tap(find.text('Riksha').first);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('pickup-use-gps')));
      await tester.tap(find.byKey(const Key('pickup-use-gps')));
      await tester.pumpAndSettle();

      final destinationField = find.byKey(const Key('destination-field'));
      await tester.ensureVisible(destinationField);
      await tester.enterText(destinationField, 'MG Road');
      final compareButton = find.byKey(const Key('compare-routes-button'));
      await tester.ensureVisible(compareButton);
      await tester.tap(compareButton);
      await tester.pumpAndSettle();

      final valueRoute = find.byKey(const Key('route-choice-value'));
      await tester.ensureVisible(valueRoute);
      await tester.tap(valueRoute);
      await tester.pumpAndSettle();

      final confirmRide = find.byKey(const Key('confirm-ride-button'));
      await tester.ensureVisible(confirmRide);
      await tester.tap(confirmRide);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('ride-confirmation-screen')), findsOneWidget);
      expect(find.text('Central Bengaluru'), findsWidgets);
      expect(find.text('MG Road'), findsWidgets);
      expect(find.text('Best value'), findsWidgets);
      expect(find.text('4.8 km'), findsWidgets);
      expect(find.text('19 min'), findsWidgets);
      expect(find.textContaining('110'), findsWidgets);

      final continueToPayment = find.byKey(
        const Key('continue-to-payment-button'),
      );
      await tester.ensureVisible(continueToPayment);
      await tester.tap(continueToPayment);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('ride-payment-screen')), findsOneWidget);
      expect(find.byKey(const Key('payment-method-cash')), findsOneWidget);
      expect(find.byKey(const Key('payment-method-upi')), findsOneWidget);
      expect(find.byKey(const Key('payment-method-card')), findsOneWidget);
      expect(find.textContaining('110'), findsWidgets);

      final upiMethod = find.byKey(const Key('payment-method-upi'));
      await tester.ensureVisible(upiMethod);
      await tester.tap(upiMethod);
      await tester.pumpAndSettle();

      final paymentButton = find.byKey(const Key('pay-and-confirm-button'));
      await tester.ensureVisible(paymentButton);
      await tester.tap(paymentButton);
      await tester.pumpAndSettle();

      expect(find.textContaining('Sign in before booking'), findsOneWidget);
      expect(find.textContaining('Ride confirmed'), findsNothing);
      expect(find.textContaining('Searching for your driver'), findsNothing);
    },
  );
}

final class _FakeLocationService implements LocationService {
  _FakeLocationService(this.result);

  final LocationAccessResult result;
  int requestCount = 0;

  @override
  Future<LocationAccessResult> requestCurrentLocation() async {
    requestCount += 1;
    return result;
  }

  @override
  Future<LocationModel?> currentLocation() async => result.location;

  @override
  Future<bool> openAppSettings() async => true;

  @override
  Future<bool> openLocationSettings() async => true;
}

final class _FakeRoutePlanningService implements RoutePlanningService {
  int requestCount = 0;
  RideRouteVehicle? lastVehicle;
  LocationModel? lastPickup;

  @override
  Future<RideRoutePlan> planRoutes({
    required LocationModel pickup,
    required String destinationQuery,
    required RideRouteVehicle vehicle,
  }) async {
    requestCount += 1;
    lastVehicle = vehicle;
    lastPickup = pickup;
    const destination = LocationModel(
      latitude: 12.9756,
      longitude: 77.6064,
      label: 'MG Road',
    );
    return RideRoutePlan(
      pickup: pickup,
      destination: destination,
      source: RideRouteSource.googleRoutes,
      sourceNotice: 'Live route test data.',
      routes: const <RideRouteOption>[
        RideRouteOption(
          id: 'recommended',
          title: 'Recommended',
          description: 'Balanced route',
          distanceKm: 4.2,
          durationMinutes: 16,
          fareMultiplier: 1,
          fareEstimates: <String, double>{'BIKE': 82, 'AUTO': 120},
          isRecommended: true,
          points: <RideRoutePoint>[
            RideRoutePoint(latitude: 12.9716, longitude: 77.5946),
            RideRoutePoint(latitude: 12.9756, longitude: 77.6064),
          ],
        ),
        RideRouteOption(
          id: 'value',
          title: 'Best value',
          description: 'Lower price',
          distanceKm: 4.8,
          durationMinutes: 19,
          fareMultiplier: 0.95,
          fareEstimates: <String, double>{'BIKE': 76, 'AUTO': 110},
          points: <RideRoutePoint>[
            RideRoutePoint(latitude: 12.9716, longitude: 77.5946),
            RideRoutePoint(latitude: 12.9756, longitude: 77.6064),
          ],
        ),
      ],
    );
  }
}

final class _FakeDestinationResolver implements DestinationResolver {
  _FakeDestinationResolver(this.result);

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

final class _FakePickupLocationRepository implements PickupLocationRepository {
  int saveCount = 0;
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
    saveCount += 1;
    lastLatitude = latitude;
    lastLongitude = longitude;
    lastSource = source;
  }
}
