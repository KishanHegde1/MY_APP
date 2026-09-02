import 'package:flutter/widgets.dart';

extension NumX on num {
  SizedBox get horizontalSpace => SizedBox(width: toDouble());
  SizedBox get verticalSpace => SizedBox(height: toDouble());
  Duration get milliseconds => Duration(milliseconds: round());
  Duration get seconds => Duration(seconds: round());
  double clampDouble(num lower, num upper) => clamp(lower, upper).toDouble();
}
