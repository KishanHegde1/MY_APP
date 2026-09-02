enum BookingStatus { pending, confirmed, active, completed, cancelled }

class BookingModel {
  const BookingModel({
    required this.id,
    required this.serviceType,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String serviceType;
  final BookingStatus status;
  final DateTime createdAt;
}
