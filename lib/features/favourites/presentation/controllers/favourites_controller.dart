import 'package:flutter/foundation.dart';

class FavouritesController extends ChangeNotifier {
  void refresh() {
    /* TODO: load saved items from the API. */
    notifyListeners();
  }
}
