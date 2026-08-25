import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  late final TextEditingController _minutesController;
  late String _selectedLockMode;

  static const int _maxMinutes = 1440; // 24 hours

  @override
  void initState() {
    super.initState();
    _minutesController = TextEditingController(
      text: widget.app.timeLimitMinutes == 0
          ? ''
          : widget.app.timeLimitMinutes.toString(),
    );
    _selectedLockMode = widget.app.lockMode;
  }

  @override
  void dispose() {
    _minutesController.dispose();
    super.dispose();
  }

  int? get _parsedMinutes {
    final raw = _minutesController.text.trim();
    if (raw.isEmpty) return null;
    return int.tryParse(raw);
  }

  String? _validateInput(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return 'Please enter a time limit';
    final minutes = int.tryParse(raw);
    if (minutes == null) return 'Numbers only';
    if (minutes < 0) return 'Cannot be negative';
    if (minutes > _maxMinutes) return 'Maximum $_maxMinutes minutes (24 hours)';
    return null;
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
            const SizedBox(height: 8),
            TextFormField(
              controller: _minutesController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 4,
              decoration: InputDecoration(
                labelText: 'Time limit (minutes)',
                hintText: 'e.g. 30',
                counterText: '',
                suffixText: 'min',
                border: const OutlineInputBorder(),
                helperText: 'Leave empty for no limit',
              ),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: _validateInput,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                (_parsedMinutes ?? 0) > 0
                    ? '$_parsedMinutes minutes / day'
                    : 'No limit',
                style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary),
              ),
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
            final minutes = _parsedMinutes;
            if (minutes == null || minutes < 0 || minutes > _maxMinutes) {
              setState(() {});
              return;
            }
            widget.onSave(
              limitMinutes: minutes,
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
