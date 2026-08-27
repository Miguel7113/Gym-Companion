import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';
import '../providers/auth_provider.dart';
import '../../../core/navigation/main_navigation.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String? email;
  final String? phone;

  const OtpVerificationScreen({
    super.key,
    this.email,
    this.phone,
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  String _otp = '';
  bool _isResending = false;

  Future<void> _verifyOtp() async {
    if (_otp.length != 6) return;

    final success = await ref.read(authNotifierProvider.notifier).verifyOtp(
      email: widget.email,
      phone: widget.phone,
      token: _otp,
    );

    if (success && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavigation()),
        (route) => false,
      );
    }
  }

  Future<void> _resendOtp() async {
    setState(() => _isResending = true);
    await ref.read(authNotifierProvider.notifier).requestOtp(
      email: widget.email,
      phone: widget.phone,
    );
    setState(() => _isResending = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authNotifierProvider);

    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: theme.textTheme.headlineSmall,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Verify')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(
                'Enter Code',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We sent a 6-digit code to ${widget.email ?? widget.phone}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: Pinput(
                  length: 6,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: defaultPinTheme.copyWith(
                    decoration: defaultPinTheme.decoration!.copyWith(
                      border: Border.all(color: theme.colorScheme.primary, width: 2),
                    ),
                  ),
                  onCompleted: (pin) {
                    setState(() => _otp = pin);
                    _verifyOtp();
                  },
                ),
              ),
              if (authState.error != null) ...[
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    authState.error!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: authState.isLoading ? null : _verifyOtp,
                  child: authState.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Verify', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: _isResending ? null : _resendOtp,
                  child: _isResending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Resend code'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
