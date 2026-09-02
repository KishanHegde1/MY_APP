import 'package:flutter/foundation.dart';

class ProviderController extends ChangeNotifier {
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  void setLoading(bool value) {
    if (_isLoading == value) {
      return;
    }
    _isLoading = value;
    notifyListeners();
  }

  // TODO: Connect provider listings, bookings, and earnings repositories.
}
