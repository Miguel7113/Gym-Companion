import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../core/api_client.dart';
import '../../../core/providers/api_provider.dart';
import '../models/auth_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AuthService
// ─────────────────────────────────────────────────────────────────────────────
class AuthService {
  final ApiClient _apiClient;

  AuthService(this._apiClient);

  // ── Gyms ──────────────────────────────────────────────────────────────────

  Future<List<Gym>> getGyms() async {
    final response = await sb.Supabase.instance.client
        .from('gyms')
        .select('id, name, logo_url, primary_color, contact_email, subscription_tier, is_active')
        .eq('is_active', true)
        .order('name');

    return (response as List)
        .map((json) => Gym.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ── Pre-check ─────────────────────────────────────────────────────────────
  // Called before showing any auth form. Returns CheckMemberResult so the
  // caller can decide which screen to show next without sending an OTP.
  Future<CheckMemberResult> checkMember({
    required String gymId,
    String? email,
    String? phone,
  }) async {
    final response = await _apiClient.post('/auth/check-member', data: {
      'gymId': gymId,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
    });
    final data = response.data as Map<String, dynamic>;
    return CheckMemberResult(
      exists: data['exists'] as bool,
      hasPassword: data['hasPassword'] as bool,
    );
  }

  // ── OTP flow (first-time signup only) ─────────────────────────────────────

  Future<OtpResponse> requestOtp(RequestOtpDto dto) async {
    final response =
        await _apiClient.post('/auth/request-otp', data: dto.toJson());
    return OtpResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// Returns whether this was a first-time signup (returning: false).
  /// Caller uses this to decide whether to show SetPasswordScreen.
  Future<bool> verifyOtp(VerifyOtpDto dto) async {
    final response =
        await _apiClient.post('/auth/verify-otp', data: dto.toJson());

    final data = response.data as Map<String, dynamic>;
    final accessToken = data['accessToken'] as String;
    final refreshToken = data['refreshToken'] as String;
    final isReturning = data['returning'] as bool? ?? false;

    await sb.Supabase.instance.client.auth.setSession(refreshToken);
    await _apiClient.setAccessToken(accessToken);

    // returning: true = already had an account → password already set
    // returning: false = brand new account → needs SetPasswordScreen
    return !isReturning; // true = "needs password setup"
  }

  // ── Password login (returning members) ────────────────────────────────────

  Future<void> login({
    required String gymId,
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post('/auth/login', data: {
      'gymId': gymId,
      'email': email,
      'password': password,
    });

    final data = response.data as Map<String, dynamic>;
    final accessToken = data['accessToken'] as String;
    final refreshToken = data['refreshToken'] as String;

    // Store session — fires authStateStreamProvider which _AuthGate watches
    await sb.Supabase.instance.client.auth.setSession(refreshToken);
    await _apiClient.setAccessToken(accessToken);
  }

  // ── Set password (once, after first OTP/magic link verification) ──────────

  Future<void> setPassword(String password) async {
    final session = sb.Supabase.instance.client.auth.currentSession;
    if (session == null) throw Exception('No active session');

    // ApiClient interceptor already attaches the Bearer token automatically
    await _apiClient.post('/auth/set-password', data: {'password': password});

    // Refresh the Supabase session so the updated password_set: true metadata
    // is live immediately — without this _AuthGate still sees hasPassword: false
    // and would show SetPasswordScreen again.
    final refreshed = await sb.Supabase.instance.client.auth.refreshSession();
    if (refreshed.session != null) {
      await _apiClient.setAccessToken(refreshed.session!.accessToken);
    }
  }

  // ── Forgot password ───────────────────────────────────────────────────────

  Future<void> forgotPassword({
    required String gymId,
    required String email,
  }) async {
    await _apiClient.post('/auth/forgot-password', data: {
      'gymId': gymId,
      'email': email,
    });
  }

  // ── Sign out ───────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await sb.Supabase.instance.client.auth.signOut();
    await _apiClient.clearAccessToken();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CheckMemberResult — returned by checkMember()
// ─────────────────────────────────────────────────────────────────────────────
class CheckMemberResult {
  final bool exists;
  final bool hasPassword;
  const CheckMemberResult({required this.exists, required this.hasPassword});
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(apiClientProvider));
});
