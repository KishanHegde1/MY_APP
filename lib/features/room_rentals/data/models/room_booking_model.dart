class RoomBookingModel {
  const RoomBookingModel({
    required this.id,
    required this.roomId,
    required this.checkIn,
    required this.checkOut,
    required this.status,
  });

  final String id;
  final String roomId;
  final DateTime checkIn;
  final DateTime checkOut;
  final String status;
}
