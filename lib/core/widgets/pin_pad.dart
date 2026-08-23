import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// Reusable 4-digit PIN pad with dot indicators.
class PinPad extends StatelessWidget {
  final String pin;
  final ValueChanged<String> onPinChanged;
  final VoidCallback? onCompleted;
  final String? errorMessage;

  const PinPad({
    super.key,
    required this.pin,
    required this.onPinChanged,
    this.onCompleted,
    this.errorMessage,
  });

  void _onKeyPress(String digit) {
    if (pin.length < AppDimensions.pinLength) {
      final newPin = pin + digit;
      onPinChanged(newPin);
      if (newPin.length == AppDimensions.pinLength && onCompleted != null) {
        onCompleted!();
      }
    }
  }

  void _onDelete() {
    if (pin.isNotEmpty) {
      onPinChanged(pin.substring(0, pin.length - 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            AppDimensions.pinLength,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              width: AppDimensions.pinDotSize,
              height: AppDimensions.pinDotSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index < pin.length
                    ? AppColors.primary
                    : theme.colorScheme.outlineVariant,
              ),
            ),
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            errorMessage!,
            style: const TextStyle(color: AppColors.error, fontSize: 13),
          ),
        ],
        const SizedBox(height: 32),
        _buildKeypadGrid(),
      ],
    );
  }

  Widget _buildKeypadGrid() {
    return Column(
      children: [
        for (var row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((d) => _buildKey(d)).toList(),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 64, height: 64),
            _buildKey('0'),
            _buildKey('del', icon: Icons.backspace_outlined),
          ],
        ),
      ],
    );
  }

  Widget _buildKey(String value, {IconData? icon}) {
    return Container(
      margin: const EdgeInsets.all(8),
      width: 64,
      height: 64,
      child: InkWell(
        borderRadius: BorderRadius.circular(32),
        onTap: () => value == 'del' ? _onDelete() : _onKeyPress(value),
        child: Center(
          child: icon != null
              ? Icon(icon, size: 22)
              : Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
