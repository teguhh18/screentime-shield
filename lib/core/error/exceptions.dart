/// Custom exceptions for lower-level error propagation.
///
/// These exceptions are caught at the repository layer and
/// converted into [Failure] types for the domain/presentation layers.
/// They should NEVER reach the UI directly.
library;

/// Thrown when a local storage (Hive) operation fails.
class CacheException implements Exception {
  final String message;
  final dynamic originalError;

  const CacheException({
    this.message = 'A cache operation failed.',
    this.originalError,
  });

  @override
  String toString() => 'CacheException: $message';
}

/// Thrown when a MethodChannel call fails at the data-source level.
class PlatformBridgeException implements Exception {
  final String message;
  final String? errorCode;
  final dynamic originalError;

  const PlatformBridgeException({
    this.message = 'A platform bridge call failed.',
    this.errorCode,
    this.originalError,
  });

  @override
  String toString() => 'PlatformBridgeException($errorCode): $message';
}
