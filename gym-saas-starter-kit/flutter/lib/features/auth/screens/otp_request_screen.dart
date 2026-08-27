import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'otp_verification_screen.dart';

class OtpRequestScreen extends ConsumerStatefulWidget {
  const OtpRequestScreen({super.key});

  @override
  ConsumerState<OtpRequestScreen> createState() => _OtpRequestScreenState();
}

class _OtpRequestScreenState extends ConsumerState<OtpRequestScreen> {
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _useEmail = true;

  Future<void> _requestOtp() async {
    final email = _useEmail ? _emailController.text.trim() : null;
    final phone = !_useEmail ? _phoneController.text.trim() : null;

    if ((email?.isEmpty ?? true) && (phone?.isEmpty ?? true)) {
      _showError('Please enter your \${_useEmail ? "email" : "phone number"}');
      return;
    }

    await ref.read(authNotifierProvider.notifier).requestOtp(
      email: email,
      phone: phone,
    );

    final state = ref.read(authNotifierProvider);
    if (state.error != null) {
      _showError(state.error!);
      return;
    }

    // Navigate to verification
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            email: email,
            phone: phone,
          ),
        ),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authNotifierProvider);
    final gym = ref.watch(selectedGymProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(gym?.name ?? 'Login'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(
                'Welcome Back',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the \${_useEmail ? "email" : "phone number"} you registered with at \${gym?.name ?? "your gym"}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 32),

              // Toggle
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Email')),
                  ButtonSegment(value: false, label: Text('Phone')),
                ],
                selected: {_useEmail},
                onSelectionChanged: (set) {
                  setState(() => _useEmail = set.first);
                },
              ),
              const SizedBox(height: 24),

              if (_useEmail)
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'you@example.com',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                )
              else
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '+1 234 567 8900',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: authState.isLoading ? null : _requestOtp,
                  child: authState.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Send Code', style: TextStyle(fontSize: 16)),
                ),
              ),

              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Wrong gym? Go back'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
