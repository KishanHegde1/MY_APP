import 'dart:math' as math;

import 'package:geocoding/geocoding.dart';

import '../../../../shared/models/location_model.dart';
import '../../domain/models/ride_route_plan.dart';
import '../../domain/services/route_planning_service.dart';

final class DeviceDestinationResolver implements DestinationResolver {
  const DeviceDestinationResolver();

  @override
  Future<LocationModel?> resolve({
    required String query,
    LocationModel? near,
  }) async {
    final coordinate = _coordinateFrom(query);
    if (coordinate != null) return coordinate;

    final nearbyLabel = near?.label?.trim();
    final searchText = nearbyLabel == null || nearbyLabel.isEmpty
        ? query
        : '$query, $nearbyLabel';
    try {
      final matches = await Geocoding().locationFromAddress(searchText);
      if (matches.isEmpty) return null;
      final match = matches.first;
      return LocationModel(
        latitude: match.latitude,
        longitude: match.longitude,
        label: query.trim(),
      );
    } on Exception {
      return null;
    }
  }

  LocationModel? _coordinateFrom(String value) {
    final parts = value.split(',');
    if (parts.length != 2) return null;
    final latitude = double.tryParse(parts.first.trim());
    final longitude = double.tryParse(parts.last.trim());
    if (latitude == null || longitude == null) return null;
    if (latitude < -90 || latitude > 90) return null;
    if (longitude < -180 || longitude > 180) return null;
    return LocationModel(
      latitude: latitude,
      longitude: longitude,
      label: value.trim(),
    );
  }
}

/// Resolves the destination, then creates clearly-labelled estimates.
///
/// The alternatives are not road geometry from Google Routes. This service is
/// intentionally useful before a paid routing provider is configured while
/// keeping that limitation visible to callers and users.
final class EstimatedRoutePlanningService implements RoutePlanningService {
  const EstimatedRoutePlanningService({
    this.destinationResolver = const DeviceDestinationResolver(),
  });

  final DestinationResolver destinationResolver;

  @override
  Future<RideRoutePlan> planRoutes({
    required LocationModel pickup,
    required String destinationQuery,
    required RideRouteVehicle vehicle,
  }) async {
    final query = destinationQuery.trim();
    if (query.length < 3) {
      throw const RoutePlanningException(
        'Enter a destination with at least 3 characters.',
      );
    }

    final destination = await destinationResolver.resolve(
      query: query,
      near: pickup,
    );
    if (destination == null) {
      throw const RoutePlanningException(
        'We could not find that destination. Add the city, area, or landmark '
        'and try again.',
      );
    }

    final directDistance = _haversineKm(pickup, destination);
    final baselineKm = directDistance * 1.22;
    if (baselineKm < 1) {
      throw const RoutePlanningException(
        'Local rides must be at least 1 km. Choose a destination farther away.',
      );
    }
    if (baselineKm > 100) {
      throw const RoutePlanningException(
        'The maximum local ride distance is 100 km. '
        'Choose a destination within 100 km.',
      );
    }
    final routes =
        <RideRouteOption>[
              _option(
                id: 'recommended',
                title: 'Recommended',
                description: 'Balanced time and estimated fare',
                pickup: pickup,
                destination: destination,
                distanceKm: baselineKm,
                averageSpeedKph: 25,
                fareMultiplier: 1,
                bend: 0.08,
                isRecommended: true,
              ),
              _option(
                id: 'fastest',
                title: 'Fastest preview',
                description: 'Shorter estimated travel time',
                pickup: pickup,
                destination: destination,
                distanceKm: baselineKm * 1.06,
                averageSpeedKph: 31,
                fareMultiplier: 1.08,
                bend: -0.13,
              ),
              _option(
                id: 'value',
                title: 'Best value',
                description: 'Lower sample fare, may take longer',
                pickup: pickup,
                destination: destination,
                distanceKm: baselineKm * 1.12,
                averageSpeedKph: 22,
                fareMultiplier: 0.94,
                bend: 0.18,
              ),
            ]
            .where((route) => route.distanceKm >= 1 && route.distanceKm <= 100)
            .toList(growable: false);

    return RideRoutePlan(
      pickup: pickup,
      destination: destination,
      routes: routes,
      source: RideRouteSource.estimatedPreview,
      sourceNotice:
          'Estimated preview only — distances, route shapes, times, and fares '
          'are not live Google Routes data.',
    );
  }

  RideRouteOption _option({
    required String id,
    required String title,
    required String description,
    required LocationModel pickup,
    required LocationModel destination,
    required double distanceKm,
    required double averageSpeedKph,
    required double fareMultiplier,
    required double bend,
    bool isRecommended = false,
  }) {
    final minutes = math.max(
      4,
      (distanceKm / averageSpeedKph * 60 + 3).round(),
    );
    return RideRouteOption(
      id: id,
      title: title,
      description: description,
      distanceKm: distanceKm,
      durationMinutes: minutes,
      fareMultiplier: fareMultiplier,
      points: _illustrativePoints(pickup, destination, bend),
      isRecommended: isRecommended,
    );
  }

  List<RideRoutePoint> _illustrativePoints(
    LocationModel pickup,
    LocationModel destination,
    double bend,
  ) {
    final latitudeDelta = destination.latitude - pickup.latitude;
    final longitudeDelta = destination.longitude - pickup.longitude;
    final controlLatitude =
        (pickup.latitude + destination.latitude) / 2 - longitudeDelta * bend;
    final controlLongitude =
        (pickup.longitude + destination.longitude) / 2 + latitudeDelta * bend;
    return List<RideRoutePoint>.generate(9, (index) {
      final t = index / 8;
      final inverse = 1 - t;
      return RideRoutePoint(
        latitude:
            inverse * inverse * pickup.latitude +
            2 * inverse * t * controlLatitude +
            t * t * destination.latitude,
        longitude:
            inverse * inverse * pickup.longitude +
            2 * inverse * t * controlLongitude +
            t * t * destination.longitude,
      );
    });
  }

  double _haversineKm(LocationModel start, LocationModel end) {
    const earthRadiusKm = 6371.0;
    final latitudeDelta = _radians(end.latitude - start.latitude);
    final longitudeDelta = _radians(end.longitude - start.longitude);
    final startLatitude = _radians(start.latitude);
    final endLatitude = _radians(end.latitude);
    final a =
        math.sin(latitudeDelta / 2) * math.sin(latitudeDelta / 2) +
        math.cos(startLatitude) *
            math.cos(endLatitude) *
            math.sin(longitudeDelta / 2) *
            math.sin(longitudeDelta / 2);
    return earthRadiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _radians(double degrees) => degrees * math.pi / 180;
}
