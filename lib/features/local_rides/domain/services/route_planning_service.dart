import '../../../../shared/models/location_model.dart';
import '../models/ride_route_plan.dart';

abstract interface class RoutePlanningService {
  Future<RideRoutePlan> planRoutes({
    required LocationModel pickup,
    required String destinationQuery,
    required RideRouteVehicle vehicle,
  });
}

abstract interface class DestinationResolver {
  Future<LocationModel?> resolve({required String query, LocationModel? near});
}

final class RoutePlanningException implements Exception {
  const RoutePlanningException(this.message);

  final String message;

  @override
  String toString() => message;
}
