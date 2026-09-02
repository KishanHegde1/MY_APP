class RideRequest {
  const RideRequest({
    required this.id,
    required this.pickupLabel,
    required this.dropLabel,
  });

  final String id;
  final String pickupLabel;
  final String dropLabel;
}
