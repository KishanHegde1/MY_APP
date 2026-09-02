import '../../domain/repositories/local_ride_repository.dart';
import '../datasources/local_ride_remote_data_source.dart';
import '../models/local_ride_model.dart';
import '../models/ride_fare_model.dart';

class LocalRideRepositoryImpl implements LocalRideRepository {
  const LocalRideRepositoryImpl(this._remoteDataSource);

  final LocalRideRemoteDataSource _remoteDataSource;

  @override
  Future<List<LocalRideModel>> getRides() => _remoteDataSource.getRides();

  @override
  Future<RideFareModel?> estimateFare({
    required String pickupAddress,
    required String dropOffAddress,
  }) {
    return _remoteDataSource.estimateFare(
      pickupAddress: pickupAddress,
      dropOffAddress: dropOffAddress,
    );
  }
}
