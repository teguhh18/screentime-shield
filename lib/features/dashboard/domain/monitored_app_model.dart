import 'package:equatable/equatable.dart';

/// Supported restriction lock modes.
abstract final class LockMode {
  static const String hardLock = 'hardLock';
  static const String snoozeAlarm = 'snoozeAlarm';
}

/// Represents an installed app with its screen time configuration.
///
/// Limits are resolved in this order:
///   1. [weeklyLimits] entry for today's weekday (0 = unlimited that day)
///   2. [timeLimitMinutes] global fallback when today has no entry
class MonitoredApp extends Equatable {
  final String packageName;
  final String appName;
  final String iconBase64;
  final int timeLimitMinutes;
  final int usageTimeMs;
  final bool isMonitored;
  final String lockMode;

  /// Per-weekday limits in minutes, keyed by [DateTime.weekday] (1 = Monday).
  /// A missing key means "fall back to [timeLimitMinutes]".
  final Map<int, int> weeklyLimits;

  const MonitoredApp({
    required this.packageName,
    required this.appName,
    this.iconBase64 = '',
    this.timeLimitMinutes = 0,
    this.usageTimeMs = 0,
    this.isMonitored = false,
    this.lockMode = LockMode.hardLock,
    this.weeklyLimits = const {},
  });

  /// True when this app should be sent to the native monitor at all: either a
  /// global limit is set, or a weekly schedule exists (which may be the only
  /// thing configured).
  bool get isActive => isMonitored || weeklyLimits.isNotEmpty;

  /// Limit in effect for today, in minutes. 0 means unlimited.
  int get todayLimitMinutes =>
      weeklyLimits[DateTime.now().weekday] ?? timeLimitMinutes;

  bool get isLimitExceeded {
    if (!isActive) return false;
    final limit = todayLimitMinutes;
    return limit > 0 && usageTimeMs >= (limit * 60 * 1000);
  }

  MonitoredApp copyWith({
    String? packageName,
    String? appName,
    String? iconBase64,
    int? timeLimitMinutes,
    int? usageTimeMs,
    bool? isMonitored,
    String? lockMode,
    Map<int, int>? weeklyLimits,
  }) {
    return MonitoredApp(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      iconBase64: iconBase64 ?? this.iconBase64,
      timeLimitMinutes: timeLimitMinutes ?? this.timeLimitMinutes,
      usageTimeMs: usageTimeMs ?? this.usageTimeMs,
      isMonitored: isMonitored ?? this.isMonitored,
      lockMode: lockMode ?? this.lockMode,
      weeklyLimits: weeklyLimits ?? this.weeklyLimits,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'packageName': packageName,
      'appName': appName,
      'timeLimitMinutes': timeLimitMinutes,
      'timeLimitMs': timeLimitMinutes * 60 * 1000,
      'isMonitored': isMonitored,
      'lockMode': lockMode,
      // JSON object keys must be strings: {"1": 60, "2": 120}
      'weeklyLimits': weeklyLimits.map((day, m) => MapEntry('$day', m)),
    };
  }

  factory MonitoredApp.fromMap(
    Map<String, dynamic> map, {
    required String appName,
    required String iconBase64,
    required int usageTimeMs,
  }) {
    return MonitoredApp(
      packageName: map['packageName'] as String? ?? '',
      appName: appName,
      iconBase64: iconBase64,
      timeLimitMinutes: (map['timeLimitMinutes'] as num?)?.toInt() ?? 0,
      usageTimeMs: usageTimeMs,
      isMonitored: map['isMonitored'] as bool? ?? false,
      lockMode: map['lockMode'] as String? ?? LockMode.hardLock,
      // Tolerates pre-schedule payloads where the key is absent entirely.
      weeklyLimits: _parseWeeklyLimits(map['weeklyLimits']),
    );
  }

  static Map<int, int> _parseWeeklyLimits(Object? raw) {
    if (raw is! Map) return const {};
    final parsed = <int, int>{};
    raw.forEach((key, value) {
      final day = int.tryParse('$key');
      if (day == null || day < DateTime.monday || day > DateTime.sunday) return;
      if (value is num) parsed[day] = value.toInt();
    });
    return parsed;
  }

  @override
  List<Object?> get props => [
        packageName,
        appName,
        iconBase64,
        timeLimitMinutes,
        usageTimeMs,
        isMonitored,
        lockMode,
        weeklyLimits,
      ];
}
