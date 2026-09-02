enum PaymentStatus { pending, authorized, paid, failed, refunded }

class PaymentModel {
  const PaymentModel({
    required this.id,
    required this.bookingId,
    required this.amount,
    required this.currency,
    required this.status,
  });

  final String id;
  final String bookingId;
  final double amount;
  final String currency;
  final PaymentStatus status;
}
