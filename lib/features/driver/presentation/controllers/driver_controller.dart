import 'package:flutter/foundation.dart';

class DriverController extends ChangeNotifier {
  bool _isAvailable = false;

  bool get isAvailable => _isAvailable;

  void setAvailability(bool value) {
    if (_isAvailable == value) {
      return;
    }
    _isAvailable = value;
    notifyListeners();
  }

  // TODO: Connect driver onboarding, matching, and trip repositories.
}
