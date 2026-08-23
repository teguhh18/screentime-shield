import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/storage/local_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/auth/presentation/onboarding_screen.dart';
import 'features/auth/presentation/pin_login_screen.dart';
import 'features/auth/presentation/pin_setup_screen.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize offline Hive storage
  await LocalStorageService.init();

  runApp(
    const ProviderScope(
      child: ScreenTimeShieldApp(),
    ),
  );
}

class ScreenTimeShieldApp extends ConsumerWidget {
  const ScreenTimeShieldApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'ScreenTime Shield',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: _buildHome(authState),
    );
  }

  Widget _buildHome(AuthState authState) {
    if (authState is AuthLoading || authState is AuthInitial) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (authState is AuthUnauthenticated) {
      if (!authState.onboardingCompleted) {
        return const OnboardingScreen();
      }
      if (!authState.hasPinSet) {
        return const PinSetupScreen();
      }
      return const PinLoginScreen();
    }

    if (authState is AuthAuthenticated) {
      return const DashboardScreen();
    }

    return const PinLoginScreen();
  }
}
