import 'package:flutter/foundation.dart';

class ProfileController extends ChangeNotifier {
  bool _isEditing = false;

  bool get isEditing => _isEditing;

  void setEditing(bool value) {
    if (_isEditing == value) {
      return;
    }
    _isEditing = value;
    notifyListeners();
  }

  // TODO: Connect profile, address, and account repositories.
}
