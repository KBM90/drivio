import 'dart:async';

import 'package:intl/intl.dart';

String formatMessageDate(String dateString) {
  // Step 1: Parse the date string into a DateTime object
  // The format from the server is "yyyy-MM-dd HH:mm:ss"
  try {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    final messageDate = dateFormat.parse(dateString);

    // Step 2: Get the current date and time
    final now = DateTime.now();

    // Step 3: Check if the date is today
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(
      messageDate.year,
      messageDate.month,
      messageDate.day,
    );

    if (today == messageDay) {
      // If the date is today, check if it's within the same hour
      final difference = now.difference(messageDate);
      if (difference.inMinutes < 60 && difference.inMinutes >= 0) {
        // If within the same hour, show the difference in minutes
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes} min later';
      } else {
        // If not within the same hour but still today, show "Today H:min"
        return 'Today ${DateFormat('H:mm').format(messageDate)}';
      }
    } else {
      // If the date is before today, show "Month day H:min"
      return DateFormat('MMM d H:mm').format(messageDate);
    }
  } catch (e) {
    // Handle parsing errors
    print('Error parsing date: $e');
    return 'Invalid date';
  }
}

// Helper function to format seconds to MM:SS
String formatCountdown(int seconds) {
  final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
  final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
  return '$minutes:$remainingSeconds';
}
