class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.label,
    required this.type,
  });

  final String id;
  final String label;
  final String type;
}
