import 'package:flutter/foundation.dart';

class PropertyController extends ChangeNotifier {
  String _query = '';
  String? _propertyType;

  String get query => _query;
  String? get propertyType => _propertyType;

  void updateQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void selectPropertyType(String? value) {
    _propertyType = value;
    notifyListeners();
  }
}
