import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/pin_pad.dart';
import 'auth_controller.dart';

/// Screen for authenticating parental PIN.
class PinLoginScreen extends ConsumerStatefulWidget {
  const PinLoginScreen({super.key});

  @override
  ConsumerState<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends ConsumerState<PinLoginScreen> {
  String _enteredPin = '';
  String? _errorMessage;

  void _handleCompleted() async {
    final success =
        await ref.read(authStateProvider.notifier).login(_enteredPin);
    if (success && mounted) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context, true);
      }
    } else if (mounted) {
      setState(() {
        _enteredPin = '';
        _errorMessage = 'Incorrect PIN. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Enter Parent PIN')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacing24),
          child: Column(
            children: [
              const SizedBox(height: AppDimensions.spacing24),
              Icon(
                Icons.lock_outline,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: AppDimensions.spacing16),
              Text(
                'Enter PIN to Access',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              PinPad(
                pin: _enteredPin,
                onPinChanged: (val) => setState(() => _enteredPin = val),
                onCompleted: _handleCompleted,
                errorMessage: _errorMessage,
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
