import 'package:equatable/equatable.dart';

/// Supported restriction lock modes.
abstract final class LockMode {
  static const String hardLock = 'hardLock';
  static const String snoozeAlarm = 'snoozeAlarm';
}

/// Represents an installed app with its screen time configuration.
class MonitoredApp extends Equatable {
  final String packageName;
  final String appName;
  final String iconBase64;
  final int timeLimitMinutes;
  final int usageTimeMs;
  final bool isMonitored;
  final String lockMode;

  const MonitoredApp({
    required this.packageName,
    required this.appName,
    this.iconBase64 = '',
    this.timeLimitMinutes = 0,
    this.usageTimeMs = 0,
    this.isMonitored = false,
    this.lockMode = LockMode.hardLock,
  });

  bool get isLimitExceeded =>
      isMonitored &&
      timeLimitMinutes > 0 &&
      usageTimeMs >= (timeLimitMinutes * 60 * 1000);

  MonitoredApp copyWith({
    String? packageName,
    String? appName,
    String? iconBase64,
    int? timeLimitMinutes,
    int? usageTimeMs,
    bool? isMonitored,
    String? lockMode,
  }) {
    return MonitoredApp(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      iconBase64: iconBase64 ?? this.iconBase64,
      timeLimitMinutes: timeLimitMinutes ?? this.timeLimitMinutes,
      usageTimeMs: usageTimeMs ?? this.usageTimeMs,
      isMonitored: isMonitored ?? this.isMonitored,
      lockMode: lockMode ?? this.lockMode,
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
    );
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
      ];
}
