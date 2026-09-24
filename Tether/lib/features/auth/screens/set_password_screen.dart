import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../services/auth_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SetPasswordScreen
//
// Shown exactly once — after a member's first OTP verification or magic link
// sign-in, before they see the main app. Sets the password on their Supabase
// auth account and marks password_set: true in their JWT metadata.
//
// After success the session is already live; we simply pop back to _AuthGate
// which will now route to MainNavigation (password_set is true in the claims
// once the session refreshes on next app open, or via the stream).
// ─────────────────────────────────────────────────────────────────────────────
class SetPasswordScreen extends ConsumerStatefulWidget {
  const SetPasswordScreen({super.key});

  @override
  ConsumerState<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends ConsumerState<SetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _passwordFocus.addListener(() => setState(() {}));
    _confirmFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _setPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      await ref.read(authServiceProvider).setPassword(_passwordCtrl.text);
      if (!mounted) return;
      // Let the root AuthGate replace this screen once the refreshed claims
      // arrive. This keeps a single MainNavigation in the widget tree.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not set password. Please try again.\n${e.toString().replaceAll('Exception: ', '')}';
      });
    }
  }

  // Password strength: returns 0–3
  int get _strength {
    final p = _passwordCtrl.text;
    if (p.length < 8) return 0;
    int score = 1;
    if (RegExp(r'[A-Z]').hasMatch(p)) score++;
    if (RegExp(r'[0-9!@#\$%^&*]').hasMatch(p)) score++;
    return score;
  }

  Color get _strengthColor {
    switch (_strength) {
      case 1: return Colors.red.shade400;
      case 2: return Colors.orange.shade400;
      case 3: return AppTheme.primaryContainer;
      default: return AppTheme.surfaceContainerHigh;
    }
  }

  String get _strengthLabel {
    switch (_strength) {
      case 1: return 'WEAK';
      case 2: return 'FAIR';
      case 3: return 'STRONG';
      default: return '';
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.containerMargin),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppTheme.stackLg),

                    // Icon + headline
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 80, height: 80,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryContainer.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.primaryContainer.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                              boxShadow: AppTheme.neonGlow(opacity: 0.25, blur: 28),
                            ),
                            child: const Icon(Symbols.lock,
                                size: 40, color: AppTheme.primaryContainer),
                          ),
                          const SizedBox(height: AppTheme.stackMd),
                          Text('CREATE YOUR\nPASSWORD',
                            style: Theme.of(context).textTheme.headlineLarge
                                ?.copyWith(height: 1.1),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppTheme.unit),
                          Text(
                            'You only do this once. After this you sign in\nwith email and password.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppTheme.onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppTheme.stackLg),

                    // ── Password field ────────────────────────────────────
                    _FieldLabel(
                      label: 'NEW PASSWORD',
                      icon: Symbols.lock,
                      focused: _passwordFocus.hasFocus,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordCtrl,
                      focusNode: _passwordFocus,
                      obscureText: _obscurePassword,
                      onChanged: (_) => setState(() {}),
                      style: Theme.of(context).textTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: 'At least 8 characters',
                        hintStyle: Theme.of(context).textTheme.bodyLarge
                            ?.copyWith(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5)),
                        suffixIcon: GestureDetector(
                          onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                          child: Icon(
                            _obscurePassword ? Symbols.visibility : Symbols.visibility_off,
                            size: 18, color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter a password';
                        if (v.length < 8) return 'Must be at least 8 characters';
                        return null;
                      },
                    ),

                    // Strength indicator
                    if (_passwordCtrl.text.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ...List.generate(3, (i) => Expanded(
                            child: Container(
                              height: 3,
                              margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                              decoration: BoxDecoration(
                                color: i < _strength
                                    ? _strengthColor
                                    : AppTheme.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          )),
                          const SizedBox(width: 8),
                          Text(_strengthLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _strengthColor,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: AppTheme.stackMd),

                    // ── Confirm password field ────────────────────────────
                    _FieldLabel(
                      label: 'CONFIRM PASSWORD',
                      icon: Symbols.lock_clock,
                      focused: _confirmFocus.hasFocus,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _confirmCtrl,
                      focusNode: _confirmFocus,
                      obscureText: _obscureConfirm,
                      style: Theme.of(context).textTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: 'Repeat your password',
                        hintStyle: Theme.of(context).textTheme.bodyLarge
                            ?.copyWith(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5)),
                        suffixIcon: GestureDetector(
                          onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          child: Icon(
                            _obscureConfirm ? Symbols.visibility : Symbols.visibility_off,
                            size: 18, color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Confirm your password';
                        if (v != _passwordCtrl.text) return 'Passwords do not match';
                        return null;
                      },
                      onFieldSubmitted: (_) => _setPassword(),
                    ),

                    const SizedBox(height: AppTheme.stackLg),

                    if (_errorMessage != null) ...[
                      _ErrorBanner(message: _errorMessage!),
                      const SizedBox(height: AppTheme.stackMd),
                    ],

                    PrimaryButton(
                      label: 'Set Password & Continue',
                      isLoading: _isLoading,
                      icon: Symbols.check_circle,
                      onPressed: _isLoading ? null : _setPassword,
                    ),

                    const SizedBox(height: AppTheme.stackLg),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool focused;
  const _FieldLabel({required this.label, required this.icon, required this.focused});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14,
          color: focused ? AppTheme.primaryContainer : AppTheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: focused ? AppTheme.primaryContainer : AppTheme.onSurfaceVariant)),
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
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter, vertical: AppTheme.stackSm),
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}
