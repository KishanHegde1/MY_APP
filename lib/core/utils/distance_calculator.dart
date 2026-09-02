import 'dart:math' as math;

abstract final class DistanceCalculator {
  static const double localRideLimitKm = 20;
  static const double _earthRadiusKm = 6371;

  static double betweenInKilometres({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    final latitudeDelta = _radians(endLatitude - startLatitude);
    final longitudeDelta = _radians(endLongitude - startLongitude);
    final startLatitudeRadians = _radians(startLatitude);
    final endLatitudeRadians = _radians(endLatitude);
    final a =
        math.sin(latitudeDelta / 2) * math.sin(latitudeDelta / 2) +
        math.cos(startLatitudeRadians) *
            math.cos(endLatitudeRadians) *
            math.sin(longitudeDelta / 2) *
            math.sin(longitudeDelta / 2);
    return _earthRadiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static bool isWithinLocalRideLimit(double distanceKm) =>
      distanceKm <= localRideLimitKm;

  static double _radians(double degrees) => degrees * math.pi / 180;
}
