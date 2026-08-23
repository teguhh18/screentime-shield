import 'package:fpdart/fpdart.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../error/exceptions.dart';
import '../error/failures.dart';

/// Wrapper around Hive for type-safe local storage access.
///
/// All box operations return `Either<Failure, T>` to ensure
/// errors are handled gracefully without throwing (per SKILL.md).
///
/// Initialization must be called once from [main.dart] before
/// any box access.
class LocalStorageService {
  /// Initializes Hive for Flutter.
  ///
  /// Must be called in `main()` before `runApp()`.
  static Future<void> init() async {
    await Hive.initFlutter();
  }

  /// Opens (or returns an already-open) Hive box.
  ///
  /// Returns [Left<CacheFailure>] if the box cannot be opened.
  static Future<Either<Failure, Box<T>>> openBox<T>(String boxName) async {
    try {
      if (Hive.isBoxOpen(boxName)) {
        return Right(Hive.box<T>(boxName));
      }
      final box = await Hive.openBox<T>(boxName);
      return Right(box);
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Failed to open storage box "$boxName": $e',
        ),
      );
    }
  }

  /// Reads a value from a box by key.
  ///
  /// Returns [Left<CacheFailure>] if the read fails.
  /// Returns [Right(null)] if the key does not exist.
  static Future<Either<Failure, T?>> read<T>(
    String boxName,
    String key,
  ) async {
    try {
      final boxResult = await openBox<T>(boxName);
      return boxResult.fold(
        (failure) => Left(failure),
        (box) => Right(box.get(key)),
      );
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  /// Writes a value to a box by key.
  ///
  /// Returns [Left<CacheFailure>] if the write fails.
  static Future<Either<Failure, void>> write<T>(
    String boxName,
    String key,
    T value,
  ) async {
    try {
      final boxResult = await openBox<T>(boxName);
      return boxResult.fold(
        (failure) => Left(failure),
        (box) async {
          await box.put(key, value);
          return const Right(null);
        },
      );
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  /// Deletes a value from a box by key.
  ///
  /// Returns [Left<CacheFailure>] if the delete fails.
  static Future<Either<Failure, void>> delete<T>(
    String boxName,
    String key,
  ) async {
    try {
      final boxResult = await openBox<T>(boxName);
      return boxResult.fold(
        (failure) => Left(failure),
        (box) async {
          await box.delete(key);
          return const Right(null);
        },
      );
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  /// Closes all open Hive boxes. Call on app disposal if needed.
  static Future<void> closeAll() async {
    await Hive.close();
  }
}

/// Box name constants for type safety.
abstract final class HiveBoxes {
  /// Stores app settings (time limits, monitored apps list, flags).
  static const String settings = 'settings_box';

  /// Stores daily usage statistics cache.
  static const String usageStats = 'usage_stats_box';

  /// Stores app metadata (package name → display name, icon hash).
  static const String appMetadata = 'app_metadata_box';
}
