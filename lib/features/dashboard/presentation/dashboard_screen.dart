import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_usage_tile.dart';
import '../../../core/widgets/time_limit_dialog.dart';
import '../../settings/presentation/settings_screen.dart';
import 'dashboard_controller.dart';

/// Main Dashboard showing total screen time stats and app limit configuration.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardStateProvider);
    final notifier = ref.read(dashboardStateProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ScreenTime Shield'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: notifier.loadDashboardData,
              child: Column(
                children: [
                  _buildHeaderCard(context, state),
                  _buildSearchBar(notifier),
                  Expanded(
                    child: ListView.builder(
                      itemCount: state.filteredApps.length,
                      itemBuilder: (context, index) {
                        final app = state.filteredApps[index];
                        return AppUsageTile(
                          app: app,
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => TimeLimitDialog(
                                app: app,
                                onSave: ({
                                  required limitMinutes,
                                  required lockMode,
                                }) {
                                  notifier.configureAppLimit(
                                    packageName: app.packageName,
                                    limitMinutes: limitMinutes,
                                    lockMode: lockMode,
                                  );
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, DashboardState state) {
    final totalDuration = Duration(milliseconds: state.totalScreenTimeMs);
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(AppDimensions.spacing16),
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacing24),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Today\'s Total Screen Time',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormatter.formatDuration(totalDuration),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Chip(
              avatar: const Icon(Icons.shield, size: 18),
              label: Text('${state.monitoredAppsCount} Monitored'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(DashboardNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing16),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Search apps...',
          prefixIcon: Icon(Icons.search),
          contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        ),
        onChanged: notifier.setSearchQuery,
      ),
    );
  }
}
