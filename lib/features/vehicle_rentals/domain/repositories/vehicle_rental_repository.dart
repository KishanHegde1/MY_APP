import '../../data/models/rental_vehicle_model.dart';

abstract interface class VehicleRentalRepository {
  Future<List<RentalVehicleModel>> getAvailableVehicles();
}
