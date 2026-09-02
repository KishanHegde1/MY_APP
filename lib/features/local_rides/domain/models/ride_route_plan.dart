import '../../../../shared/models/location_model.dart';

enum RideRouteSource { googleRoutes, estimatedPreview }

enum RideRouteVehicle {
  bike('BIKE'),
  auto('AUTO'),
  car('CAR');

  const RideRouteVehicle(this.apiValue);

  final String apiValue;
}

final class RideRoutePoint {
  const RideRoutePoint({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

final class RideRouteOption {
  const RideRouteOption({
    required this.id,
    required this.title,
    required this.description,
    required this.distanceKm,
    required this.durationMinutes,
    required this.fareMultiplier,
    required this.points,
    this.fareEstimates = const <String, double>{},
    this.encodedPolyline,
    this.isRecommended = false,
  }) : assert(distanceKm > 0),
       assert(durationMinutes > 0),
       assert(fareMultiplier > 0);

  final String id;
  final String title;
  final String description;
  final double distanceKm;
  final int durationMinutes;
  final double fareMultiplier;
  final List<RideRoutePoint> points;
  final Map<String, double> fareEstimates;
  final String? encodedPolyline;
  final bool isRecommended;

  double? fareFor(String vehicleName) =>
      fareEstimates[vehicleName.toUpperCase()];
}

final class RideRoutePlan {
  RideRoutePlan({
    required this.pickup,
    required this.destination,
    required List<RideRouteOption> routes,
    required this.source,
    required this.sourceNotice,
  }) : routes = List.unmodifiable(routes),
       assert(routes.isNotEmpty);

  final LocationModel pickup;
  final LocationModel destination;
  final List<RideRouteOption> routes;
  final RideRouteSource source;
  final String sourceNotice;
}
