import 'package:flutter/foundation.dart';

class VehicleRentalController extends ChangeNotifier {
  String? _selectedCategory;
  DateTimeRangeValue? _selectedPeriod;

  String? get selectedCategory => _selectedCategory;
  DateTimeRangeValue? get selectedPeriod => _selectedPeriod;

  void selectCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void selectPeriod({required DateTime start, required DateTime end}) {
    _selectedPeriod = DateTimeRangeValue(start: start, end: end);
    notifyListeners();
  }
}

class DateTimeRangeValue {
  const DateTimeRangeValue({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}
