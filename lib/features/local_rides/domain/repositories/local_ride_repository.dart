import '../../data/models/local_ride_model.dart';
import '../../data/models/ride_fare_model.dart';

abstract interface class LocalRideRepository {
  Future<List<LocalRideModel>> getRides();

  Future<RideFareModel?> estimateFare({
    required String pickupAddress,
    required String dropOffAddress,
  });
}
