class RentalBookingModel {
  const RentalBookingModel({
    required this.id,
    required this.vehicleId,
    required this.startsAt,
    required this.endsAt,
    required this.status,
  });

  final String id;
  final String vehicleId;
  final DateTime startsAt;
  final DateTime endsAt;
  final String status;
}
