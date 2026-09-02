import 'ride_route_plan.dart';

/// A route explicitly confirmed from the two-pin map trip planner.
///
/// This only contains route and fare estimates. A booking is created later
/// after the user reviews the trip and selects a payment method.
final class MapTripSelection {
  const MapTripSelection({required this.plan, required this.selectedRoute});

  final RideRoutePlan plan;
  final RideRouteOption selectedRoute;
}
