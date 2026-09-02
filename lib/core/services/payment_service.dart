enum PaymentStatus { pending, successful, failed, cancelled }

final class PaymentRequest {
  const PaymentRequest({
    required this.referenceId,
    required this.amount,
    required this.currency,
  });
  final String referenceId;
  final num amount;
  final String currency;
}

final class PaymentResult {
  const PaymentResult({required this.status, this.transactionId, this.message});
  final PaymentStatus status;
  final String? transactionId;
  final String? message;
}

abstract interface class PaymentService {
  Future<PaymentResult> pay(PaymentRequest request);
}

final class PlaceholderPaymentService implements PaymentService {
  const PlaceholderPaymentService();

  @override
  Future<PaymentResult> pay(PaymentRequest request) async =>
      const PaymentResult(
        status: PaymentStatus.failed,
        message: 'Payment provider is not configured.',
      );
}
