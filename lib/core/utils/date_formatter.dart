import 'package:intl/intl.dart' show DateFormat;

/// Date and time formatting helpers.
///
/// Centralizes all date/time display formatting to prevent
/// duplication and ensure consistent output across the app.
abstract final class DateFormatter {
  /// Formats a [Duration] as "Xh Ym" (e.g. "2h 15m").
  ///
  /// If the duration is less than 1 hour, returns "Xm" (e.g. "45m").
  /// If the duration is zero, returns "0m".
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h';
    return '${minutes}m';
  }

  /// Formats a [Duration] as "X hours Y minutes" (verbose).
  static String formatDurationVerbose(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    final parts = <String>[];
    if (hours > 0) parts.add('$hours hour${hours > 1 ? 's' : ''}');
    if (minutes > 0) parts.add('$minutes minute${minutes > 1 ? 's' : ''}');

    return parts.isEmpty ? '0 minutes' : parts.join(' ');
  }

  /// Formats a [DateTime] as "Aug 23, 2026".
  static String formatDate(DateTime date) {
    return DateFormat('MMM d, y').format(date);
  }

  /// Formats a [DateTime] as "12:30 PM".
  static String formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }

  /// Returns "Today", "Yesterday", or the formatted date.
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final difference = today.difference(target).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    return formatDate(date);
  }
}
