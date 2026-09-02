import 'package:flutter/foundation.dart';

/// Coordinates future app-start and session restoration work.
class SplashController extends ChangeNotifier {
  bool _isInitializing = false;

  bool get isInitializing => _isInitializing;

  Future<void> initialize() async {
    _isInitializing = true;
    notifyListeners();

    // TODO: Restore the session and load startup configuration.
    await Future<void>.value();

    _isInitializing = false;
    notifyListeners();
  }
}
