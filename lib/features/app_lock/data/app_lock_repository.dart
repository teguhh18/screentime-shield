import 'package:fpdart/fpdart.dart';

import '../../../core/error/failures.dart';
import '../../../core/native_bridge/native_bridge.dart';
import '../../../core/native_bridge/native_bridge_channels.dart';
import '../../dashboard/domain/monitored_app_model.dart';

/// Repository for managing app lock service and overlay limits via MethodChannel.
class AppLockRepository {
  final NativeBridge _bridge;

  AppLockRepository({NativeBridge? bridge})
      : _bridge = bridge ?? NativeBridge(channelName: kAppLockChannel);

  /// Starts the native Foreground monitoring service.
  Future<Either<Failure, bool>> startService() async {
    return _bridge.invokeNativeMethod<bool>(
      AppLockMethod.startService.methodName,
    );
  }

  /// Stops the native Foreground monitoring service.
  Future<Either<Failure, bool>> stopService() async {
    return _bridge.invokeNativeMethod<bool>(
      AppLockMethod.stopService.methodName,
    );
  }

  /// Checks if System Overlay permission is granted.
  Future<Either<Failure, bool>> checkOverlayPermission() async {
    return _bridge.invokeNativeMethod<bool>(
      AppLockMethod.checkOverlayPermission.methodName,
    );
  }

  /// Requests System Overlay permission from Settings.
  Future<Either<Failure, bool>> requestOverlayPermission() async {
    return _bridge.invokeNativeMethod<bool>(
      AppLockMethod.requestOverlayPermission.methodName,
    );
  }

  /// Updates list of monitored apps and daily limits sent to native background service.
  Future<Either<Failure, bool>> updateMonitoredApps(
    List<MonitoredApp> apps,
  ) async {
    // isActive (not isMonitored): an app may only have a weekly schedule set.
    final activeOnly = apps.where((a) => a.isActive).toList();
    final appsPayload = activeOnly.map((a) => a.toMap()).toList();

    return _bridge.invokeNativeMethod<bool>(
      AppLockMethod.updateMonitoredApps.methodName,
      arguments: {'apps': appsPayload},
    );
  }
}
