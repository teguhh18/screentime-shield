import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/error/failures.dart';

/// Repository handling secure storage and verification of parental PIN.
class AuthRepository {
  final FlutterSecureStorage _storage;
  static const String _pinHashKey = 'user_pin_hash';
  static const String _onboardingCompleteKey = 'onboarding_completed';

  AuthRepository({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Hashes a plain string PIN using SHA-256.
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }

  /// Checks if a PIN has been set up.
  Future<Either<Failure, bool>> hasPin() async {
    try {
      final pinHash = await _storage.read(key: _pinHashKey);
      return Right(pinHash != null && pinHash.isNotEmpty);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to read PIN status: $e'));
    }
  }

  /// Saves a new PIN (stored as SHA-256 hash).
  Future<Either<Failure, Unit>> savePin(String pin) async {
    try {
      final hashed = _hashPin(pin);
      await _storage.write(key: _pinHashKey, value: hashed);
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to save PIN securely: $e'));
    }
  }

  /// Verifies an entered PIN against the saved hash.
  Future<Either<Failure, bool>> verifyPin(String pin) async {
    try {
      final savedHash = await _storage.read(key: _pinHashKey);
      if (savedHash == null) {
        return const Right(false);
      }
      final enteredHash = _hashPin(pin);
      return Right(savedHash == enteredHash);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to verify PIN: $e'));
    }
  }

  /// Checks if onboarding has been completed.
  Future<Either<Failure, bool>> isOnboardingCompleted() async {
    try {
      final result = await _storage.read(key: _onboardingCompleteKey);
      return Right(result == 'true');
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to read onboarding state: $e'));
    }
  }

  /// Sets onboarding completion flag.
  Future<Either<Failure, Unit>> setOnboardingCompleted() async {
    try {
      await _storage.write(key: _onboardingCompleteKey, value: 'true');
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to save onboarding state: $e'));
    }
  }
}
