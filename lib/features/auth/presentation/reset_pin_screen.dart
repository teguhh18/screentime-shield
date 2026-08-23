import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/pin_pad.dart';
import 'auth_controller.dart';

/// Screen for creating a new PIN after successful device credential verification.
class ResetPinScreen extends ConsumerStatefulWidget {
  const ResetPinScreen({super.key});

  @override
  ConsumerState<ResetPinScreen> createState() => _ResetPinScreenState();
}

class _ResetPinScreenState extends ConsumerState<ResetPinScreen> {
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
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PIN berhasil diubah!'),
              backgroundColor: Colors.green,
            ),
          );
          if (Navigator.canPop(context)) {
            Navigator.pop(context, true);
          }
        } else if (mounted) {
          setState(() {
            _errorMessage = 'Gagal menyimpan PIN baru.';
          });
        }
      } else {
        setState(() {
          _firstPin = '';
          _confirmPin = '';
          _isConfirming = false;
          _errorMessage = 'PIN tidak cocok. Silakan coba lagi.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activePin = _isConfirming ? _confirmPin : _firstPin;

    return Scaffold(
      appBar: AppBar(title: const Text('Buat PIN Baru')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacing24),
          child: Column(
            children: [
              const SizedBox(height: AppDimensions.spacing16),
              Icon(
                Icons.lock_reset,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: AppDimensions.spacing16),
              Text(
                _isConfirming ? 'Konfirmasi PIN Baru' : 'Masukkan PIN Baru',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppDimensions.spacing8),
              Text(
                _isConfirming
                    ? 'Masukkan ulang PIN baru untuk verifikasi.'
                    : 'Pilih PIN 4 digit baru untuk aplikasi.',
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
