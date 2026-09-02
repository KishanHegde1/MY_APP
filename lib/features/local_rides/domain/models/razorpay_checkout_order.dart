final class RazorpayCheckoutOrder {
  const RazorpayCheckoutOrder({
    required this.bookingId,
    required this.razorpayOrderId,
    required this.amountInPaise,
    required this.currency,
    required this.keyId,
  });

  final String bookingId;
  final String razorpayOrderId;
  final int amountInPaise;
  final String currency;
  final String keyId;
}

final class RazorpayPaymentVerification {
  const RazorpayPaymentVerification({
    required this.bookingId,
    required this.rideId,
    required this.paymentId,
    required this.paymentStatus,
    required this.bookingStatus,
    required this.estimatedFare,
    required this.currency,
  });

  final String bookingId;
  final String rideId;
  final String paymentId;
  final String paymentStatus;
  final String bookingStatus;
  final double estimatedFare;
  final String currency;
}
