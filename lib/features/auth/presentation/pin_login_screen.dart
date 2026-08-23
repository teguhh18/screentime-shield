import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/native_bridge/native_bridge_channels.dart';
import '../../../core/widgets/pin_pad.dart';
import 'auth_controller.dart';
import 'reset_pin_screen.dart';

/// Screen for authenticating parental PIN.
class PinLoginScreen extends ConsumerStatefulWidget {
  const PinLoginScreen({super.key});

  @override
  ConsumerState<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends ConsumerState<PinLoginScreen> {
  String _enteredPin = '';
  String? _errorMessage;
  bool _isVerifyingDevice = false;

  static const _securityChannel = MethodChannel(kDeviceSecurityChannel);

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

  Future<void> _handleForgotPassword() async {
    if (_isVerifyingDevice) return;

    setState(() => _isVerifyingDevice = true);

    try {
      // 1. Check if device has secure lock screen
      final isSecure =
          await _securityChannel.invokeMethod<bool>('isDeviceSecure') ?? false;

      if (!isSecure) {
        // Device has NO lock screen -> go straight to reset
        if (mounted) {
          _navigateToResetPin();
        }
        return;
      }

      // 2. Device HAS lock screen -> prompt for device credentials
      final verified = await _securityChannel
              .invokeMethod<bool>('confirmDeviceCredential') ??
          false;

      if (verified && mounted) {
        _navigateToResetPin();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verifikasi perangkat gagal atau dibatalkan.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isVerifyingDevice = false);
    }
  }

  void _navigateToResetPin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ResetPinScreen()),
    ).then((result) {
      if (result == true && mounted) {
        // PIN was successfully reset -> pop login screen too
        if (Navigator.canPop(context)) {
          Navigator.pop(context, true);
        }
      }
    });
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
              const SizedBox(height: AppDimensions.spacing24),
              _isVerifyingDevice
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : TextButton(
                      onPressed: _handleForgotPassword,
                      child: Text(
                        'Lupa Password?',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
