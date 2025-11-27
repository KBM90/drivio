import 'package:intl/intl.dart';

class DateTimeHelper {
  static String formatDate(String? dateString) {
    if (dateString == null) return '';
    final date = DateTime.parse(dateString).toLocal();
    final now = DateTime.now();

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      // Today: 3:00 PM
      return DateFormat.jm().format(date);
    } else if (date.year == now.year) {
      // This year: Mar 4, 3:00 PM
      return DateFormat('MMM d, h:mm a').format(date);
    } else {
      // Other years: Mar 4, 2023, 3:00 PM
      return DateFormat('MMM d, y, h:mm a').format(date);
    }
  }
}
