import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/glass_card.dart';
import '../models/auth_models.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'otp_verification_screen.dart';

class OtpRequestScreen extends ConsumerStatefulWidget {
  final Gym gym;
  const OtpRequestScreen({super.key, required this.gym});

  @override
  ConsumerState<OtpRequestScreen> createState() => _OtpRequestScreenState();
}

class _OtpRequestScreenState extends ConsumerState<OtpRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _displayNameController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _useEmail = true;
  bool _isCoachLogin = false;

  // Focus nodes for ghost-input lime highlight behavior
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _nameFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    for (final node in [_emailFocus, _phoneFocus, _nameFocus]) {
      node.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _displayNameController.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _useEmail ? _emailController.text.trim() : null;
    final phone = !_useEmail ? _phoneController.text.trim() : null;

    try {
      // Coach path: skip roster/OTP gate — go straight to password login.
      if (_isCoachLogin) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LoginScreen(
              gym: widget.gym,
              email: email ?? '',
              initialCoachLogin: true,
            ),
          ),
        );
        return;
      }

      // ── Step 1: pre-check before sending anything ──────────────────────
      final check = await ref.read(authServiceProvider).checkMember(
        gymId: widget.gym.id,
        email: email,
        phone: phone,
      );

      if (!mounted) return;

      // Not on the roster at all
      if (!check.exists) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Your account was not found as a current gym member. '
              'Contact your gym admin.';
        });
        return;
      }

      // Returning member with a password — go straight to LoginScreen
      if (check.hasPassword) {
        setState(() => _isLoading = false);
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LoginScreen(
              gym: widget.gym,
              email: email ?? '',
            ),
          ),
        );
        return;
      }

      // ── Step 2: new member — send OTP / magic link ─────────────────────
      final dto = RequestOtpDto(
        gymId: widget.gym.id,
        email: email,
        phone: phone,
        displayName: _displayNameController.text.trim().isEmpty
            ? null
            : _displayNameController.text.trim(),
      );

      await ref.read(authServiceProvider).requestOtp(dto);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (_useEmail) {
        _showMagicLinkSentDialog();
      } else {
        _navigateToVerification();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _navigateToVerification() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtpVerificationScreen(
          gym: widget.gym,
          email: _useEmail ? _emailController.text.trim() : null,
          phone: !_useEmail ? _phoneController.text.trim() : null,
          displayName: _displayNameController.text.trim().isEmpty
              ? null
              : _displayNameController.text.trim(),
        ),
      ),
    );
  }

  void _showMagicLinkSentDialog() {
    final email = _emailController.text.trim();
    showAppInfoDialog(
      context,
      icon: Symbols.mark_email_unread,
      title: 'Check your email',
      message: 'We sent a sign-in link to $email. Tap it to log in; it opens '
          'the app automatically.\n\nThe link expires in 1 hour.',
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final gym = widget.gym;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      // No AppBar — we draw our own back button
      body: Stack(
        children: [
          // ── Subtle background noise / texture ───────────────────────────
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
                // ── Top bar ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.gutter,
                    vertical: AppTheme.unit,
                  ),
                  child: Row(
                    children: [
                      // Back button
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
                          child: const Icon(
                            Symbols.arrow_back,
                            size: 20,
                            color: AppTheme.onSurface,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Gym name label
                      Text(
                        gym.name.toUpperCase(),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: AppTheme.primaryContainer,
                            ),
                      ),
                    ],
                  ),
                ),

                // ── Scrollable form ──────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.containerMargin,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppTheme.stackMd),

                          // Gym avatar + headline
                          _GymHeader(gym: gym),

                          const SizedBox(height: AppTheme.stackLg),

                          // Email / Phone toggle (coaches use email only)
                          if (!_isCoachLogin) ...[
                            Text(
                              'Contact method',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(color: AppTheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: AppTheme.stackSm),
                            _ContactToggle(
                              useEmail: _useEmail,
                              onChanged: (v) =>
                                  setState(() => _useEmail = v),
                            ),
                            const SizedBox(height: AppTheme.stackMd),
                          ],

                          // Email or Phone input
                          if (_useEmail || _isCoachLogin)
                            _GhostField(
                              controller: _emailController,
                              focusNode: _emailFocus,
                              label: 'Email address',
                              hint: 'your@email.com',
                              keyboardType: TextInputType.emailAddress,
                              icon: Symbols.mail,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Enter your email address';
                                }
                                if (!RegExp(
                                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                    .hasMatch(v)) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            )
                          else
                            _GhostField(
                              controller: _phoneController,
                              focusNode: _phoneFocus,
                              label: 'Phone number',
                              hint: '+2547XXXXXXXX',
                              keyboardType: TextInputType.phone,
                              icon: Symbols.phone,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Enter your phone number';
                                }
                                return null;
                              },
                            ),

                          if (!_isCoachLogin) ...[
                            const SizedBox(height: AppTheme.stackMd),
                            _GhostField(
                              controller: _displayNameController,
                              focusNode: _nameFocus,
                              label: 'Display name',
                              hint: 'Optional — e.g. Marcus R.',
                              icon: Symbols.person,
                              validator: (_) => null,
                            ),
                          ],

                          const SizedBox(height: AppTheme.stackMd),

                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              "I'm a coach",
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            subtitle: Text(
                              'Skip member check — use staff email & password',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.onSurfaceVariant,
                                  ),
                            ),
                            value: _isCoachLogin,
                            activeThumbColor: AppTheme.onPrimaryContainer,
                            activeTrackColor: AppTheme.primaryContainer,
                            onChanged: _isLoading
                                ? null
                                : (value) => setState(() {
                                      _isCoachLogin = value;
                                      if (value) _useEmail = true;
                                    }),
                          ),

                          const SizedBox(height: AppTheme.stackLg),

                          // Error message
                          if (_errorMessage != null) ...[
                            _ErrorBanner(message: _errorMessage!),
                            const SizedBox(height: AppTheme.stackMd),
                          ],

                          // Primary CTA
                          PrimaryButton(
                            label: _isCoachLogin
                                ? 'Continue as coach'
                                : (_useEmail ? 'Continue' : 'Send Code'),
                            isLoading: _isLoading,
                            icon: _isCoachLogin || _useEmail
                                ? Symbols.arrow_forward
                                : Symbols.send,
                            onPressed: _isLoading ? null : _requestOtp,
                          ),

                          const SizedBox(height: AppTheme.stackMd),

                          Center(
                            child: Text(
                              _isCoachLogin
                                  ? 'Next: enter your staff password.'
                                  : (_useEmail
                                      ? 'We\'ll check your membership, then sign you in.'
                                      : 'We\'ll send a 6-digit code to your phone.'),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppTheme.onSurfaceVariant
                                        .withOpacity(0.6),
                                  ),
                              textAlign: TextAlign.center,
                            ),
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
// _GymHeader — large gym avatar + name + tagline
// ─────────────────────────────────────────────────────────────────────────────
class _GymHeader extends StatelessWidget {
  final Gym gym;
  const _GymHeader({required this.gym});

  @override
  Widget build(BuildContext context) {
    Color accent = AppTheme.primaryContainer;
    if (gym.primaryColor != null) {
      try {
        accent =
            Color(int.parse(gym.primaryColor!.replaceFirst('#', '0xFF')));
      } catch (_) {}
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: accent.withOpacity(0.4), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(0.2),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: ClipOval(
                child: gym.logoUrl != null
                    ? Image.network(gym.logoUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(
                            gym.name[0].toUpperCase(),
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(color: accent),
                          ),
                        ))
                    : Center(
                        child: Text(
                          gym.name.isNotEmpty
                              ? gym.name[0].toUpperCase()
                              : 'G',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(color: accent),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: AppTheme.stackSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gym.name.toUpperCase(),
                    style: Theme.of(context)
                        .textTheme
                        .headlineLarge
                        ?.copyWith(
                          color: AppTheme.onSurface,
                        ),
                  ),
                  Text(
                    'Member sign in',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ContactToggle — Email / Phone pill toggle
// ─────────────────────────────────────────────────────────────────────────────
class _ContactToggle extends StatelessWidget {
  final bool useEmail;
  final ValueChanged<bool> onChanged;

  const _ContactToggle({required this.useEmail, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(
        children: [
          _ToggleOption(
            label: 'EMAIL',
            icon: Symbols.mail,
            isSelected: useEmail,
            onTap: () => onChanged(true),
          ),
          _ToggleOption(
            label: 'PHONE',
            icon: Symbols.phone,
            isSelected: !useEmail,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryContainer.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            border: isSelected
                ? Border.all(
                    color: AppTheme.primaryContainer.withOpacity(0.4))
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected
                    ? AppTheme.primaryContainer
                    : AppTheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: isSelected
                          ? AppTheme.primaryContainer
                          : AppTheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _GhostField — bottom-border only input with lime focus state
// ─────────────────────────────────────────────────────────────────────────────
class _GhostField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final IconData icon;
  final String? Function(String?) validator;

  const _GhostField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.icon,
    required this.validator,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final isFocused = focusNode.hasFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isFocused
                  ? AppTheme.primaryContainer
                  : AppTheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isFocused
                        ? AppTheme.primaryContainer
                        : AppTheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.onSurface,
              ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.onSurfaceVariant.withOpacity(0.5),
                ),
            // Rely on the theme's UnderlineInputBorder
            filled: false,
          ),
          validator: validator,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ErrorBanner — red-tinted glass strip for error messages
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
        border: Border.all(
          color: AppTheme.error.withOpacity(0.3),
          width: 1,
        ),
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
