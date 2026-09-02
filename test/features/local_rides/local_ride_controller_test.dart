import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_app_flutter/core/services/location_service.dart';
import 'package:my_app_flutter/features/local_rides/domain/models/pickup_location_source.dart';
import 'package:my_app_flutter/features/local_rides/presentation/controllers/local_ride_controller.dart';
import 'package:my_app_flutter/shared/models/location_model.dart';

void main() {
  test('choosing a vehicle never requests location', () async {
    final locationService = _DeferredLocationService();
    final controller = LocalRideController(locationService);

    await controller.chooseVehicle(RideVehicleType.bike);

    expect(locationService.requestCount, 0);
    expect(controller.selectedVehicle, RideVehicleType.bike);
    controller.dispose();
  });

  test(
    'a late GPS result cannot overwrite a newer confirmed map pin',
    () async {
      final locationService = _DeferredLocationService();
      final controller = LocalRideController(locationService);
      final gpsRequest = controller.refreshLocation();
      const pin = LocationModel(
        latitude: 12.9279234,
        longitude: 77.6271071,
        label: 'Exact pinned pickup',
      );

      controller.setPickupLocation(pin, source: PickupLocationSource.mapPin);
      locationService.complete(
        const LocationAccessResult.success(
          LocationModel(
            latitude: 12.9716,
            longitude: 77.5946,
            label: 'Late GPS location',
          ),
        ),
      );
      await gpsRequest;

      expect(controller.pickupLocation?.latitude, pin.latitude);
      expect(controller.pickupLocation?.longitude, pin.longitude);
      expect(controller.pickupSource, PickupLocationSource.mapPin);
      controller.dispose();
    },
  );
}

final class _DeferredLocationService implements LocationService {
  final Completer<LocationAccessResult> _request = Completer();
  int requestCount = 0;

  void complete(LocationAccessResult result) => _request.complete(result);

  @override
  Future<LocationAccessResult> requestCurrentLocation() {
    requestCount += 1;
    return _request.future;
  }

  @override
  Future<LocationModel?> currentLocation() async => null;

  @override
  Future<bool> openAppSettings() async => true;

  @override
  Future<bool> openLocationSettings() async => true;
}
