import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../models/auth_models.dart';
import '../services/auth_service.dart';
import '../widgets/auth_widgets.dart';
import 'check_email_screen.dart';
import 'password_screen.dart';
import 'verify_code_screen.dart';

/// Step 1: one field that takes the email or phone the gym has on file.
/// The answer decides the next step (password, email link or SMS code).
class SignInScreen extends ConsumerStatefulWidget {
  final Gym gym;
  const SignInScreen({super.key, required this.gym});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  bool _looksLikePhone = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    final phone = AuthIdentifier.looksLikePhone(value);
    if (phone != _looksLikePhone || _error != null) {
      setState(() {
        _looksLikePhone = phone;
        _error = null;
      });
    }
  }

  Future<void> _continue() async {
    if (_isLoading) return;
    final id = AuthIdentifier.parse(_controller.text);
    if (id == null) {
      setState(() {
        _error = _controller.text.trim().isEmpty
            ? 'Enter your email or phone number.'
            : _looksLikePhone
                ? 'Enter the full phone number, including the country code, '
                    'e.g. +254712345678.'
                : 'That email doesn\'t look right. Check it and try again.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });
    final auth = ref.read(authServiceProvider);

    try {
      final check = await auth.checkMember(
        gymId: widget.gym.id,
        email: id.email,
        phone: id.phone,
      );
      if (!mounted) return;

      if (!check.exists) {
        setState(() {
          _isLoading = false;
          _error = '${widget.gym.name} doesn\'t have ${id.display} on file. '
              'Use the one you gave the front desk, or ask them to add you.';
        });
        return;
      }

      final Widget next;
      if (id.isEmail && check.hasPassword) {
        next = PasswordScreen(gym: widget.gym, email: id.email!);
      } else {
        await auth.requestOtp(RequestOtpDto(
          gymId: widget.gym.id,
          email: id.email,
          phone: id.phone,
        ));
        next = id.isEmail
            ? CheckEmailScreen(gym: widget.gym, email: id.email!)
            : VerifyCodeScreen(gym: widget.gym, phone: id.phone!);
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
      FocusScope.of(context).unfocus();
      Navigator.push(context, MaterialPageRoute(builder: (_) => next));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = authErrorMessage(
          e,
          fallback: 'Something went wrong. Please try again.',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthStepScaffold(
      gym: widget.gym,
      eyebrow: 'Sign in',
      title: 'What\'s your email or phone?',
      subtitle: Text('Use the one ${widget.gym.name} has on file.'),
      error: _error,
      action: AuthPrimaryButton(
        label: 'Continue',
        isLoading: _isLoading,
        onPressed: _continue,
      ),
      children: [
        AuthField(
          controller: _controller,
          hint: 'Email or phone number',
          icon: _looksLikePhone ? Symbols.call : Symbols.alternate_email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.go,
          autofillHints: const [AutofillHints.email, AutofillHints.telephoneNumber],
          autofocus: true,
          enabled: !_isLoading,
          onChanged: _onChanged,
          onSubmitted: (_) => _continue(),
        ),
      ],
    );
  }
}
