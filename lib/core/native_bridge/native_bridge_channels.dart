/// Defines all MethodChannel names and method identifiers
/// for communication between Dart and Kotlin.
///
/// Channel names follow the reverse-domain pattern matching
/// the app's package name for uniqueness.
library;

// ── Channel Names ───────────────────────────────────────────────────
/// Channel for querying app usage statistics via UsageStatsManager.
const String kUsageStatsChannel =
    'com.inibudi.screentimeshield/usage_stats';

/// Channel for controlling the app-lock overlay / foreground service.
const String kAppLockChannel =
    'com.inibudi.screentimeshield/app_lock';

/// Channel for Device Administrator operations (anti-cheat).
const String kDeviceAdminChannel =
    'com.inibudi.screentimeshield/device_admin';

// ── Method Enums ────────────────────────────────────────────────────

/// Methods available on the [kUsageStatsChannel].
enum UsageStatsMethod {
  /// Check if Usage Stats permission is granted.
  checkPermission('checkPermission'),

  /// Open the system Usage Stats permission settings page.
  requestPermission('requestPermission'),

  /// Query usage stats for a given time range.
  /// Expects arguments: { 'startTime': int, 'endTime': int }
  getUsageStats('getUsageStats'),

  /// Get list of installed (launchable) apps.
  getInstalledApps('getInstalledApps');

  final String methodName;
  const UsageStatsMethod(this.methodName);
}

/// Methods available on the [kAppLockChannel].
enum AppLockMethod {
  /// Start the foreground monitoring service.
  startService('startService'),

  /// Stop the foreground monitoring service.
  stopService('stopService'),

  /// Check if Draw-Over-Other-Apps permission is granted.
  checkOverlayPermission('checkOverlayPermission'),

  /// Request Draw-Over-Other-Apps permission.
  requestOverlayPermission('requestOverlayPermission'),

  /// Update the list of apps to monitor & their time limits.
  /// Expects arguments: `{ 'apps': List<Map<String, dynamic>> }`
  updateMonitoredApps('updateMonitoredApps');

  final String methodName;
  const AppLockMethod(this.methodName);
}

/// Methods available on the [kDeviceAdminChannel].
enum DeviceAdminMethod {
  /// Check if Device Admin privilege is active.
  checkAdminStatus('checkAdminStatus'),

  /// Request Device Admin activation.
  requestAdmin('requestAdmin'),

  /// Remove Device Admin (requires PIN verification first).
  removeAdmin('removeAdmin');

  final String methodName;
  const DeviceAdminMethod(this.methodName);
}
