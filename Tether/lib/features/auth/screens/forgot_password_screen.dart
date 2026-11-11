import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_theme.dart';
import '../models/auth_models.dart';
import '../services/auth_service.dart';
import '../widgets/auth_widgets.dart';

/// Emails a reset link. Opening it on this phone signs the member in and the
/// auth gate asks for a new password.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  final Gym gym;
  final String email;

  const ForgotPasswordScreen({super.key, required this.gym, required this.email});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  late final _emailCtrl = TextEditingController(text: widget.email);
  bool _isLoading = false;
  String? _sentTo;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_isLoading) return;
    final id = AuthIdentifier.parse(_emailCtrl.text);
    if (id == null || !id.isEmail) {
      setState(() => _error = 'Enter the email you sign in with.');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).forgotPassword(
            gymId: widget.gym.id,
            email: id.email!,
          );
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      setState(() {
        _isLoading = false;
        _sentTo = id.email;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = authErrorMessage(
          e,
          fallback: 'Could not send the reset email. Please try again.',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sentTo = _sentTo;
    if (sentTo != null) {
      return AuthStepScaffold(
        gym: widget.gym,
        leading: const AuthStepIcon(icon: Symbols.mark_email_read),
        title: 'Check your email',
        subtitle: Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'If '),
              TextSpan(
                text: sentTo,
                style: const TextStyle(
                  color: AppTheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(
                text: ' has an account at ${widget.gym.name}, a reset link is '
                    'on its way. Open it on this phone to choose a new password.',
              ),
            ],
          ),
        ),
        action: AuthPrimaryButton(
          label: 'Back to sign in',
          icon: Symbols.arrow_back,
          onPressed: () => Navigator.pop(context),
        ),
        secondaryAction: AuthTextButton(
          label: 'Send it again',
          onPressed: () => setState(() => _sentTo = null),
        ),
      );
    }

    return AuthStepScaffold(
      gym: widget.gym,
      eyebrow: 'Forgot password',
      title: 'Reset your password',
      subtitle: const Text('We\'ll email you a link to choose a new one.'),
      error: _error,
      action: AuthPrimaryButton(
        label: 'Send reset link',
        icon: Symbols.send,
        isLoading: _isLoading,
        onPressed: _send,
      ),
      children: [
        AuthField(
          controller: _emailCtrl,
          hint: 'you@example.com',
          icon: Symbols.alternate_email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.send,
          autofillHints: const [AutofillHints.email],
          enabled: !_isLoading,
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          onSubmitted: (_) => _send(),
        ),
      ],
    );
  }
}
