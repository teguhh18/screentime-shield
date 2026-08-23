import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/permission_card.dart';
import '../../settings/presentation/permissions_controller.dart';
import 'auth_controller.dart';

/// Friendly Onboarding Screen educating parents about system permissions
/// before requesting native intents.
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(permissionsStateProvider);
    final permNotifier = ref.read(permissionsStateProvider.notifier);
    final authNotifier = ref.read(authStateProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Setup ScreenTime Shield')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacing24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome Parents!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppDimensions.spacing8),
              Text(
                'To protect and monitor your child\'s screen time, please grant the following essential permissions:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppDimensions.spacing24),
              Expanded(
                child: ListView(
                  children: [
                    PermissionCard(
                      title: 'Usage Access',
                      description:
                          'Allows reading app screen time and active apps.',
                      icon: Icons.bar_chart,
                      isGranted: permissions.isUsageStatsGranted,
                      onRequest: permNotifier.requestUsagePermission,
                    ),
                    PermissionCard(
                      title: 'Display Over Apps',
                      description:
                          'Displays lock screen overlay when time limit ends.',
                      icon: Icons.layers,
                      isGranted: permissions.isOverlayGranted,
                      onRequest: permNotifier.requestOverlayPermission,
                    ),
                    PermissionCard(
                      title: 'Anti-Cheat (Device Admin)',
                      description:
                          'Prevents children from unauthorized app uninstallation.',
                      icon: Icons.shield,
                      isGranted: permissions.isDeviceAdminGranted,
                      onRequest: permNotifier.requestDeviceAdmin,
                    ),
                  ],
                ),
              ),
              CustomButton(
                text: 'Continue to Setup PIN',
                onPressed: () async {
                  await permNotifier.checkAllPermissions();
                  await authNotifier.completeOnboarding();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
