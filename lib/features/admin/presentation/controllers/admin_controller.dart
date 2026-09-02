import 'package:flutter/foundation.dart';

class AdminController extends ChangeNotifier {
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  void setLoading(bool value) {
    if (_isLoading == value) {
      return;
    }
    _isLoading = value;
    notifyListeners();
  }

  // TODO: Enforce admin authorization before loading operational data.
}
