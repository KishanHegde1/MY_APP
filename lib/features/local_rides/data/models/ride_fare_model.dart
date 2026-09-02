class RideFareModel {
  const RideFareModel({
    required this.amount,
    required this.currencyCode,
    required this.distanceKm,
  });

  final double amount;
  final String currencyCode;
  final double distanceKm;
}
