import 'package:flutter/foundation.dart';

class OnboardingController extends ChangeNotifier {
  int _currentPage = 0;
  bool _isComplete = false;

  int get currentPage => _currentPage;
  bool get isComplete => _isComplete;

  void selectPage(int page) {
    if (page < 0 || page == _currentPage) return;
    _currentPage = page;
    notifyListeners();
  }

  void complete() {
    _isComplete = true;
    notifyListeners();
    // TODO: Persist onboarding completion in local storage.
  }
}
