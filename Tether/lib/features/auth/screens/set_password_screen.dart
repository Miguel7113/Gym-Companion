import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/auth_widgets.dart';

const _minPasswordLength = 8;

/// Last step of first sign-in (name + password), or choosing a new password
/// after opening a reset link. The auth gate shows this as the root screen
/// and swaps to the app once the password is saved.
class SetPasswordScreen extends ConsumerStatefulWidget {
  final bool isReset;
  final VoidCallback? onDone;

  const SetPasswordScreen({super.key, this.isReset = false, this.onDone});

  @override
  ConsumerState<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends ConsumerState<SetPasswordScreen> {
  final _nameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _obscured = true;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final meta = Supabase.instance.client.auth.currentUser?.userMetadata;
    final name = meta?['display_name'];
    if (name is String) _nameCtrl.text = name.trim();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isLoading) return;
    final name = _nameCtrl.text.trim();
    final password = _passwordCtrl.text;
    final String? problem;
    if (!widget.isReset && name.length < 2) {
      problem = 'Add your name so your gym and buddies know it\'s you.';
    } else if (password.length < _minPasswordLength) {
      problem = 'Use at least $_minPasswordLength characters for your password.';
    } else {
      problem = null;
    }
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });
    final auth = ref.read(authServiceProvider);
    try {
      if (!widget.isReset) await auth.setDisplayName(name);
      await auth.setPassword(password);
      TextInput.finishAutofillContext();
      widget.onDone?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = authErrorMessage(
          e,
          fallback: 'Could not save your password. Please try again.',
        );
      });
    }
  }

  Future<void> _signOut() async {
    await ref.read(authServiceProvider).signOut();
    widget.onDone?.call();
  }

  @override
  Widget build(BuildContext context) {
    final email = Supabase.instance.client.auth.currentUser?.email;

    return AuthStepScaffold(
      showBack: false,
      eyebrow: widget.isReset ? 'Reset password' : 'Last step',
      title: widget.isReset ? 'Choose a new password' : 'Set up your account',
      subtitle: Text(
        widget.isReset
            ? 'You\'ll use it to sign in${email == null ? '' : ' as $email'}.'
            : 'Next time you\'ll sign in with your email and this password.',
      ),
      error: _error,
      action: AuthPrimaryButton(
        label: widget.isReset ? 'Save password' : 'Finish',
        icon: Symbols.check,
        isLoading: _isLoading,
        onPressed: _save,
      ),
      secondaryAction: AuthTextButton(
        label: email == null ? 'Sign out' : 'Not $email? Sign out',
        onPressed: _isLoading ? null : _signOut,
      ),
      children: [
        AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.isReset) ...[
                AuthField(
                  controller: _nameCtrl,
                  label: 'Your name',
                  hint: 'e.g. Marcus Reid',
                  icon: Symbols.badge,
                  autofocus: _nameCtrl.text.isEmpty,
                  enabled: !_isLoading,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  onSubmitted: (_) => _passwordFocus.requestFocus(),
                ),
                const SizedBox(height: AppTheme.stackMd),
              ],
              AuthField(
                controller: _passwordCtrl,
                focusNode: _passwordFocus,
                label: widget.isReset ? 'New password' : 'Password',
                hint: 'At least $_minPasswordLength characters',
                icon: Symbols.lock,
                obscureText: _obscured,
                autofocus: widget.isReset || _nameCtrl.text.isNotEmpty,
                enabled: !_isLoading,
                keyboardType: TextInputType.visiblePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                onChanged: (_) => setState(() => _error = null),
                onSubmitted: (_) => _save(),
                suffix: PasswordVisibilityToggle(
                  obscured: _obscured,
                  onToggle: () => setState(() => _obscured = !_obscured),
                ),
              ),
              const SizedBox(height: AppTheme.stackSm),
              _StrengthMeter(password: _passwordCtrl.text),
            ],
          ),
        ),
      ],
    );
  }
}

class _StrengthMeter extends StatelessWidget {
  final String password;
  const _StrengthMeter({required this.password});

  int get _score {
    if (password.length < _minPasswordLength) return password.isEmpty ? 0 : 1;
    var score = 2;
    final mixed = RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password);
    final symbolOrDigit = RegExp(r'[0-9!@#$%^&*(),.?":{}|<>_\-]').hasMatch(password);
    if (mixed && symbolOrDigit) score++;
    if (password.length >= 12) score++;
    return score.clamp(0, 4);
  }

  @override
  Widget build(BuildContext context) {
    final score = _score;
    const labels = ['', 'Too short', 'Okay', 'Good', 'Strong'];
    final colors = [
      AppTheme.surfaceContainerHigh,
      AppTheme.toneDanger,
      AppTheme.toneWarning,
      AppTheme.primaryContainer,
      AppTheme.toneSuccess,
    ];
    final color = colors[score];

    return Row(
      children: [
        for (var i = 1; i <= 4; i++) ...[
          if (i > 1) const SizedBox(width: 4),
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: i <= score ? color : AppTheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
        const SizedBox(width: 10),
        SizedBox(
          width: 64,
          child: Text(
            labels[score],
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}
