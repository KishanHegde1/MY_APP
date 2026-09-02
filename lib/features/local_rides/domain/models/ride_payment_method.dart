enum RidePaymentMethod {
  cash('CASH'),
  upi('UPI'),
  card('CARD');

  const RidePaymentMethod(this.apiValue);

  final String apiValue;
}
