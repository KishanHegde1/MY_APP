import 'package:flutter/foundation.dart';

class NotificationsController extends ChangeNotifier {
  int _unreadCount = 0;

  int get unreadCount => _unreadCount;

  void updateUnreadCount(int value) {
    final nextValue = value < 0 ? 0 : value;
    if (_unreadCount == nextValue) {
      return;
    }
    _unreadCount = nextValue;
    notifyListeners();
  }

  // TODO: Connect push registration and notification history.
}
