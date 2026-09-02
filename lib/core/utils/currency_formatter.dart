abstract final class CurrencyFormatter {
  static String format(
    num amount, {
    String symbol = '₹',
    int decimalDigits = 2,
  }) => '$symbol${amount.toStringAsFixed(decimalDigits)}';
}
