import 'package:fpdart/fpdart.dart';

import '../../../core/error/failures.dart';
import '../../../core/native_bridge/native_bridge.dart';
import '../../../core/native_bridge/native_bridge_channels.dart';

/// Repository for querying system usage stats and installed apps via MethodChannel.
class AppUsageRepository {
  final NativeBridge _bridge;

  AppUsageRepository({NativeBridge? bridge})
      : _bridge = bridge ?? NativeBridge(channelName: kUsageStatsChannel);

  /// Checks if Usage Stats system permission is granted.
  Future<Either<Failure, bool>> checkUsagePermission() async {
    return _bridge.invokeNativeMethod<bool>(
      UsageStatsMethod.checkPermission.methodName,
    );
  }

  /// Opens system settings for Usage Stats permission.
  Future<Either<Failure, bool>> requestUsagePermission() async {
    return _bridge.invokeNativeMethod<bool>(
      UsageStatsMethod.requestPermission.methodName,
    );
  }

  /// Queries usage stats for today (00:00 to now).
  Future<Either<Failure, List<dynamic>>> getTodayUsageStats() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startTime = startOfDay.millisecondsSinceEpoch;
    final endTime = now.millisecondsSinceEpoch;

    return _bridge.invokeNativeMethod<List<dynamic>>(
      UsageStatsMethod.getUsageStats.methodName,
      arguments: {
        'startTime': startTime,
        'endTime': endTime,
      },
    );
  }

  /// Fetches launchable installed apps on the device.
  Future<Either<Failure, List<dynamic>>> getInstalledApps() async {
    return _bridge.invokeNativeMethod<List<dynamic>>(
      UsageStatsMethod.getInstalledApps.methodName,
    );
  }
}
