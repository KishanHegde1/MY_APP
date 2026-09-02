import '../../domain/repositories/vehicle_rental_repository.dart';
import '../models/rental_vehicle_model.dart';

class VehicleRentalRepositoryImpl implements VehicleRentalRepository {
  const VehicleRentalRepositoryImpl();

  @override
  Future<List<RentalVehicleModel>> getAvailableVehicles() async {
    // TODO: Load available rental vehicles from the backend.
    return const <RentalVehicleModel>[];
  }
}
