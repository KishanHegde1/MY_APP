import '../models/local_ride_model.dart';
import '../models/ride_fare_model.dart';

class LocalRideRemoteDataSource {
  const LocalRideRemoteDataSource();

  Future<List<LocalRideModel>> getRides() async {
    // TODO: Fetch the customer's ride history from the backend.
    return const <LocalRideModel>[];
  }

  Future<RideFareModel?> estimateFare({
    required String pickupAddress,
    required String dropOffAddress,
  }) async {
    // TODO: Request fare options and enforce the 1–100 km local ride range.
    return null;
  }
}
