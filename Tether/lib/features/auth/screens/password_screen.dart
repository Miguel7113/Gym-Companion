import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../models/auth_models.dart';
import '../services/auth_service.dart';
import '../widgets/auth_widgets.dart';
import 'forgot_password_screen.dart';

/// Step 2 for members and staff who already have a password.
class PasswordScreen extends ConsumerStatefulWidget {
  final Gym gym;
  final String email;

  const PasswordScreen({super.key, required this.gym, required this.email});

  @override
  ConsumerState<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends ConsumerState<PasswordScreen> {
  final _controller = TextEditingController();
  bool _obscured = true;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_isLoading) return;
    if (_controller.text.isEmpty) {
      setState(() => _error = 'Enter your password.');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(authServiceProvider).login(
            gymId: widget.gym.id,
            email: widget.email,
            password: _controller.text,
          );
      TextInput.finishAutofillContext();
      // The auth gate swaps to the app and clears this flow.
    } catch (e) {
      if (!mounted) return;
      final status = authStatusCode(e);
      setState(() {
        _isLoading = false;
        _error = status == 401 || status == 400
            ? 'That password isn\'t right. Try again, or reset it below.'
            : authErrorMessage(e, fallback: 'Could not sign in. Please try again.');
      });
    }
  }

  void _forgot() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ForgotPasswordScreen(gym: widget.gym, email: widget.email),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthStepScaffold(
      gym: widget.gym,
      eyebrow: 'Welcome back',
      title: 'Enter your password',
      subtitle: Align(
        alignment: Alignment.centerLeft,
        child: IdentityPill(
          value: widget.email,
          onChange: _isLoading ? null : () => Navigator.pop(context),
        ),
      ),
      error: _error,
      action: AuthPrimaryButton(
        label: 'Sign in',
        isLoading: _isLoading,
        onPressed: _signIn,
      ),
      secondaryAction: AuthTextButton(
        label: 'Forgot password?',
        onPressed: _isLoading ? null : _forgot,
      ),
      children: [
        AutofillGroup(
          child: AuthField(
            controller: _controller,
            hint: 'Password',
            icon: Symbols.lock,
            obscureText: _obscured,
            autofocus: true,
            enabled: !_isLoading,
            keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.go,
            autofillHints: const [AutofillHints.password],
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) => _signIn(),
            suffix: PasswordVisibilityToggle(
              obscured: _obscured,
              onToggle: () => setState(() => _obscured = !_obscured),
            ),
          ),
        ),
      ],
    );
  }
}
