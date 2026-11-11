import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../models/auth_models.dart';

/// Brand colour from the gym's settings, falling back to the app accent.
Color gymAccent(Gym gym) {
  final hex = gym.primaryColor;
  if (hex == null) return AppTheme.primaryContainer;
  try {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  } catch (_) {
    return AppTheme.primaryContainer;
  }
}

/// Readable message for a failed auth request.
String authErrorMessage(Object error, {required String fallback}) {
  if (error is DioException) {
    if (error.response == null) {
      return 'Can\'t reach Tether right now. Check your connection and try again.';
    }
    final data = error.response?.data;
    final message = data is Map ? data['message'] : null;
    if (message is String && message.isNotEmpty) return message;
    if (message is List && message.isNotEmpty) return message.first.toString();
  }
  return fallback;
}

int? authStatusCode(Object error) =>
    error is DioException ? error.response?.statusCode : null;

final _emailPattern = RegExp(r'^[\w\-.+]+@([\w-]+\.)+[\w-]{2,}$');
final _phonePattern = RegExp(r'^\+?\d{7,15}$');

/// What the member typed on the sign-in step.
class AuthIdentifier {
  final String? email;
  final String? phone;

  const AuthIdentifier._({this.email, this.phone});

  /// Returns null when [raw] is neither an email nor a phone number.
  static AuthIdentifier? parse(String raw) {
    final value = raw.trim();
    if (value.contains('@')) {
      return _emailPattern.hasMatch(value)
          ? AuthIdentifier._(email: value.toLowerCase())
          : null;
    }
    final phone = value.replaceAll(RegExp(r'[\s\-().]'), '');
    return _phonePattern.hasMatch(phone) ? AuthIdentifier._(phone: phone) : null;
  }

  static bool looksLikePhone(String raw) {
    final value = raw.trim();
    return value.isNotEmpty && !value.contains('@') && RegExp(r'^[+\d]').hasMatch(value);
  }

  bool get isEmail => email != null;
  String get display => email ?? phone!;
}

/// One step of the sign-in flow: a big question, its inputs and a button
/// pinned to the bottom that rides above the keyboard.
class AuthStepScaffold extends StatelessWidget {
  final Gym? gym;
  final String? eyebrow;
  final String title;
  final Widget? subtitle;
  final List<Widget> children;
  final String? error;
  final Widget action;
  final Widget? secondaryAction;
  final bool showBack;
  final Widget? leading;

  const AuthStepScaffold({
    super.key,
    this.gym,
    this.eyebrow,
    required this.title,
    this.subtitle,
    this.children = const [],
    this.error,
    required this.action,
    this.secondaryAction,
    this.showBack = true,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final accent = gym == null ? AppTheme.primaryContainer : gymAccent(gym!);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        resizeToAvoidBottomInset: true,
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -1.1),
              radius: 1.1,
              colors: [accent.withValues(alpha: 0.13), AppTheme.surface],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                SizedBox(
                  height: 56,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.gutter,
                    ),
                    child: Row(
                      children: [
                        if (showBack) const AuthBackButton(),
                        const Spacer(),
                        if (gym != null) GymChip(gym: gym!),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.containerMargin,
                      AppTheme.stackMd,
                      AppTheme.containerMargin,
                      AppTheme.stackMd,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (leading != null) ...[
                          leading!,
                          const SizedBox(height: AppTheme.stackMd),
                        ],
                        if (eyebrow != null) ...[
                          Text(
                            eyebrow!.toUpperCase(),
                            style: text.labelMedium?.copyWith(
                              color: accent,
                              letterSpacing: 1.6,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        Text(
                          title,
                          style: text.displaySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1,
                            height: 1.08,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: AppTheme.stackSm),
                          DefaultTextStyle.merge(
                            style: text.bodyLarge?.copyWith(
                              color: AppTheme.onSurfaceVariant,
                              height: 1.45,
                            ),
                            child: subtitle!,
                          ),
                        ],
                        const SizedBox(height: AppTheme.stackLg - 8),
                        ...children,
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.containerMargin,
                    AppTheme.unit,
                    AppTheme.containerMargin,
                    AppTheme.gutter,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (error != null) ...[
                        AuthErrorBanner(message: error!),
                        const SizedBox(height: AppTheme.stackSm),
                      ],
                      action,
                      if (secondaryAction != null) ...[
                        const SizedBox(height: 4),
                        secondaryAction!,
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-width primary button used at the bottom of every step.
class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon = Symbols.arrow_forward,
  });

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      label: label,
      onPressed: isLoading ? null : onPressed,
      isLoading: isLoading,
      icon: icon,
      height: 56,
    );
  }
}

/// Quiet text button for the secondary choice on a step.
class AuthTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const AuthTextButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppTheme.onSurface,
        minimumSize: const Size.fromHeight(48),
        textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
      ),
      child: Text(label),
    );
  }
}

class AuthBackButton extends StatelessWidget {
  const AuthBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Back',
      onPressed: () => Navigator.maybePop(context),
      style: IconButton.styleFrom(
        backgroundColor: AppTheme.surfaceContainerHigh,
        fixedSize: const Size(40, 40),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      icon: const Icon(Symbols.arrow_back, size: 20, color: AppTheme.onSurface),
    );
  }
}

class GymChip extends StatelessWidget {
  final Gym gym;

  const GymChip({super.key, required this.gym});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GymAvatar(gym: gym, size: 28),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              gym.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.onSurface,
                    letterSpacing: 0,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Gym logo, or its initial on a tinted disc.
class GymAvatar extends StatelessWidget {
  final Gym gym;
  final double size;

  const GymAvatar({super.key, required this.gym, this.size = 48});

  @override
  Widget build(BuildContext context) {
    final accent = gymAccent(gym);
    final initial = Center(
      child: Text(
        gym.name.isNotEmpty ? gym.name[0].toUpperCase() : 'G',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: accent,
              fontSize: size * 0.42,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
      ),
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        shape: BoxShape.circle,
        border: Border.all(color: accent.withValues(alpha: 0.4), width: 1.2),
      ),
      child: ClipOval(
        child: gym.logoUrl == null
            ? initial
            : Image.network(
                gym.logoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => initial,
              ),
      ),
    );
  }
}

/// Large single-purpose input: big type, accent ring on focus.
class AuthField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final String? label;
  final IconData? icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final bool autofocus;
  final bool enabled;
  final Widget? suffix;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;

  const AuthField({
    super.key,
    required this.controller,
    required this.hint,
    this.label,
    this.icon,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.obscureText = false,
    this.autofocus = false,
    this.enabled = true,
    this.suffix,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
  });

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  FocusNode? _ownedFocus;
  FocusNode get _focus => widget.focusNode ?? (_ownedFocus ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant AuthField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownedFocus)?.removeListener(_onFocusChange);
      _focus.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    _ownedFocus?.dispose();
    super.dispose();
  }

  void _onFocusChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final focused = _focus.hasFocus;
    final iconColor =
        focused ? AppTheme.primaryContainer : AppTheme.onSurfaceVariant;
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
          borderSide: BorderSide(color: color, width: width),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: text.labelLarge?.copyWith(
              color: AppTheme.onSurfaceVariant,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: widget.controller,
          focusNode: _focus,
          autofocus: widget.autofocus,
          enabled: widget.enabled,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          autofillHints: widget.autofillHints,
          obscureText: widget.obscureText,
          autocorrect: false,
          enableSuggestions: !widget.obscureText &&
              widget.keyboardType != TextInputType.emailAddress,
          textCapitalization: widget.textCapitalization,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          style: text.titleLarge?.copyWith(
            color: AppTheme.onSurface,
            fontWeight: FontWeight.w500,
            fontSize: 20,
          ),
          cursorColor: AppTheme.primaryContainer,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: text.titleLarge?.copyWith(
              color: AppTheme.onSurfaceVariant.withValues(alpha: 0.45),
              fontWeight: FontWeight.w400,
              fontSize: 20,
            ),
            filled: true,
            fillColor: AppTheme.surfaceContainer,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTheme.containerMargin,
              vertical: 20,
            ),
            prefixIcon: widget.icon == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(left: 16, right: 10),
                    child: Icon(widget.icon, size: 22, color: iconColor),
                  ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0),
            suffixIcon: widget.suffix,
            border: border(Colors.white.withValues(alpha: 0.08)),
            enabledBorder: border(Colors.white.withValues(alpha: 0.08)),
            disabledBorder: border(Colors.white.withValues(alpha: 0.04)),
            focusedBorder: border(AppTheme.primaryContainer, 1.5),
          ),
        ),
      ],
    );
  }
}

/// Eye toggle for password fields.
class PasswordVisibilityToggle extends StatelessWidget {
  final bool obscured;
  final VoidCallback onToggle;

  const PasswordVisibilityToggle({
    super.key,
    required this.obscured,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: obscured ? 'Show password' : 'Hide password',
      onPressed: onToggle,
      icon: Icon(
        obscured ? Symbols.visibility : Symbols.visibility_off,
        size: 22,
        color: AppTheme.onSurfaceVariant,
      ),
    );
  }
}

/// Shows who is signing in, with a way to go back and change it.
class IdentityPill extends StatelessWidget {
  final String value;
  final IconData icon;
  final VoidCallback? onChange;

  const IdentityPill({
    super.key,
    required this.value,
    this.icon = Symbols.mail,
    this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodyMedium?.copyWith(
                color: AppTheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onChange != null) ...[
            const SizedBox(width: 6),
            TextButton(
              onPressed: onChange,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryContainer,
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Change'),
            ),
          ] else
            const SizedBox(width: 6),
        ],
      ),
    );
  }
}

/// Large tinted icon used at the top of confirmation steps.
class AuthStepIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const AuthStepIcon({
    super.key,
    required this.icon,
    this.color = AppTheme.primaryContainer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusXxl + 4),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Icon(icon, size: 30, color: color),
    );
  }
}

class AuthErrorBanner extends StatelessWidget {
  final String message;
  const AuthErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.stackSm),
        decoration: BoxDecoration(
          color: AppTheme.errorContainer.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Symbols.error, size: 18, color: AppTheme.error),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.error,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Counts down from [seconds] after each [restart]; drives resend buttons.
class ResendCooldown extends ChangeNotifier {
  final int seconds;
  int _remaining = 0;
  Timer? _timer;

  ResendCooldown({this.seconds = 30}) {
    restart();
  }

  int get remaining => _remaining;
  bool get ready => _remaining == 0;

  void restart() {
    _timer?.cancel();
    _remaining = seconds;
    notifyListeners();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _remaining--;
      if (_remaining <= 0) {
        _remaining = 0;
        timer.cancel();
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
