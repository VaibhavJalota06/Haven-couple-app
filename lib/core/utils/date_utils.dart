import 'package:intl/intl.dart';

class HavenDateUtils {
  /// Calculates number of days together since anniversary / start date
  static int calculateDaysTogether(DateTime startDate) {
    final now = DateTime.now();
    final difference = now.difference(startDate);
    return difference.inDays >= 0 ? difference.inDays : 0;
  }

  /// Calculates upcoming anniversary and remaining days
  static ({DateTime nextDate, int daysRemaining, int yearsCount}) calculateNextAnniversary(DateTime startDate) {
    final now = DateTime.now();
    DateTime nextAnniversary = DateTime(now.year, startDate.month, startDate.day);
    
    if (nextAnniversary.isBefore(now)) {
      nextAnniversary = DateTime(now.year + 1, startDate.month, startDate.day);
    }
    
    final daysRemaining = nextAnniversary.difference(now).inDays + 1;
    final yearsCount = nextAnniversary.year - startDate.year;

    return (
      nextDate: nextAnniversary,
      daysRemaining: daysRemaining,
      yearsCount: yearsCount,
    );
  }

  /// Formats message timestamp (e.g., "10:42 AM", "Yesterday", "Oct 14")
  static String formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return DateFormat('h:mm a').format(dateTime);
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else if (now.difference(dateTime).inDays < 7) {
      return DateFormat('EEEE').format(dateTime);
    } else {
      return DateFormat('MMM d, y').format(dateTime);
    }
  }

  /// Formats date for plans & memories
  static String formatFullDate(DateTime dateTime) {
    return DateFormat('MMMM d, yyyy').format(dateTime);
  }

  /// Formats time duration for audio/video calls (e.g. "04:15" or "1:02:40")
  static String formatDuration(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}
