import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/auth_models.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  final SupabaseClient _client;

  AuthService(this._client);

  /// Fetch all active gyms for the selection screen
  Future<List<Gym>> fetchActiveGyms() async {
    final response = await _client
        .from('gyms')
        .select('id, name, slug, code, logo_url, primary_color, plan_tier, created_at')
        .eq('subscription_status', 'active')
        .order('name');

    return (response as List)
        .map((json) => Gym.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Search gym by code (exact match) or name (partial match)
  Future<List<Gym>> searchGyms({String? code, String? name}) async {
    var query = _client
        .from('gyms')
        .select('id, name, slug, code, logo_url, primary_color, plan_tier, created_at')
        .eq('subscription_status', 'active');

    if (code != null && code.isNotEmpty) {
      query = query.eq('code', code.trim().toUpperCase());
    } else if (name != null && name.isNotEmpty) {
      query = query.ilike('name', '%\${name.trim()}%');
    }

    final response = await query.order('name');
    return (response as List)
        .map((json) => Gym.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Request OTP via Edge Function (checks if member is pre-registered)
  Future<void> requestOtp({
    String? email,
    String? phone,
    required String gymId,
  }) async {
    final response = await _client.functions.invoke(
      'auth-request-otp',
      body: {
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        'gym_id': gymId,
      },
    );

    if (response.status != 200) {
      final error = response.data['error'] ?? 'Failed to send OTP';
      throw AuthException(error);
    }
  }

  /// Verify OTP via Edge Function (links auth user to gym_member on first claim)
  Future<Session> verifyOtp({
    String? email,
    String? phone,
    required String token,
    required String gymId,
  }) async {
    final response = await _client.functions.invoke(
      'auth-verify-otp',
      body: {
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        'token': token,
        'gym_id': gymId,
      },
    );

    if (response.status != 200) {
      final error = response.data['error'] ?? 'Invalid OTP';
      throw AuthException(error);
    }

    // The edge function returns a refreshed session with gym claims
    final sessionData = response.data['session'] as Map<String, dynamic>;
    final session = Session.fromJson(sessionData);

    // Persist session locally
    await _client.auth.setSession(session.refreshToken!);

    return session;
  }

  /// Get current member profile from JWT claims
  Future<GymMember?> getCurrentMember() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final memberId = user.userMetadata?['member_id'] as String?;
    if (memberId == null) return null;

    final response = await _client
        .from('gym_members')
        .select()
        .eq('id', memberId)
        .single();

    return GymMember.fromJson(response);
  }

  /// Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange.map((event) {
        final session = event.session;
        if (session == null) {
          return const AuthState();
        }
        // Member and gym will be loaded by the provider
        return const AuthState();
      });
}
