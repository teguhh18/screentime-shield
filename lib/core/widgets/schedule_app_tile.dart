import 'dart:convert';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../utils/weekly_limit.dart';
import '../../features/dashboard/domain/monitored_app_model.dart';

/// List item for the weekly schedule tab: app icon, name, schedule summary,
/// and today's effective limit badge.
class ScheduleAppTile extends StatelessWidget {
  final MonitoredApp app;
  final VoidCallback onTap;

  const ScheduleAppTile({
    super.key,
    required this.app,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final todayLimit = app.todayLimitMinutes;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacing16,
        vertical: AppDimensions.spacing4,
      ),
      child: ListTile(
        onTap: onTap,
        leading: _buildAppIcon(),
        title: Text(
          app.appName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              WeeklyLimit.describe(app.weeklyLimits, app.timeLimitMinutes),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            _badge(
              WeeklyLimit.describeToday(
                app.weeklyLimits,
                app.timeLimitMinutes,
              ),
              app.isLimitExceeded
                  ? AppColors.error
                  : (todayLimit > 0 ? AppColors.primary : theme.disabledColor),
            ),
          ],
        ),
        trailing: Icon(
          app.weeklyLimits.isEmpty ? Icons.calendar_today_outlined : Icons.event_available,
          color: app.weeklyLimits.isEmpty ? theme.disabledColor : AppColors.success,
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildAppIcon() {
    if (app.iconBase64.isNotEmpty) {
      try {
        final bytes = base64Decode(app.iconBase64);
        return Image.memory(
          bytes,
          width: AppDimensions.iconXLarge,
          height: AppDimensions.iconXLarge,
          errorBuilder: (_, _, _) => _defaultIcon(),
        );
      } catch (_) {
        return _defaultIcon();
      }
    }
    return _defaultIcon();
  }

  Widget _defaultIcon() {
    return const CircleAvatar(
      child: Icon(Icons.android, size: AppDimensions.iconMedium),
    );
  }
}
