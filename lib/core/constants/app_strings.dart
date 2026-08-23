/// Application-wide string constants.
///
/// All user-facing and internal strings are centralized here
/// to simplify localization and prevent magic-string bugs.
abstract final class AppStrings {
  // ── App ───────────────────────────────────────────────────────────
  static const String appName = 'ScreenTime Shield';
  static const String appTagline = 'Protect your child\'s screen time';

  // ── Onboarding ────────────────────────────────────────────────────
  static const String onboardingTitle = 'Welcome to ScreenTime Shield';
  static const String onboardingSubtitle =
      'A simple tool to help manage your child\'s app usage.';
  static const String onboardingPermissionTitle = 'Permissions Required';
  static const String onboardingPermissionBody =
      'We need a few system permissions to monitor and limit app usage. '
      'Each permission will be explained before you grant it.';

  // ── Auth / PIN ────────────────────────────────────────────────────
  static const String pinSetupTitle = 'Create a PIN';
  static const String pinSetupSubtitle =
      'This PIN will protect the app from being modified by your child.';
  static const String pinConfirmTitle = 'Confirm your PIN';
  static const String pinLoginTitle = 'Enter your PIN';
  static const String pinMismatchError = 'PINs do not match. Please try again.';
  static const String pinInvalidError = 'Incorrect PIN. Please try again.';

  // ── Dashboard ─────────────────────────────────────────────────────
  static const String dashboardTitle = 'Dashboard';
  static const String noAppsMonitored = 'No apps are being monitored yet.';
  static const String totalScreenTime = 'Total Screen Time';

  // ── Lock Screen ───────────────────────────────────────────────────
  static const String lockTitle = 'Time\'s Up!';
  static const String lockBody =
      'The daily screen time limit for this app has been reached.';
  static const String snoozeLabel = 'Snooze';
  static const String unlockWithPin = 'Unlock with PIN';

  // ── Settings ──────────────────────────────────────────────────────
  static const String settingsTitle = 'Settings';
  static const String deviceAdminLabel = 'Device Administrator';
  static const String deviceAdminDescription =
      'Prevents the app from being uninstalled without your PIN.';
  static const String uninstallLabel = 'Uninstall App';

  // ── Errors ────────────────────────────────────────────────────────
  static const String genericError = 'Something went wrong. Please try again.';
  static const String storageReadError = 'Failed to read data from storage.';
  static const String storageWriteError = 'Failed to save data to storage.';
  static const String platformError =
      'Could not communicate with the system. Please restart the app.';

  // ── MethodChannel ─────────────────────────────────────────────────
  static const String channelUsageStats =
      'com.inibudi.screentimeshield/usage_stats';
  static const String channelAppLock =
      'com.inibudi.screentimeshield/app_lock';
  static const String channelDeviceAdmin =
      'com.inibudi.screentimeshield/device_admin';
}
