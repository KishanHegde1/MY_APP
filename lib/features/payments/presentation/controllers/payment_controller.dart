import 'package:flutter/foundation.dart';

class PaymentController extends ChangeNotifier {
  bool _isProcessing = false;

  bool get isProcessing => _isProcessing;

  void setProcessing(bool value) {
    if (_isProcessing == value) {
      return;
    }
    _isProcessing = value;
    notifyListeners();
  }

  // TODO: Integrate a payment gateway and server-side payment verification.
}
