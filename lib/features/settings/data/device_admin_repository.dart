import 'package:fpdart/fpdart.dart';

import '../../../core/error/failures.dart';
import '../../../core/native_bridge/native_bridge.dart';
import '../../../core/native_bridge/native_bridge_channels.dart';

/// Repository for Device Administrator anti-cheat operations via MethodChannel.
class DeviceAdminRepository {
  final NativeBridge _bridge;

  DeviceAdminRepository({NativeBridge? bridge})
      : _bridge = bridge ?? NativeBridge(channelName: kDeviceAdminChannel);

  /// Checks if app is currently activated as Device Administrator.
  Future<Either<Failure, bool>> checkAdminStatus() async {
    return _bridge.invokeNativeMethod<bool>(
      DeviceAdminMethod.checkAdminStatus.methodName,
    );
  }

  /// Triggers system intent to activate Device Administrator (Anti-Cheat).
  Future<Either<Failure, bool>> requestAdmin() async {
    return _bridge.invokeNativeMethod<bool>(
      DeviceAdminMethod.requestAdmin.methodName,
    );
  }

  /// Revokes Device Administrator privilege (Safe uninstall path).
  Future<Either<Failure, bool>> removeAdmin() async {
    return _bridge.invokeNativeMethod<bool>(
      DeviceAdminMethod.removeAdmin.methodName,
    );
  }
}
