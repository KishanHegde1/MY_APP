import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../shared/models/location_model.dart';

enum LocationAccessIssue {
  serviceDisabled,
  permissionDenied,
  permissionPermanentlyDenied,
  positionUnavailable,
}

final class LocationAccessResult {
  const LocationAccessResult.success(this.location) : issue = null;

  const LocationAccessResult.failure(this.issue) : location = null;

  final LocationModel? location;
  final LocationAccessIssue? issue;

  bool get isSuccess => location != null;
}

abstract interface class LocationService {
  Future<LocationAccessResult> requestCurrentLocation();
  Future<LocationModel?> currentLocation();
  Future<bool> openLocationSettings();
  Future<bool> openAppSettings();
}

final class PlaceholderLocationService implements LocationService {
  const PlaceholderLocationService();

  @override
  Future<LocationAccessResult> requestCurrentLocation() async =>
      const LocationAccessResult.failure(
        LocationAccessIssue.positionUnavailable,
      );

  @override
  Future<LocationModel?> currentLocation() async => null;

  @override
  Future<bool> openLocationSettings() async => false;

  @override
  Future<bool> openAppSettings() async => false;
}

final class DeviceLocationService implements LocationService {
  const DeviceLocationService();

  @override
  Future<LocationModel?> currentLocation() async {
    final result = await requestCurrentLocation();
    return result.location;
  }

  @override
  Future<LocationAccessResult> requestCurrentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationAccessResult.failure(
          LocationAccessIssue.serviceDisabled,
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        return const LocationAccessResult.failure(
          LocationAccessIssue.permissionDenied,
        );
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationAccessResult.failure(
          LocationAccessIssue.permissionPermanentlyDenied,
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      final label = await _locationLabel(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      return LocationAccessResult.success(
        LocationModel(
          latitude: position.latitude,
          longitude: position.longitude,
          label: label,
        ),
      );
    } on Exception {
      return const LocationAccessResult.failure(
        LocationAccessIssue.positionUnavailable,
      );
    }
  }

  @override
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  @override
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  Future<String?> _locationLabel({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final placemarks = await Geocoding().placemarkFromCoordinates(
        latitude,
        longitude,
      );
      if (placemarks.isEmpty) return null;

      final place = placemarks.first;
      final parts = <String?>[
        place.subLocality,
        place.locality,
        place.administrativeArea,
      ];
      final uniqueParts = <String>[];
      for (final part in parts) {
        final value = part?.trim();
        if (value != null && value.isNotEmpty && !uniqueParts.contains(value)) {
          uniqueParts.add(value);
        }
      }
      return uniqueParts.take(2).join(', ').trim().isEmpty
          ? null
          : uniqueParts.take(2).join(', ');
    } on Exception {
      return null;
    }
  }
}
