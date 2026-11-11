import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_dialog.dart';
import '../models/auth_models.dart';
import '../services/auth_service.dart';
import '../widgets/auth_widgets.dart';

const _codeLength = 6;

/// Phone sign-in: enter the six-digit code we texted.
class VerifyCodeScreen extends ConsumerStatefulWidget {
  final Gym gym;
  final String phone;

  const VerifyCodeScreen({super.key, required this.gym, required this.phone});

  @override
  ConsumerState<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends ConsumerState<VerifyCodeScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  final _cooldown = ResendCooldown();
  bool _isVerifying = false;
  bool _isSending = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    _cooldown.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() => _error = null);
    if (value.length == _codeLength) _verify();
  }

  Future<void> _verify() async {
    if (_isVerifying || _controller.text.length != _codeLength) return;
    setState(() {
      _isVerifying = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).verifyOtp(VerifyOtpDto(
            gymId: widget.gym.id,
            phone: widget.phone,
            token: _controller.text,
          ));
      // The auth gate takes over: new members set a password, everyone
      // else lands in the app.
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      _controller.clear();
      _focus.requestFocus();
      setState(() {
        _isVerifying = false;
        _error = authStatusCode(e) == null || authStatusCode(e)! >= 500
            ? authErrorMessage(e, fallback: 'Could not check the code. Try again.')
            : 'That code didn\'t work. Check the latest text and try again.';
      });
    }
  }

  Future<void> _resend() async {
    setState(() {
      _isSending = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).requestOtp(
            RequestOtpDto(gymId: widget.gym.id, phone: widget.phone),
          );
      if (!mounted) return;
      _cooldown.restart();
      _controller.clear();
      showAppSnack(context, 'New code sent', tone: AppSnackTone.success);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = authErrorMessage(
            e,
            fallback: 'Could not send a new code. Try again in a minute.',
          ));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _cooldown,
      builder: (context, _) => AuthStepScaffold(
        gym: widget.gym,
        eyebrow: 'Verify your number',
        title: 'Enter the 6-digit code',
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('We texted it to'),
            const SizedBox(height: 10),
            IdentityPill(
              value: widget.phone,
              icon: Symbols.call,
              onChange: _isVerifying ? null : () => Navigator.pop(context),
            ),
          ],
        ),
        error: _error,
        action: AuthPrimaryButton(
          label: 'Verify',
          icon: Symbols.check,
          isLoading: _isVerifying,
          onPressed: _controller.text.length == _codeLength ? _verify : null,
        ),
        secondaryAction: AuthTextButton(
          label: _isSending
              ? 'Sending…'
              : _cooldown.ready
                  ? 'Text me a new code'
                  : 'Text me a new code in ${_cooldown.remaining}s',
          onPressed: _cooldown.ready && !_isSending && !_isVerifying ? _resend : null,
        ),
        children: [
          CodeInput(
            controller: _controller,
            focusNode: _focus,
            enabled: !_isVerifying,
            hasError: _error != null,
            onChanged: _onChanged,
          ),
        ],
      ),
    );
  }
}

/// Six digit boxes backed by one real text field, so paste and SMS autofill
/// fill every box at once.
class CodeInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final bool hasError;
  final ValueChanged<String> onChanged;

  const CodeInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    this.enabled = true,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => focusNode.requestFocus(),
      child: Stack(
        children: [
          ListenableBuilder(
            listenable: Listenable.merge([controller, focusNode]),
            builder: (context, _) {
              final value = controller.text;
              return Row(
                children: [
                  for (var i = 0; i < _codeLength; i++) ...[
                    if (i > 0) SizedBox(width: i == _codeLength ~/ 2 ? 14 : 8),
                    Expanded(
                      child: _DigitBox(
                        digit: i < value.length ? value[i] : null,
                        active: focusNode.hasFocus &&
                            (i == value.length ||
                                (i == _codeLength - 1 && value.length == _codeLength)),
                        hasError: hasError,
                        style: text.headlineMedium,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                enabled: enabled,
                autofocus: true,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                maxLength: _codeLength,
                showCursor: false,
                enableInteractiveSelection: false,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: onChanged,
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DigitBox extends StatelessWidget {
  final String? digit;
  final bool active;
  final bool hasError;
  final TextStyle? style;

  const _DigitBox({
    required this.digit,
    required this.active,
    required this.hasError,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError
        ? AppTheme.error.withValues(alpha: 0.7)
        : active
            ? AppTheme.primaryContainer
            : digit != null
                ? AppTheme.primaryContainer.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.08);

    return AspectRatio(
      aspectRatio: 0.82,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(color: borderColor, width: active ? 1.8 : 1),
        ),
        child: Text(
          digit ?? '',
          style: style?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurface,
          ),
        ),
      ),
    );
  }
}
