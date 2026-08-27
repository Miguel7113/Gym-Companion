import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../models/auth_models.dart';
import '../services/auth_service.dart';
import 'set_password_screen.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final Gym gym;
  final String? email;
  final String? phone;
  final String? displayName;

  const OtpVerificationScreen({
    super.key,
    required this.gym,
    this.email,
    this.phone,
    this.displayName,
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState
    extends ConsumerState<OtpVerificationScreen> {
  // 6 separate controllers + focus nodes for the split OTP boxes
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otpValue =>
      _controllers.map((c) => c.text).join();

  bool get _isComplete => _otpValue.length == 6;

  void _onDigitEntered(int index, String value) {
    if (value.isEmpty) {
      // Backspace — move focus back
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
        _controllers[index - 1].clear();
      }
    } else if (value.length == 1) {
      // Move to next field
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        // Auto-submit when last digit entered
        if (_isComplete) _verifyOtp();
      }
    }
    setState(() {});
  }

  Future<void> _verifyOtp() async {
    if (!_isComplete) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dto = VerifyOtpDto(
        gymId: widget.gym.id,
        email: widget.email,
        phone: widget.phone,
        token: _otpValue,
        displayName: widget.displayName,
      );

      // Returns true if this is a brand-new account (needs password setup)
      final needsPasswordSetup =
          await ref.read(authServiceProvider).verifyOtp(dto);

      if (!mounted) return;
      FocusScope.of(context).unfocus();

      if (needsPasswordSetup) {
        // First-time signup — ask them to create a password before entering the app
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SetPasswordScreen()),
        );
      }
      // If returning user (needsPasswordSetup == false), _AuthGate stream
      // picks up the new session and routes to MainNavigation automatically.
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid or expired code. Please try again.';
      });
      _clearAndFocus();
    }
  }

  Future<void> _resendCode() async {
    setState(() {
      _isResending = true;
      _errorMessage = null;
    });
    try {
      final dto = RequestOtpDto(
        gymId: widget.gym.id,
        email: widget.email,
        phone: widget.phone,
        displayName: widget.displayName,
      );
      await ref.read(authServiceProvider).requestOtp(dto);
      if (!mounted) return;
      setState(() => _isResending = false);
      _showResendSuccess();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isResending = false;
        _errorMessage = 'Could not resend code. Try again.';
      });
    }
  }

  void _clearAndFocus() {
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();
  }

  void _showResendSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.surfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        content: Row(
          children: [
            const Icon(Symbols.check_circle,
                color: AppTheme.primaryContainer, size: 18),
            const SizedBox(width: 8),
            Text(
              'New code sent',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: AppTheme.onSurface),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contact = widget.email ?? widget.phone ?? '';
    // Mask the contact for privacy (show first 3 chars + ***)
    final maskedContact = contact.length > 5
        ? '${contact.substring(0, 3)}***${contact.substring(contact.length - 3)}'
        : contact;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(
        children: [
          // Subtle gradient bg
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0D0E12),
                    AppTheme.surface,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Top bar ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.gutter,
                    vertical: AppTheme.unit,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerHigh,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: const Icon(Symbols.arrow_back,
                              size: 20, color: AppTheme.onSurface),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'VERIFY',
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(color: AppTheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),

                // ── Content ────────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.containerMargin,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppTheme.stackLg),

                        // Icon + headline
                        Center(
                          child: Column(
                            children: [
                              // Shield / verify icon in lime circle with glow
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryContainer
                                      .withOpacity(0.12),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.primaryContainer
                                        .withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                  boxShadow: AppTheme.neonGlow(
                                      opacity: 0.2, blur: 24),
                                ),
                                child: const Icon(
                                  Symbols.verified_user,
                                  size: 36,
                                  color: AppTheme.primaryContainer,
                                ),
                              ),
                              const SizedBox(height: AppTheme.stackMd),
                              Text(
                                'CHECK YOUR\nINBOX',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineLarge
                                    ?.copyWith(
                                      height: 1.1,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppTheme.unit),
                              RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                          color: AppTheme.onSurfaceVariant),
                                  children: [
                                    const TextSpan(
                                        text: 'We sent a 6-digit code to '),
                                    TextSpan(
                                      text: maskedContact,
                                      style: TextStyle(
                                        color: AppTheme.onSurface,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppTheme.stackLg),

                        // ── OTP boxes ──────────────────────────────────
                        Text(
                          'VERIFICATION CODE',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(color: AppTheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: AppTheme.stackSm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(
                            6,
                            (i) => _OtpBox(
                              controller: _controllers[i],
                              focusNode: _focusNodes[i],
                              onChanged: (v) => _onDigitEntered(i, v),
                              autofocus: i == 0,
                            ),
                          ),
                        ),

                        const SizedBox(height: AppTheme.stackLg),

                        // Error message
                        if (_errorMessage != null) ...[
                          _ErrorBanner(message: _errorMessage!),
                          const SizedBox(height: AppTheme.stackMd),
                        ],

                        // Verify CTA
                        PrimaryButton(
                          label: 'Verify & Sign In',
                          isLoading: _isLoading,
                          onPressed: (_isComplete && !_isLoading)
                              ? _verifyOtp
                              : null,
                        ),

                        const SizedBox(height: AppTheme.stackMd),

                        // Resend row
                        Center(
                          child: _isResending
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                      AppTheme.primaryContainer,
                                    ),
                                  ),
                                )
                              : GestureDetector(
                                  onTap: _resendCode,
                                  child: RichText(
                                    text: TextSpan(
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppTheme.onSurfaceVariant
                                                .withOpacity(0.6),
                                          ),
                                      children: [
                                        const TextSpan(
                                            text: "Didn't receive it? "),
                                        TextSpan(
                                          text: 'Resend code',
                                          style: TextStyle(
                                            color: AppTheme.primaryContainer,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                        ),

                        const SizedBox(height: AppTheme.stackLg),
                      ],
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
// _OtpBox — single digit input box, lime border on focus / when filled
// ─────────────────────────────────────────────────────────────────────────────
class _OtpBox extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final bool autofocus;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    this.autofocus = false,
  });

  @override
  State<_OtpBox> createState() => _OtpBoxState();
}

class _OtpBoxState extends State<_OtpBox> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = widget.focusNode.hasFocus;
    final isFilled = widget.controller.text.isNotEmpty;
    final showLime = isFocused || isFilled;

    return Container(
      width: 44,
      height: 56,
      decoration: BoxDecoration(
        color: isFilled
            ? AppTheme.primaryContainer.withOpacity(0.08)
            : AppTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(
          color: showLime
              ? AppTheme.primaryContainer.withOpacity(isFocused ? 1.0 : 0.5)
              : Colors.white.withOpacity(0.1),
          width: isFocused ? 2 : 1,
        ),
        boxShadow: isFocused ? AppTheme.neonGlow(opacity: 0.15) : null,
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: Theme.of(context).textTheme.displayMedium?.copyWith(
              fontSize: 24,
              color: isFilled ? AppTheme.primaryContainer : AppTheme.onSurface,
            ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          counterText: '',
          filled: false,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ErrorBanner — shared error banner (same as otp_request_screen)
// ─────────────────────────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.gutter,
        vertical: AppTheme.stackSm,
      ),
      decoration: BoxDecoration(
        color: AppTheme.errorContainer.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Symbols.error, size: 16, color: AppTheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.error,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
