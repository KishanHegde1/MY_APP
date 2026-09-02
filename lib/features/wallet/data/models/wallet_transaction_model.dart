enum WalletTransactionType { credit, debit, refund }

class WalletTransactionModel {
  const WalletTransactionModel({
    required this.id,
    required this.amount,
    required this.currency,
    required this.type,
    required this.createdAt,
  });

  final String id;
  final double amount;
  final String currency;
  final WalletTransactionType type;
  final DateTime createdAt;
}
