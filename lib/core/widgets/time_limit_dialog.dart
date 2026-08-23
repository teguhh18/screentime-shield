import 'package:flutter/material.dart';

import '../../features/dashboard/domain/monitored_app_model.dart';

/// Reusable app restriction configuration dialog.
class TimeLimitDialog extends StatefulWidget {
  final MonitoredApp app;
  final Function({
    required int limitMinutes,
    required String lockMode,
  }) onSave;

  const TimeLimitDialog({
    super.key,
    required this.app,
    required this.onSave,
  });

  @override
  State<TimeLimitDialog> createState() => _TimeLimitDialogState();
}

class _TimeLimitDialogState extends State<TimeLimitDialog> {
  late double _selectedMinutes;
  late String _selectedLockMode;

  @override
  void initState() {
    super.initState();
    _selectedMinutes = (widget.app.timeLimitMinutes == 0)
        ? 60.0
        : widget.app.timeLimitMinutes.toDouble();
    _selectedLockMode = widget.app.lockMode;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text('Restrict: ${widget.app.appName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '1. Daily Time Limit',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Center(
              child: Text(
                _selectedMinutes == 0
                    ? 'No limit'
                    : '${_selectedMinutes.toInt()} minutes / day',
                style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary),
              ),
            ),
            Slider(
              value: _selectedMinutes,
              min: 0,
              max: 240,
              divisions: 48,
              onChanged: (val) => setState(() => _selectedMinutes = val),
            ),
            const Divider(),
            Text(
              '2. Lock Mode',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                _selectedLockMode == LockMode.hardLock
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: _selectedLockMode == LockMode.hardLock
                    ? theme.colorScheme.primary
                    : null,
              ),
              title: const Text('Hard Lock (Block & Kick to Home)'),
              subtitle: const Text('Prevents opening app & forces back to Home.'),
              onTap: () => setState(() => _selectedLockMode = LockMode.hardLock),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                _selectedLockMode == LockMode.snoozeAlarm
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: _selectedLockMode == LockMode.snoozeAlarm
                    ? theme.colorScheme.primary
                    : null,
              ),
              title: const Text('Snooze Alarm'),
              subtitle: const Text('Warning alert with 5/15 min snooze option.'),
              onTap: () => setState(() => _selectedLockMode = LockMode.snoozeAlarm),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.app.isMonitored)
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              widget.onSave(
                limitMinutes: 0,
                lockMode: _selectedLockMode,
              );
              Navigator.pop(context);
            },
            child: const Text('Disable'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(
              limitMinutes: _selectedMinutes.toInt(),
              lockMode: _selectedLockMode,
            );
            Navigator.pop(context);
          },
          child: const Text('Save Settings'),
        ),
      ],
    );
  }
}
