import 'package:flutter/foundation.dart';

class RoomRentalController extends ChangeNotifier {
  String _query = '';
  bool _isLoading = false;

  String get query => _query;
  bool get isLoading => _isLoading;

  void updateQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void setLoading({required bool value}) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }
}
