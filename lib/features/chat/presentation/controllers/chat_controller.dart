import 'package:flutter/foundation.dart';

class ChatController extends ChangeNotifier {
  String? _activeRoomId;

  String? get activeRoomId => _activeRoomId;

  void openRoom(String? roomId) {
    if (_activeRoomId == roomId) {
      return;
    }
    _activeRoomId = roomId;
    notifyListeners();
  }

  // TODO: Connect authenticated real-time messaging and message persistence.
}
