import 'package:flutter/foundation.dart';

class AuthController extends ChangeNotifier {
  bool _isSubmitting = false;
  String? _errorMessage;

  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  void beginSubmission() {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();
  }

  void finishSubmission({String? errorMessage}) {
    _isSubmitting = false;
    _errorMessage = errorMessage;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }
}
