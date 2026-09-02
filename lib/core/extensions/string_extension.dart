extension StringX on String {
  bool get isBlank => trim().isEmpty;
  String get capitalized =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
  String get titleCase => trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .map((word) => word.toLowerCase().capitalized)
      .join(' ');
  String? get nullIfBlank => isBlank ? null : trim();
  bool get looksLikeEmail =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(trim());
  bool get looksLikePhone =>
      RegExp(r'^\+?[0-9]{8,15}$').hasMatch(replaceAll(RegExp(r'[\s-]'), ''));
}
