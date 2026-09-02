import 'package:flutter/foundation.dart';

class HomeController extends ChangeNotifier {
  String? _selectedServiceId;

  String? get selectedServiceId => _selectedServiceId;

  void selectService(String serviceId) {
    if (_selectedServiceId == serviceId) return;
    _selectedServiceId = serviceId;
    notifyListeners();
  }
}
