// ─────────────────────────────────────────────────────────────────────────────
// SupabaseConfig
//
// The publishable key (formerly called "anon key") is safe to embed in
// client code — it is NOT the service role key.
// The service role key lives only in the backend .env and never ships to users.
//
// The defaultValue is used for local development so you don't need
// --dart-define flags during testing. For production builds, inject via:
//   flutter build appbundle \
//     --dart-define=SUPABASE_URL=https://... \
//     --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
// ─────────────────────────────────────────────────────────────────────────────
abstract final class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://uqswohwqdcjlncdudhap.supabase.co',
  );

  // Supabase publishable key (previously "anon key") — safe to ship to clients
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_9TD5SfAXxIPWoPdirHbhYg_DBnPjBou',
  );

  // Convenience alias matching the new Supabase naming
  static const String publishableKey = anonKey;

  // Edge function base URL — same project as the Supabase URL
  static String get edgeFunctionUrl => '$url/functions/v1';

  // Deep link scheme registered in platform manifests
  // Must match the redirect URL in Supabase Dashboard → Auth → URL Configuration
  static const String deepLinkScheme = 'io.supabase.tether';
  static const String deepLinkHost = 'login-callback';
  static const String deepLinkRedirect = '$deepLinkScheme://$deepLinkHost/';
}
