import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/permission_aware_scope.dart';
import '../../../core/widgets/permission_card.dart';
import '../../auth/presentation/pin_login_screen.dart';
import 'permissions_controller.dart';

/// Settings screen for managing permissions, anti-cheat, and safe app uninstallation.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(permissionsStateProvider);
    final permNotifier = ref.read(permissionsStateProvider.notifier);

    return PermissionAwareScope(
      child: Scaffold(
        appBar: AppBar(title: const Text('Security & Settings')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppDimensions.spacing16),
            children: [
              Text(
                'System Permissions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppDimensions.spacing8),
              PermissionCard(
                title: 'Usage Access',
                description: 'Required to track daily app screen time.',
                icon: Icons.bar_chart,
                isGranted: permissions.isUsageStatsGranted,
                onRequest: permNotifier.requestUsagePermission,
              ),
              PermissionCard(
                title: 'System Overlay',
                description: 'Required for full-screen lock mode.',
                icon: Icons.layers,
                isGranted: permissions.isOverlayGranted,
                onRequest: permNotifier.requestOverlayPermission,
              ),
              PermissionCard(
                title: 'Anti-Cheat (Device Admin)',
                description: 'Prevents unauthorized uninstallation.',
                icon: Icons.shield,
                isGranted: permissions.isDeviceAdminGranted,
                onRequest: permNotifier.requestDeviceAdmin,
              ),
              const SizedBox(height: AppDimensions.spacing24),
              Text(
                'App Management',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppDimensions.spacing8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Uninstall Protection'),
                  subtitle: Text(
                    permissions.isDeviceAdminGranted
                        ? 'Protected. PIN required to disable and uninstall.'
                        : 'Not protected.',
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.spacing16),
              CustomButton(
                text: 'Disable Anti-Cheat & Prepare Uninstall',
                isOutlined: true,
                onPressed: () async {
                  final pinVerified = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PinLoginScreen(),
                    ),
                  );

                  if (pinVerified == true) {
                    await permNotifier.removeDeviceAdmin();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Anti-Cheat disabled. App can now be uninstalled.',
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}