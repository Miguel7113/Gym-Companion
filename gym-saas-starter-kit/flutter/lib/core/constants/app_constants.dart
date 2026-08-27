class AppConstants {
  AppConstants._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static const int otpLength = 6;
  static const int otpResendSeconds = 60;
  static const int maxOtpAttempts = 3;
}
