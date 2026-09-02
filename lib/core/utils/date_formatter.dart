abstract final class DateFormatter {
  static const _months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')} ${_months[value.month - 1]} ${value.year}';

  static String time(DateTime value) {
    final period = value.hour >= 12 ? 'PM' : 'AM';
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    return '$hour:${value.minute.toString().padLeft(2, '0')} $period';
  }

  static String dateTime(DateTime value) => '${date(value)}, ${time(value)}';
}
