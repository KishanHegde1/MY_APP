final class RideBookingResult {
  const RideBookingResult({
    required this.bookingId,
    required this.rideId,
    required this.status,
    required this.paymentMethod,
    required this.estimatedFare,
    required this.currency,
  });

  final String bookingId;
  final String rideId;
  final String status;
  final String paymentMethod;
  final double estimatedFare;
  final String currency;
}
