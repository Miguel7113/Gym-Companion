import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/config/supabase_config.dart';
import 'core/navigation/main_navigation.dart';
import 'core/providers/api_provider.dart';
import 'core/sync/sync_service.dart';
import 'features/auth/screens/gym_selection_screen.dart';
import 'features/auth/screens/set_password_screen.dart';
import 'features/auth/providers/auth_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SKIP_LOGIN_FOR_TESTING
// Set to true only for UI testing without a backend connection.
// Must be false for any real auth / backend API calls to work.
// ─────────────────────────────────────────────────────────────────────────────
const bool SKIP_LOGIN_FOR_TESTING = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.implicit,
    ),
  );

  runApp(const ProviderScope(child: MyApp()));
}

// Convenience getter used throughout the app
// e.g.: supabase.from('gyms').select()
SupabaseClient get supabase => Supabase.instance.client;

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Tether',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: SKIP_LOGIN_FOR_TESTING
          ? const MainNavigation()
          : const _AuthGate(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AuthGate
//
// Watches the Supabase auth state stream. When the session changes the widget
// automatically rebuilds and routes to the correct screen.
//
// Magic link flow:
//   1. User taps link in email → app opens with Supabase session
//   2. _AuthGate detects session but JWT may lack gym_id/member_id claims
//   3. _ClaimHandler calls NestJS /auth/claim-session to:
//      - create users row if first login
//      - inject gym_id/member_id/role into JWT
//      - refresh session with updated claims
//   4. authStateStreamProvider emits refreshed session → MainNavigation
// ─────────────────────────────────────────────────────────────────────────────
class _AuthGate extends ConsumerStatefulWidget {
  const _AuthGate();

  @override
  ConsumerState<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<_AuthGate> {
  bool _isClaiming = false;
  String? _claimError; // shown if claim-session fails

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authStateStreamProvider);

    return authAsync.when(
      data: (authState) {
        if (authState.session != null) {
          final session = authState.session!;
          final meta = session.user.userMetadata ?? {};
          final hasGymClaims = (meta['gym_id'] as String?)?.isNotEmpty == true;
          final hasPassword = meta['password_set'] == true;

          // Sync token to API client for NestJS calls
          ref.read(apiClientProvider).setAccessToken(session.accessToken);

          // Session exists but no gym claims yet — magic link first-signup path
          if (!hasGymClaims && !_isClaiming) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _completeClaim(session);
            });
            // Show error if a previous claim attempt failed
            if (_claimError != null) {
              return _ClaimErrorScreen(
                message: _claimError!,
                onRetry: () {
                  setState(() { _claimError = null; });
                  _completeClaim(session);
                },
                onSignOut: () async {
                  setState(() => _claimError = null);
                  await Supabase.instance.client.auth.signOut();
                },
              );
            }
            return const _SplashScreen();
          }

          // Session has gym claims but password not yet set — first signup
          if (hasGymClaims && !hasPassword) {
            return const SetPasswordScreen();
          }

          // Fully authenticated with password set — show the app
          // Trigger exercise cache seed in background (no-op if already fresh)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(syncServiceProvider).seedIfNeeded();
          });
          return const MainNavigation();
        }
        return const GymSelectionScreen();
      },
      loading: () => const _SplashScreen(),
      error: (_, __) => const GymSelectionScreen(),
    );
  }

  Future<void> _completeClaim(Session session) async {
    if (_isClaiming) return;
    setState(() { _isClaiming = true; _claimError = null; });

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.setAccessToken(session.accessToken);

      final response = await apiClient.post('/auth/claim-session', data: {
        'email': session.user.email,
        'phone': session.user.phone,
        'refreshToken': session.refreshToken,
      });

      final data = response.data as Map<String, dynamic>;
      final refreshToken = data['refreshToken'] as String?;
      final accessToken = data['accessToken'] as String?;

      if (refreshToken != null && accessToken != null) {
        await Supabase.instance.client.auth.setSession(refreshToken);
        await apiClient.setAccessToken(accessToken);
      }
    } catch (e) {
      debugPrint('[AuthGate] _completeClaim failed: $e');
      final msg = e.toString().toLowerCase();

      if (msg.contains('not found') ||
          msg.contains('no gym membership') ||
          msg.contains('401') ||
          msg.contains('403')) {
        // Genuinely not authorised — sign out cleanly
        await Supabase.instance.client.auth.signOut();
      } else {
        // Network error or backend down — show retry screen, keep session
        if (mounted) {
          setState(() => _claimError =
            'Could not connect to the server. Check your connection and try again.\n\n'
            'Error: ${e.toString().replaceAll('Exception: ', '')}');
        }
      }
    } finally {
      if (mounted) setState(() => _isClaiming = false);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SplashScreen — shown for ~100ms while Supabase restores the session
// ─────────────────────────────────────────────────────────────────────────────
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'TETHER',
              style: TextStyle(
                color: AppTheme.primaryContainer,
                fontSize: 40,
                fontWeight: FontWeight.w900,
                letterSpacing: 6,
                shadows: [
                  Shadow(
                    color: AppTheme.primaryContainer.withOpacity(0.4),
                    blurRadius: 20,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryContainer.withOpacity(0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ClaimErrorScreen — shown when claim-session fails with a network/server error
// Lets the user retry or sign out cleanly instead of silently looping
// ─────────────────────────────────────────────────────────────────────────────
class _ClaimErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onSignOut;

  const _ClaimErrorScreen({
    required this.message,
    required this.onRetry,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 56,
                color: AppTheme.onSurfaceVariant.withOpacity(0.5),
              ),
              const SizedBox(height: 24),
              Text(
                'CONNECTION ERROR',
                style: TextStyle(
                  color: AppTheme.primaryContainer,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryContainer,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Text('RETRY',
                  style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1)),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onSignOut,
                child: Text('Sign out',
                  style: TextStyle(color: AppTheme.onSurfaceVariant)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
