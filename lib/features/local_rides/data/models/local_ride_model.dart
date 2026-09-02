class LocalRideModel {
  const LocalRideModel({
    required this.id,
    required this.pickupAddress,
    required this.dropOffAddress,
    required this.status,
  });

  final String id;
  final String pickupAddress;
  final String dropOffAddress;
  final String status;
}
