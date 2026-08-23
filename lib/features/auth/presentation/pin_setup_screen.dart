import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/pin_pad.dart';
import 'auth_controller.dart';

/// Screen for creating and confirming parental access PIN.
class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  String _firstPin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  String? _errorMessage;

  void _handleCompleted() async {
    if (!_isConfirming) {
      setState(() {
        _isConfirming = true;
        _errorMessage = null;
      });
    } else {
      if (_firstPin == _confirmPin) {
        final success =
            await ref.read(authStateProvider.notifier).savePin(_firstPin);
        if (!success && mounted) {
          setState(() {
            _errorMessage = 'Failed to save PIN securely.';
          });
        }
      } else {
        setState(() {
          _firstPin = '';
          _confirmPin = '';
          _isConfirming = false;
          _errorMessage = 'PINs do not match. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activePin = _isConfirming ? _confirmPin : _firstPin;

    return Scaffold(
      appBar: AppBar(title: const Text('Parent Security PIN')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacing24),
          child: Column(
            children: [
              Text(
                _isConfirming ? 'Confirm your PIN' : 'Create 4-Digit PIN',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppDimensions.spacing8),
              Text(
                _isConfirming
                    ? 'Re-enter your PIN to verify.'
                    : 'Choose a PIN that your child cannot guess.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              PinPad(
                pin: activePin,
                onPinChanged: (val) {
                  setState(() {
                    if (_isConfirming) {
                      _confirmPin = val;
                    } else {
                      _firstPin = val;
                    }
                  });
                },
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
