import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../models/auth_models.dart';
import '../services/auth_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ForgotPasswordScreen
//
// Linked from LoginScreen. Sends a password reset email via NestJS which
// confirms the email is still on the gym roster before triggering Supabase.
// The reset link deep-links back to the app where SetPasswordScreen handles it.
// ─────────────────────────────────────────────────────────────────────────────
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  final Gym gym;
  final String email; // pre-filled from LoginScreen

  const ForgotPasswordScreen({
    super.key,
    required this.gym,
    required this.email,
  });

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailCtrl;
  bool _isLoading = false;
  bool _sent = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.email);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      await ref.read(authServiceProvider).forgotPassword(
        gymId: widget.gym.id,
        email: _emailCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() { _isLoading = false; _sent = true; });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not send reset email. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0D0E12), AppTheme.surface],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // ── Top bar ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.gutter, vertical: AppTheme.unit),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerHigh,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: const Icon(Symbols.arrow_back, size: 20,
                              color: AppTheme.onSurface),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.containerMargin),
                    child: _sent ? _SuccessState(email: _emailCtrl.text.trim()) : Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppTheme.stackLg),

                          Center(
                            child: Column(
                              children: [
                                Container(
                                  width: 72, height: 72,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryContainer.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppTheme.primaryContainer.withValues(alpha: 0.3),
                                      width: 1.5,
                                    ),
                                    boxShadow: AppTheme.neonGlow(opacity: 0.2, blur: 24),
                                  ),
                                  child: const Icon(Symbols.lock_reset,
                                      size: 36, color: AppTheme.primaryContainer),
                                ),
                                const SizedBox(height: AppTheme.stackMd),
                                Text('Reset password',
                                  style: Theme.of(context).textTheme.headlineLarge),
                                const SizedBox(height: AppTheme.unit),
                                Text(
                                  "Enter your email and we'll send a reset link\nif your account is active.",
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: AppTheme.onSurfaceVariant),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: AppTheme.stackLg),

                          Row(
                            children: [
                              Icon(Symbols.mail, size: 14, color: AppTheme.onSurfaceVariant),
                              const SizedBox(width: 6),
                              Text('Email address',
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(color: AppTheme.onSurfaceVariant)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            style: Theme.of(context).textTheme.bodyLarge,
                            decoration: InputDecoration(
                              hintText: 'your@email.com',
                              hintStyle: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5)),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Enter your email';
                              if (!v.contains('@')) return 'Enter a valid email';
                              return null;
                            },
                            onFieldSubmitted: (_) => _sendReset(),
                          ),

                          const SizedBox(height: AppTheme.stackLg),

                          if (_errorMessage != null) ...[
                            _ErrorBanner(message: _errorMessage!),
                            const SizedBox(height: AppTheme.stackMd),
                          ],

                          PrimaryButton(
                            label: 'Send Reset Link',
                            isLoading: _isLoading,
                            icon: Symbols.send,
                            onPressed: _isLoading ? null : _sendReset,
                          ),

                          const SizedBox(height: AppTheme.stackLg),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Success state shown after email is sent
// ─────────────────────────────────────────────────────────────────────────────
class _SuccessState extends StatelessWidget {
  final String email;
  const _SuccessState({required this.email});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: AppTheme.stackLg),
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: AppTheme.primaryContainer.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.primaryContainer.withValues(alpha: 0.4), width: 1.5),
            boxShadow: AppTheme.neonGlow(opacity: 0.3, blur: 28),
          ),
          child: const Icon(Symbols.mark_email_read,
              size: 40, color: AppTheme.primaryContainer),
        ),
        const SizedBox(height: AppTheme.stackMd),
        Text('Check your email',
          style: Theme.of(context).textTheme.headlineLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.unit),
        Text(
          'If $email is registered as a gym member, you\'ll receive a reset link shortly.\n\nTap the link to set a new password.',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: AppTheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.stackLg),
        SecondaryButton(
          label: 'Back to Sign In',
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.gutter, vertical: AppTheme.stackSm),
      decoration: BoxDecoration(
        color: AppTheme.errorContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Symbols.error, size: 16, color: AppTheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}
