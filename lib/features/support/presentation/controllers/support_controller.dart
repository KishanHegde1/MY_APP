import 'package:flutter/foundation.dart';

class SupportController extends ChangeNotifier {
  bool _isSubmitting = false;

  bool get isSubmitting => _isSubmitting;

  void setSubmitting(bool value) {
    if (_isSubmitting == value) {
      return;
    }
    _isSubmitting = value;
    notifyListeners();
  }

  // TODO: Connect support topics and ticket submission to the backend.
}
