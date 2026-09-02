import '../../../../shared/models/location_model.dart';
import 'ride_route_plan.dart';

/// Immutable trip details handed from route selection to confirmation/payment.
///
/// This is a preview model only. It intentionally contains no booking or
/// payment status because those states must come from verified backend APIs.
final class RideCheckoutDetails {
  const RideCheckoutDetails({
    required this.pickup,
    required this.destination,
    required this.route,
    required this.vehicle,
    required this.planSource,
    required this.sourceNotice,
  });

  final LocationModel pickup;
  final LocationModel destination;
  final RideRouteOption route;
  final RideRouteVehicle vehicle;
  final RideRouteSource planSource;
  final String sourceNotice;

  double get estimatedFare => calculateRideFare(route, vehicle);

  bool get hasBackendFare => route.fareFor(vehicle.apiValue) != null;

  String get vehicleLabel => switch (vehicle) {
    RideRouteVehicle.bike => 'Bike',
    RideRouteVehicle.auto => 'Auto',
    RideRouteVehicle.car => 'Car',
  };
}

double calculateRideFare(RideRouteOption route, RideRouteVehicle vehicle) {
  final backendFare = route.fareFor(vehicle.apiValue);
  if (backendFare != null) return backendFare;

  final (base, perKm, perMinute) = switch (vehicle) {
    RideRouteVehicle.bike => (28.0, 8.0, 0.45),
    RideRouteVehicle.auto => (42.0, 13.0, 0.7),
    RideRouteVehicle.car => (70.0, 19.0, 0.95),
  };
  return (base + route.distanceKm * perKm + route.durationMinutes * perMinute) *
      route.fareMultiplier;
}
