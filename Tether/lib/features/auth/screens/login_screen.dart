import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../models/auth_models.dart';
import '../services/auth_service.dart';
import 'forgot_password_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LoginScreen
//
// Shown to returning members (checkMember returned hasPassword: true).
// Email is pre-filled from OtpRequestScreen. After successful login the
// Supabase session is stored and _AuthGate routes to MainNavigation.
// ─────────────────────────────────────────────────────────────────────────────
class LoginScreen extends ConsumerStatefulWidget {
  final Gym gym;
  final String email;
  final bool initialCoachLogin;

  const LoginScreen({
    super.key,
    required this.gym,
    required this.email,
    this.initialCoachLogin = false,
  });

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailCtrl;
  final _passwordCtrl = TextEditingController();
  final _passwordFocus = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;
  late bool _isCoachLogin;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.email);
    _isCoachLogin = widget.initialCoachLogin;
    _passwordFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final email = _emailCtrl.text.trim();
      final password = _passwordCtrl.text;
      if (_isCoachLogin) {
        await ref.read(authServiceProvider).coachLogin(
          email: email,
          password: password,
        );
      } else {
        await ref.read(authServiceProvider).login(
          gymId: widget.gym.id,
          email: email,
          password: password,
        );
      }
      if (!mounted) return;
      // The root AuthGate owns the authenticated app route. Returning to it
      // avoids mounting a second MainNavigation while the auth stream rebuilds.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      final raw = e.toString().replaceAll('Exception: ', '');
      setState(() {
        _isLoading = false;
        final msg = raw.toLowerCase();
        if (msg.contains('no coach account') || msg.contains('403')) {
          _errorMessage = 'No coach account for this gym.';
        } else if (msg.contains('incorrect') || msg.contains('invalid') || msg.contains('401')) {
          _errorMessage = 'Incorrect email or password.';
        } else if (msg.contains('not found') || msg.contains('gym member')) {
          _errorMessage = 'Your account was not found as a current gym member. Contact your gym admin.';
        } else {
          _errorMessage = 'Could not sign in. Please try again.\n$raw';
        }
      });
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
            child: Column(
              children: [
                // ── Top bar ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.gutter, vertical: AppTheme.unit),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerHigh,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: const Icon(Symbols.arrow_back, size: 20, color: AppTheme.onSurface),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        widget.gym.name.toUpperCase(),
                        style: Theme.of(context).textTheme.labelLarge
                            ?.copyWith(color: AppTheme.primaryContainer),
                      ),
                    ],
                  ),
                ),

                // ── Form ─────────────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.containerMargin),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppTheme.stackMd),

                          // Icon + headline
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  width: 72, height: 72,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryContainer.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppTheme.primaryContainer.withValues(alpha: 0.3),
                                      width: 1.5,
                                    ),
                                    boxShadow: AppTheme.neonGlow(opacity: 0.2, blur: 24),
                                  ),
                                  child: const Icon(Symbols.lock_open,
                                      size: 36, color: AppTheme.primaryContainer),
                                ),
                                const SizedBox(height: AppTheme.stackMd),
                                Text('Welcome back',
                                  style: Theme.of(context).textTheme.headlineLarge),
                                const SizedBox(height: AppTheme.unit),
                                Text('Sign in to ${widget.gym.name}',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: AppTheme.onSurfaceVariant),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: AppTheme.stackLg),

                          // Email (pre-filled, editable)
                          _FieldLabel(label: 'Email address', icon: Symbols.mail, focused: false),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            style: Theme.of(context).textTheme.bodyLarge,
                            decoration: InputDecoration(
                              hintText: 'your@email.com',
                              hintStyle: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5)),
                            ),
                            validator: (v) => (v?.trim().isEmpty ?? true) ? 'Enter your email' : null,
                          ),

                          const SizedBox(height: AppTheme.stackMd),

                          // Password
                          _FieldLabel(
                            label: 'PASSWORD',
                            icon: Symbols.lock,
                            focused: _passwordFocus.hasFocus,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordCtrl,
                            focusNode: _passwordFocus,
                            obscureText: _obscurePassword,
                            style: Theme.of(context).textTheme.bodyLarge,
                            decoration: InputDecoration(
                              hintText: '••••••••',
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
                              if (v == null || v.isEmpty) return 'Enter your password';
                              if (v.length < 8) return 'Password must be at least 8 characters';
                              return null;
                            },
                            onFieldSubmitted: (_) => _login(),
                          ),

                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              "I'm a coach",
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            subtitle: Text(
                              'Sign in with your staff email and password',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.onSurfaceVariant,
                                  ),
                            ),
                            value: _isCoachLogin,
                            activeThumbColor: AppTheme.onPrimaryContainer,
                            activeTrackColor: AppTheme.primaryContainer,
                            onChanged: _isLoading
                                ? null
                                : (value) => setState(() => _isCoachLogin = value),
                          ),

                          // Forgot password
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => ForgotPasswordScreen(
                                  gym: widget.gym,
                                  email: _emailCtrl.text.trim(),
                                )),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Text(
                                  'Forgot password?',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(color: AppTheme.primaryContainer),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: AppTheme.stackLg),

                          if (_errorMessage != null) ...[
                            _ErrorBanner(message: _errorMessage!),
                            const SizedBox(height: AppTheme.stackMd),
                          ],

                          PrimaryButton(
                            label: 'Sign In',
                            isLoading: _isLoading,
                            icon: Symbols.login,
                            onPressed: _isLoading ? null : _login,
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
