import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_dimensions.dart';

/// One weekday's minute input inside [WeekdayLimitDialog].
///
/// An empty field means "use the global limit for this day"; `0` means
/// "unlimited this day".
class WeekdayLimitRow extends StatelessWidget {
  final int weekday;
  final String label;
  final TextEditingController controller;
  final VoidCallback onChanged;

  static const int maxMinutes = 1440; // 24 hours

  const WeekdayLimitRow({
    super.key,
    required this.weekday,
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  static String? validate(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return null; // inherit global limit
    final minutes = int.tryParse(raw);
    if (minutes == null) return 'Numbers only';
    if (minutes < 0) return 'Cannot be negative';
    if (minutes > maxMinutes) return 'Maximum $maxMinutes minutes';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacing4),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 4,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: validate,
              onChanged: (_) => onChanged(),
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'global',
                counterText: '',
                suffixText: 'min',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
