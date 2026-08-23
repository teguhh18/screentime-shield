import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';

// ── State ────────────────────────────────────────────────────────────

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthUnauthenticated extends AuthState {
  final bool hasPinSet;
  final bool onboardingCompleted;

  const AuthUnauthenticated({
    required this.hasPinSet,
    required this.onboardingCompleted,
  });

  @override
  List<Object?> get props => [hasPinSet, onboardingCompleted];
}

class AuthAuthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

// ── Notifier ─────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(AuthInitial()) {
    checkInitialStatus();
  }

  Future<void> checkInitialStatus() async {
    state = AuthLoading();

    final onboardingRes = await _repository.isOnboardingCompleted();
    final pinRes = await _repository.hasPin();

    final onboardingDone = onboardingRes.fold((_) => false, (v) => v);
    final pinSet = pinRes.fold((_) => false, (v) => v);

    state = AuthUnauthenticated(
      hasPinSet: pinSet,
      onboardingCompleted: onboardingDone,
    );
  }

  Future<bool> savePin(String pin) async {
    state = AuthLoading();
    final result = await _repository.savePin(pin);

    return result.fold(
      (failure) {
        state = AuthError(failure.message);
        return false;
      },
      (_) {
        state = AuthAuthenticated();
        return true;
      },
    );
  }

  Future<bool> login(String pin) async {
    state = AuthLoading();
    final result = await _repository.verifyPin(pin);

    return result.fold(
      (failure) {
        state = AuthError(failure.message);
        return false;
      },
      (isValid) {
        if (isValid) {
          state = AuthAuthenticated();
          return true;
        } else {
          state = const AuthError('Incorrect PIN. Please try again.');
          return false;
        }
      },
    );
  }

  Future<void> completeOnboarding() async {
    await _repository.setOnboardingCompleted();
    await checkInitialStatus();
  }
}

// ── Providers ────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
