import 'package:flutter/foundation.dart';

class OutstationController extends ChangeNotifier {
  bool _isRoundTrip = false;
  bool _isLoading = false;

  bool get isRoundTrip => _isRoundTrip;
  bool get isLoading => _isLoading;

  void setRoundTrip({required bool value}) {
    if (_isRoundTrip == value) return;
    _isRoundTrip = value;
    notifyListeners();
  }

  void setLoading({required bool value}) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }
}
