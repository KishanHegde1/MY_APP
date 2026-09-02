import '../models/pickup_location_source.dart';

abstract interface class PickupLocationRepository {
  Future<void> savePickupLocation({
    required double latitude,
    required double longitude,
    required String formattedAddress,
    required PickupLocationSource source,
  });
}

enum PickupLocationPersistenceFailure {
  authenticationRequired,
  invalidLocation,
  networkUnavailable,
  saveRejected,
}

final class PickupLocationPersistenceException implements Exception {
  const PickupLocationPersistenceException(this.failure, this.message);

  final PickupLocationPersistenceFailure failure;
  final String message;

  @override
  String toString() => message;
}
