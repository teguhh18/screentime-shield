import 'dart:convert';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../utils/date_formatter.dart';
import '../../features/dashboard/domain/monitored_app_model.dart';

/// List item displaying installed app info, usage time, and lock mode.
class AppUsageTile extends StatelessWidget {
  final MonitoredApp app;
  final VoidCallback onTap;

  const AppUsageTile({
    super.key,
    required this.app,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usageDuration = Duration(milliseconds: app.usageTimeMs);

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
            Text(
              'Today: ${DateFormatter.formatDuration(usageDuration)}',
              style: TextStyle(
                color: app.isLimitExceeded
                    ? AppColors.error
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (app.isMonitored) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _badge('Limit: ${app.timeLimitMinutes}m', AppColors.primary),
                  _badge(
                    app.lockMode == LockMode.hardLock
                        ? 'Hard Lock'
                        : 'Snooze Alarm',
                    app.lockMode == LockMode.hardLock
                        ? Colors.redAccent
                        : Colors.orangeAccent,
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: Icon(
          app.isMonitored ? Icons.timer : Icons.timer_outlined,
          color: app.isMonitored ? AppColors.primary : theme.disabledColor,
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
