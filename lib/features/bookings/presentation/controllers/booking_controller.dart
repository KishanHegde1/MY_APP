import 'package:flutter/foundation.dart';

class BookingController extends ChangeNotifier {
  String? _selectedBookingId;

  String? get selectedBookingId => _selectedBookingId;

  void selectBooking(String? bookingId) {
    if (_selectedBookingId == bookingId) {
      return;
    }
    _selectedBookingId = bookingId;
    notifyListeners();
  }

  // TODO: Connect booking queries, cancellation, and status updates.
}
