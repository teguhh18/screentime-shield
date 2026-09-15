import 'package:flutter_test/flutter_test.dart';
import 'package:screentimeshield/core/utils/weekly_limit.dart';
import 'package:screentimeshield/features/dashboard/domain/monitored_app_model.dart';

void main() {
  MonitoredApp buildApp({
    int globalMinutes = 0,
    Map<int, int> weekly = const {},
  }) {
    return MonitoredApp(
      packageName: 'com.example.app',
      appName: 'Example',
      timeLimitMinutes: globalMinutes,
      isMonitored: globalMinutes > 0,
      weeklyLimits: weekly,
    );
  }

  group('todayLimitMinutes', () {
    test('uses the scheduled value for today when one exists', () {
      final today = DateTime.now().weekday;
      final app = buildApp(globalMinutes: 60, weekly: {today: 120});
      expect(app.todayLimitMinutes, 120);
    });

    test('falls back to the global limit on unscheduled days', () {
      final tomorrow = DateTime.now().weekday % 7 + 1;
      final app = buildApp(globalMinutes: 60, weekly: {tomorrow: 120});
      expect(app.todayLimitMinutes, 60);
    });

    test('0 on a scheduled day means unlimited, not global', () {
      final today = DateTime.now().weekday;
      final app = buildApp(globalMinutes: 60, weekly: {today: 0});
      expect(app.todayLimitMinutes, 0);
      expect(app.isLimitExceeded, isFalse);
    });

    test('no schedule at all keeps the global limit', () {
      final app = buildApp(globalMinutes: 45);
      expect(app.todayLimitMinutes, 45);
    });
  });

  group('isActive', () {
    test('true when only a weekly schedule is set', () {
      final app = buildApp(weekly: {DateTime.monday: 30});
      expect(app.isMonitored, isFalse);
      expect(app.isActive, isTrue);
    });

    test('false when nothing is configured', () {
      expect(buildApp().isActive, isFalse);
    });
  });

  group('serialization', () {
    test('round-trips the weekly schedule', () {
      final app = buildApp(
        globalMinutes: 60,
        weekly: {DateTime.monday: 60, DateTime.tuesday: 120},
      );

      final restored = MonitoredApp.fromMap(
        app.toMap(),
        appName: app.appName,
        iconBase64: '',
        usageTimeMs: 0,
      );

      expect(restored.weeklyLimits, {1: 60, 2: 120});
      expect(restored.timeLimitMinutes, 60);
    });

    test('payloads written before the schedule feature load as empty', () {
      final restored = MonitoredApp.fromMap(
        const {
          'packageName': 'com.example.app',
          'timeLimitMinutes': 60,
          'isMonitored': true,
          'lockMode': LockMode.hardLock,
        },
        appName: 'Example',
        iconBase64: '',
        usageTimeMs: 0,
      );

      expect(restored.weeklyLimits, isEmpty);
      expect(restored.timeLimitMinutes, 60);
    });

    test('ignores out-of-range or malformed weekday keys', () {
      final restored = MonitoredApp.fromMap(
        const {
          'packageName': 'com.example.app',
          'weeklyLimits': {'1': 60, '9': 30, 'x': 15, '5': 'nope'},
        },
        appName: 'Example',
        iconBase64: '',
        usageTimeMs: 0,
      );

      expect(restored.weeklyLimits, {1: 60});
    });
  });

  group('WeeklyLimit helpers', () {
    test('describe falls back when there is no schedule', () {
      expect(WeeklyLimit.describe(const {}, 60), 'Same limit every day');
    });

    test('describe counts the days still following the global limit', () {
      final text = WeeklyLimit.describe(const {1: 60, 2: 120}, 60);
      expect(text, 'Mon 60m · Tue 120m · global on 5 days');
    });

    test('weekday labels cover the whole week', () {
      for (final day in WeeklyLimit.order) {
        expect(WeeklyLimit.weekdayLabel(day), isNotEmpty);
        expect(WeeklyLimit.weekdayLabel(day, short: true), isNotEmpty);
      }
    });
  });
}
