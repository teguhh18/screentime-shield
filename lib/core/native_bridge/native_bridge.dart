import 'package:flutter/services.dart';
import 'package:fpdart/fpdart.dart';

import '../error/failures.dart';

/// Base class for all native platform bridges (MethodChannel wrappers).
///
/// Provides a standardized [invokeNativeMethod] that:
/// 1. Calls the native method via [MethodChannel].
/// 2. Wraps the result in `Either<Failure, T>`.
/// 3. Catches [PlatformException] and [MissingPluginException]
///    and converts them to [PlatformFailure] with a user-readable message.
///
/// Usage (in a concrete bridge subclass):
/// ```dart
/// class UsageStatsBridge extends NativeBridge {
///   UsageStatsBridge() : super(channelName: kUsageStatsChannel);
///
///   Future<Either<Failure, List<dynamic>>> getUsageStats(...) =>
///       invokeNativeMethod<List<dynamic>>(
///         UsageStatsMethod.getUsageStats.methodName,
///         arguments: { 'startTime': start, 'endTime': end },
///       );
/// }
/// ```
class NativeBridge {
  late final MethodChannel _channel;

  /// The channel name this bridge communicates over.
  final String channelName;

  NativeBridge({required this.channelName}) {
    _channel = MethodChannel(channelName);
  }

  /// Invokes a native method and returns the result wrapped in [Either].
  ///
  /// - [method]: The method name string (use the enum's `.methodName`).
  /// - [arguments]: Optional map of arguments to pass to the native side.
  ///
  /// Returns [Right] with the result on success,
  /// or [Left] with a [PlatformFailure] on error.
  Future<Either<Failure, T>> invokeNativeMethod<T>(
    String method, {
    Map<String, dynamic>? arguments,
  }) async {
    try {
      final result = await _channel.invokeMethod<T>(method, arguments);
      return Right(result as T);
    } on PlatformException catch (e) {
      return Left(
        PlatformFailure(
          message: e.message ??
              'An unknown error occurred while communicating with the system.',
          code: e.code,
        ),
      );
    } on MissingPluginException {
      return Left(
        const PlatformFailure(
          message:
              'This feature is not available on the current platform. '
              'Please make sure the app is running on a supported Android device.',
          code: 'MISSING_PLUGIN',
        ),
      );
    }
  }

  /// Sets a handler for method calls coming FROM the native side.
  ///
  /// Useful for receiving events like "app limit reached" or
  /// "overlay dismissed" from the Kotlin foreground service.
  void setMethodCallHandler(
    Future<dynamic> Function(MethodCall call)? handler,
  ) {
    _channel.setMethodCallHandler(handler);
  }
}
