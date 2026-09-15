import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/weekly_limit.dart';
import '../../../core/widgets/schedule_app_tile.dart';
import '../../../core/widgets/weekday_limit_dialog.dart';
import '../../dashboard/presentation/dashboard_controller.dart';

/// Weekly schedule tab: set a different daily limit per weekday for each app.
///
/// Reuses [dashboardStateProvider] so the installed-app list and usage data are
/// only loaded once for both this tab and the Home tab.
class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardStateProvider);
    final notifier = ref.read(dashboardStateProvider.notifier);

    final apps = [...state.apps]
      ..sort((a, b) {
        if (a.weeklyLimits.isNotEmpty != b.weeklyLimits.isNotEmpty) {
          return a.weeklyLimits.isNotEmpty ? -1 : 1;
        }
        return a.appName.toLowerCase().compareTo(b.appName.toLowerCase());
      });

    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Schedule')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: notifier.loadDashboardData,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: apps.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) return _buildHeader(context);
                  final app = apps[index - 1];
                  return ScheduleAppTile(
                    app: app,
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => WeekdayLimitDialog(
                        app: app,
                        onSave: ({required weeklyLimits}) {
                          notifier.configureWeeklyLimits(
                            packageName: app.packageName,
                            weeklyLimits: weeklyLimits,
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final today = WeeklyLimit.weekdayLabel(DateTime.now().weekday);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Different limits per day of the week.',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Today is $today. Days you leave empty follow the app\'s global '
            'limit; enter 0 to allow unlimited use that day.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
