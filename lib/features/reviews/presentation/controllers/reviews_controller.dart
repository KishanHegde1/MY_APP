import 'package:flutter/foundation.dart';

class ReviewsController extends ChangeNotifier {
  int? _draftRating;

  int? get draftRating => _draftRating;

  void setDraftRating(int? value) {
    final int? nextValue;
    if (value == null) {
      nextValue = null;
    } else if (value < 1) {
      nextValue = 1;
    } else if (value > 5) {
      nextValue = 5;
    } else {
      nextValue = value;
    }
    if (_draftRating == nextValue) {
      return;
    }
    _draftRating = nextValue;
    notifyListeners();
  }

  // TODO: Validate completed bookings before review submission.
}
