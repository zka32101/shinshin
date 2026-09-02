/// Utility functions for date and time operations
class DateTimeUtils {
  /// Get the day index (0 = Monday, 6 = Sunday) for a DateTime
  static int getDayIndexOfWeek(DateTime date) {
    return (date.weekday - 1) % 7;
  }

  /// Check if a date is within the last N days
  static bool isWithinLastDays(DateTime date, int days) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    return difference >= 0 && difference < days;
  }

  /// Get the start of the week (Monday) for a given date
  static DateTime getWeekStart(DateTime date) {
    final dayOfWeek = date.weekday;
    final daysToSubtract = dayOfWeek - 1;
    return date.subtract(Duration(days: daysToSubtract));
  }

  /// Get the end of the week (Sunday) for a given date
  static DateTime getWeekEnd(DateTime date) {
    final dayOfWeek = date.weekday;
    final daysToAdd = 7 - dayOfWeek;
    return date.add(Duration(days: daysToAdd));
  }

  /// Calculate the number of days between two dates
  static int daysBetween(DateTime from, DateTime to) {
    return to.difference(from).inDays;
  }

  /// Check if two dates are on the same day
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Get the current hour as an integer (0-23)
  static int getCurrentHour() => DateTime.now().hour;

  /// Check if a date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return isSameDay(date, now);
  }

  /// Check if a date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(date, yesterday);
  }

  /// Format a date difference to a human-readable string
  static String formatDaysDifference(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) return '今日';
    if (difference == 1) return '昨日';
    if (difference < 7) return '$difference日前';
    if (difference < 30) return '${(difference / 7).toStringAsFixed(0)}週前';
    return '${(difference / 30).toStringAsFixed(0)}ヶ月前';
  }
}
