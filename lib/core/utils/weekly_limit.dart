/// Helpers for the per-weekday screen time schedule.
///
/// Weekday keys are [DateTime.weekday] values: 1 = Monday … 7 = Sunday, so a
/// schedule can be indexed directly with `DateTime.now().weekday`. The Kotlin
/// layer uses `Calendar.DAY_OF_WEEK`, whose numbering matches.
abstract final class WeeklyLimit {
  /// Monday → Sunday, in display order.
  static const List<int> order = [1, 2, 3, 4, 5, 6, 7];

  static const Map<int, String> _fullNames = {
    DateTime.monday: 'Monday',
    DateTime.tuesday: 'Tuesday',
    DateTime.wednesday: 'Wednesday',
    DateTime.thursday: 'Thursday',
    DateTime.friday: 'Friday',
    DateTime.saturday: 'Saturday',
    DateTime.sunday: 'Sunday',
  };

  static const Map<int, String> _shortNames = {
    DateTime.monday: 'Mon',
    DateTime.tuesday: 'Tue',
    DateTime.wednesday: 'Wed',
    DateTime.thursday: 'Thu',
    DateTime.friday: 'Fri',
    DateTime.saturday: 'Sat',
    DateTime.sunday: 'Sun',
  };

  /// Full label for a [DateTime.weekday] value, falling back to `''`.
  static String weekdayLabel(int weekday, {bool short = false}) {
    final names = short ? _shortNames : _fullNames;
    return names[weekday] ?? '';
  }

  /// One-line summary of a schedule for list tiles.
  static String describe(Map<int, int> weeklyLimits, int globalMinutes) {
    if (weeklyLimits.isEmpty) return 'Same limit every day';

    final scheduled = order
        .where(weeklyLimits.containsKey)
        .map((day) => '${weekdayLabel(day, short: true)} ${weeklyLimits[day]}m')
        .toList();
    final remaining = order.length - scheduled.length;

    if (remaining == 0) return scheduled.join(' · ');
    return '${scheduled.join(' · ')} · global on $remaining '
        '${remaining == 1 ? 'day' : 'days'}';
  }

  /// What today's limit is, phrased for the schedule tile badge.
  static String describeToday(Map<int, int> weeklyLimits, int globalMinutes) {
    if (weeklyLimits.isEmpty) {
      return globalMinutes > 0
          ? 'Today: Global ${globalMinutes}m'
          : 'Today: Unlimited';
    }
    if (!weeklyLimits.containsKey(DateTime.now().weekday)) {
      return globalMinutes > 0
          ? 'Today: Global ${globalMinutes}m'
          : 'Today: Unlimited';
    }
    final minutes = weeklyLimits[DateTime.now().weekday]!;
    return minutes > 0 ? 'Today: ${minutes}m' : 'Today: Unlimited';
  }
}
