import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_dialog.dart';
import '../models/auth_models.dart';
import '../services/auth_service.dart';
import '../widgets/auth_widgets.dart';

/// First-time email sign-in: the member opens the link we just sent.
class CheckEmailScreen extends ConsumerStatefulWidget {
  final Gym gym;
  final String email;

  const CheckEmailScreen({super.key, required this.gym, required this.email});

  @override
  ConsumerState<CheckEmailScreen> createState() => _CheckEmailScreenState();
}

class _CheckEmailScreenState extends ConsumerState<CheckEmailScreen> {
  final _cooldown = ResendCooldown();
  bool _isSending = false;
  String? _error;

  @override
  void dispose() {
    _cooldown.dispose();
    super.dispose();
  }

  Future<void> _resend() async {
    setState(() {
      _isSending = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).requestOtp(
            RequestOtpDto(gymId: widget.gym.id, email: widget.email),
          );
      if (!mounted) return;
      _cooldown.restart();
      showAppSnack(context, 'New link sent', tone: AppSnackTone.success);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = authErrorMessage(
            e,
            fallback: 'Could not send a new link. Try again in a minute.',
          ));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable: _cooldown,
      builder: (context, _) => AuthStepScaffold(
        gym: widget.gym,
        leading: const AuthStepIcon(icon: Symbols.mark_email_unread),
        title: 'Check your email',
        subtitle: Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'We sent a sign-in link to '),
              TextSpan(
                text: widget.email,
                style: const TextStyle(
                  color: AppTheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const TextSpan(
                text: '. Open it on this phone and Tether will sign you in.',
              ),
            ],
          ),
        ),
        error: _error,
        action: AuthPrimaryButton(
          label: _cooldown.ready
              ? 'Resend link'
              : 'Resend in ${_cooldown.remaining}s',
          icon: Symbols.refresh,
          isLoading: _isSending,
          onPressed: _cooldown.ready ? _resend : null,
        ),
        secondaryAction: AuthTextButton(
          label: 'Use a different email',
          onPressed: () => Navigator.pop(context),
        ),
        children: [
          for (final tip in const [
            'The link works for 1 hour.',
            'Can\'t find it? Check your spam or promotions folder.',
            'You\'ll set a password next, so this only happens once.',
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2, right: 10),
                    child: Icon(
                      Symbols.check_circle,
                      size: 18,
                      color: AppTheme.primaryContainer,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      tip,
                      style: text.bodyMedium?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                        height: 1.4,
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
