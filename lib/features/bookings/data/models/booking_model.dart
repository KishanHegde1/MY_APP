import '../../../../shared/models/location_model.dart';

enum BookingStatus { pending, confirmed, active, completed, cancelled }

class BookingModel {
  const BookingModel({
    required this.id,
    required this.rideId,
    required this.serviceType,
    required this.status,
    required this.createdAt,
    required this.vehicleType,
    required this.pickup,
    required this.destination,
    required this.distanceKm,
    required this.durationMinutes,
    required this.estimatedFare,
    required this.currency,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.trackingAvailable,
    required this.trackingMessage,
  });

  final String id;
  final String rideId;
  final String serviceType;
  final BookingStatus status;
  final DateTime createdAt;
  final String vehicleType;
  final LocationModel pickup;
  final LocationModel destination;
  final double distanceKm;
  final int durationMinutes;
  final double estimatedFare;
  final String currency;
  final String paymentMethod;
  final String? paymentStatus;
  final bool trackingAvailable;
  final String trackingMessage;
}
