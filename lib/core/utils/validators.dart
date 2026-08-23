/// Input validation helpers.
///
/// All validation logic is centralized here to keep
/// UI files free of business logic (per SKILL.md).
abstract final class Validators {
  /// Validates a PIN string.
  ///
  /// Returns `null` if valid, or an error message string if invalid.
  /// A valid PIN is exactly 4 digits.
  static String? validatePin(String? pin) {
    if (pin == null || pin.isEmpty) {
      return 'PIN cannot be empty.';
    }
    if (pin.length != 4) {
      return 'PIN must be exactly 4 digits.';
    }
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      return 'PIN must contain only numbers.';
    }
    return null;
  }

  /// Validates that two PINs match (for setup confirmation).
  ///
  /// Returns `null` if they match, or an error message if they don't.
  static String? validatePinConfirmation(String? pin, String? confirm) {
    final pinError = validatePin(pin);
    if (pinError != null) return pinError;

    if (pin != confirm) {
      return 'PINs do not match.';
    }
    return null;
  }

  /// Validates that a screen time limit (in minutes) is reasonable.
  ///
  /// Must be between 1 and 1440 (24 hours).
  static String? validateTimeLimitMinutes(int? minutes) {
    if (minutes == null || minutes < 1) {
      return 'Time limit must be at least 1 minute.';
    }
    if (minutes > 1440) {
      return 'Time limit cannot exceed 24 hours.';
    }
    return null;
  }
}
