import 'package:flutter/material.dart';

import '../../features/dashboard/domain/monitored_app_model.dart';
import '../utils/weekly_limit.dart';
import 'weekday_limit_row.dart';

/// Editor for an app's per-weekday screen time limits.
///
/// Only the schedule is edited here; the global limit and lock mode stay in
/// [TimeLimitDialog] on the Home tab.
class WeekdayLimitDialog extends StatefulWidget {
  final MonitoredApp app;
  final Function({required Map<int, int> weeklyLimits}) onSave;

  const WeekdayLimitDialog({
    super.key,
    required this.app,
    required this.onSave,
  });

  @override
  State<WeekdayLimitDialog> createState() => _WeekdayLimitDialogState();
}

class _WeekdayLimitDialogState extends State<WeekdayLimitDialog> {
  final Map<int, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (final day in WeeklyLimit.order) {
      final minutes = widget.app.weeklyLimits[day];
      _controllers[day] = TextEditingController(
        text: minutes == null ? '' : minutes.toString(),
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Collects non-empty days into a schedule map.
  Map<int, int>? _collect() {
    final result = <int, int>{};
    for (final day in WeeklyLimit.order) {
      final raw = _controllers[day]!.text.trim();
      if (raw.isEmpty) continue;
      final minutes = int.tryParse(raw);
      if (minutes == null ||
          minutes < 0 ||
          minutes > WeekdayLimitRow.maxMinutes) {
        return null;
      }
      result[day] = minutes;
    }
    return result;
  }

  void _clearAll() {
    for (final controller in _controllers.values) {
      controller.clear();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final global = widget.app.timeLimitMinutes;

    return AlertDialog(
      title: Text('Weekly Schedule: ${widget.app.appName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              global > 0
                  ? 'Global limit: $global min/day. Empty days use it; '
                      'enter 0 for no limit that day.'
                  : 'No global limit set. Only the days you fill in are '
                      'enforced; enter 0 for no limit that day.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            for (final day in WeeklyLimit.order)
              WeekdayLimitRow(
                weekday: day,
                label: WeeklyLimit.weekdayLabel(day, short: true),
                controller: _controllers[day]!,
                onChanged: () => setState(() {}),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          onPressed: _clearAll,
          child: const Text('Clear'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final weekly = _collect();
            if (weekly == null) {
              setState(() {});
              return;
            }
            widget.onSave(weeklyLimits: weekly);
            Navigator.pop(context);
          },
          child: const Text('Save Schedule'),
        ),
      ],
    );
  }
}
