abstract final class Validators {
  static String? required(
    String? value, {
    String message = 'This field is required.',
  }) {
    return value == null || value.trim().isEmpty ? message : null;
  }

  static String? email(String? value) {
    final requiredError = required(value);
    if (requiredError != null) return requiredError;
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value!.trim())
        ? null
        : 'Enter a valid email address.';
  }

  static String? phone(String? value) {
    final requiredError = required(value);
    if (requiredError != null) return requiredError;
    final normalized = value!.replaceAll(RegExp(r'[\s-]'), '');
    return RegExp(r'^\+?[0-9]{8,15}$').hasMatch(normalized)
        ? null
        : 'Enter a valid phone number.';
  }

  static String? password(String? value, {int minimumLength = 8}) {
    final requiredError = required(value);
    if (requiredError != null) return requiredError;
    return value!.length >= minimumLength
        ? null
        : 'Password must contain at least $minimumLength characters.';
  }
}
