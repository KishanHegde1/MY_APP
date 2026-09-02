import 'package:flutter/foundation.dart';

class WalletController extends ChangeNotifier {
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  void setLoading(bool value) {
    if (_isLoading == value) {
      return;
    }
    _isLoading = value;
    notifyListeners();
  }

  // TODO: Load wallet balance and transactions from the backend.
}
