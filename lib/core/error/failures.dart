import 'package:equatable/equatable.dart';

/// Base failure class for the Either pattern.
///
/// All domain-level errors are represented as [Failure] subclasses,
/// ensuring type-safe error handling without throwing exceptions.
/// Used with `fpdart`'s `Either<Failure, T>` throughout the app.
sealed class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

/// Failure originating from local cache/storage operations (Hive).
class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'Failed to access local storage.',
    super.code,
  });
}

/// Failure originating from platform channel communication (MethodChannel).
class PlatformFailure extends Failure {
  const PlatformFailure({
    super.message = 'Failed to communicate with the native platform.',
    super.code,
  });
}

/// Failure originating from input validation.
class ValidationFailure extends Failure {
  const ValidationFailure({
    super.message = 'Validation failed.',
    super.code,
  });
}

/// Failure for permission-related issues.
class PermissionFailure extends Failure {
  const PermissionFailure({
    super.message = 'Required permission was not granted.',
    super.code,
  });
}
