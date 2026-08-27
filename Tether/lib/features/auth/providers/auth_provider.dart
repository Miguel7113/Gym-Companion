import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../models/auth_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// authStateStreamProvider
//
// Reactively streams Supabase auth state changes.
// The _AuthGate in main.dart watches this to route between
// GymSelectionScreen and MainNavigation automatically.
//
// Supabase persists sessions to secure storage and restores them on cold
// start — so a valid session from a previous launch will be emitted here
// before the user sees any UI.
// ─────────────────────────────────────────────────────────────────────────────
final authStateStreamProvider = StreamProvider<sb.AuthState>((ref) {
  return sb.Supabase.instance.client.auth.onAuthStateChange;
});

// ─────────────────────────────────────────────────────────────────────────────
// currentSessionProvider — exposes the current Session? synchronously
// ─────────────────────────────────────────────────────────────────────────────
final currentSessionProvider = Provider<sb.Session?>((ref) {
  return sb.Supabase.instance.client.auth.currentSession;
});

// ─────────────────────────────────────────────────────────────────────────────
// currentUserProvider
//
// Exposes the parsed User model built from the JWT claims embedded in the
// Supabase session. Returns null when not authenticated.
//
// The JWT contains gym_id, member_id, role injected by the auth-verify-otp
// Edge Function — so we never need a separate /users/me API call.
// ─────────────────────────────────────────────────────────────────────────────
final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authStateStreamProvider);
  final session = sb.Supabase.instance.client.auth.currentSession;
  if (session == null) return null;
  return User.fromSupabaseSession(session);
});

// ─────────────────────────────────────────────────────────────────────────────
// selectedGymProvider — holds the gym the user tapped before OTP flow
// ─────────────────────────────────────────────────────────────────────────────
final selectedGymProvider = StateProvider<Gym?>((ref) => null);
