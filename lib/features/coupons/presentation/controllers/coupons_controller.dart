import 'package:flutter/foundation.dart';

class CouponsController extends ChangeNotifier {
  void refresh() {
    /* TODO: load eligible coupons from the API. */
    notifyListeners();
  }
}
