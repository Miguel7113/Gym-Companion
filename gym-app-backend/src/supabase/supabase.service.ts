import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createClient, SupabaseClient, Session, User } from '@supabase/supabase-js';

@Injectable()
export class SupabaseService {
  private readonly client: SupabaseClient;

  constructor(private config: ConfigService) {
    this.client = createClient(
      this.config.get<string>('SUPABASE_URL')!,
      this.config.get<string>('SUPABASE_SERVICE_ROLE_KEY')!,
      { auth: { autoRefreshToken: false, persistSession: false } },
    );
  }

  async sendEmailOtp(email: string) {
    const { error } = await this.client.auth.signInWithOtp({
      email,
      options: {
        // Redirect back into the app via the registered deep link scheme.
        // Must also be listed in Supabase Dashboard → Auth → URL Configuration
        // → Redirect URLs as: io.supabase.tether://login-callback/
        emailRedirectTo: 'io.supabase.tether://login-callback/',
      },
    });
    if (error) throw error;
  }

  async sendPhoneOtp(phone: string) {
    const { error } = await this.client.auth.signInWithOtp({ phone });
    if (error) throw error;
  }

  async verifyOtp(params: { email?: string; phone?: string; token: string }): Promise<Session> {
    const { email, phone, token } = params;
    const { data, error } = await this.client.auth.verifyOtp(
      email
        ? { email, token, type: 'email' }
        : { phone: phone!, token, type: 'sms' },
    );
    if (error) throw error;
    if (!data.session) {
      throw new Error('No session returned from OTP verification');
    }
    return data.session;
  }

  async signInWithPassword(email: string, password: string): Promise<Session> {
    const { data, error } = await this.client.auth.signInWithPassword({
      email,
      password,
    });
    if (error) throw error;
    if (!data.session) {
      throw new Error('No session returned from sign in');
    }
    return data.session;
  }

  async createStaffUser(email: string, password: string): Promise<User> {
    const { data, error } = await this.client.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
    });
    if (error) throw error;
    if (!data.user) {
      throw new Error('Failed to create staff user');
    }
    return data.user;
  }

  /// Injects custom claims into the JWT via raw_user_meta_data.
  /// These are read by the RLS helper functions (get_my_gym_id etc.)
  async updateUserMetadata(
    authUserId: string,
    metadata: Record<string, unknown>,
  ): Promise<void> {
    const { error } = await this.client.auth.admin.updateUserById(authUserId, {
      user_metadata: metadata,
    });
    if (error) throw error;
  }

  /// Refreshes a session so the new JWT claims from updateUserMetadata
  /// are immediately live without requiring the user to log in again.
  async refreshSession(refreshToken: string): Promise<Session> {
    const { data, error } = await this.client.auth.refreshSession({
      refresh_token: refreshToken,
    });
    if (error) throw error;
    if (!data.session) {
      throw new Error('Failed to refresh session');
    }
    return data.session;
  }

  /// Verifies an access token and returns the Supabase auth User.
  /// Used by /auth/claim-session to confirm the magic link session is valid
  /// before injecting gym claims.
  async getUser(accessToken: string): Promise<User> {
    const { data, error } = await this.client.auth.getUser(accessToken);
    if (error) throw error;
    if (!data.user) throw new Error('No user found for token');
    return data.user;
  }

  /// Fetches a Supabase auth user by their UUID using the admin API.
  /// Used to read user_metadata (e.g. password_set flag).
  async getUserById(authUserId: string): Promise<User | null> {
    const { data, error } = await this.client.auth.admin.getUserById(authUserId);
    if (error) return null;
    return data.user ?? null;
  }

  /// Sets a password on an existing Supabase auth user.
  /// Called once after first OTP/magic link verification — converts the
  /// magic-link-only account into a normal email+password account.
  async setUserPassword(authUserId: string, password: string): Promise<void> {
    const { error } = await this.client.auth.admin.updateUserById(authUserId, {
      password,
    });
    if (error) throw error;
  }

  /// Sends a Supabase password reset email.
  /// The reset link redirects to the app's deep link scheme so the
  /// SetPassword screen can handle it.
  async sendPasswordReset(email: string): Promise<void> {
    const { error } = await this.client.auth.resetPasswordForEmail(email, {
      redirectTo: 'io.supabase.tether://login-callback/',
    });
    if (error) throw error;
  }

  async createPostImageSignedUrl(
    path: string,
    expiresInSeconds = 3600,
  ): Promise<string | null> {
    const { data, error } = await this.client.storage
      .from('post-images')
      .createSignedUrl(path, expiresInSeconds);
    if (error) {
      console.error('[Supabase] failed to sign post image URL', error.message);
      return null;
    }
    return data.signedUrl;
  }

  /// Signs many post image paths in parallel for feed responses.
  async createPostImageSignedUrls(
    paths: string[],
    expiresInSeconds = 3600,
  ): Promise<Map<string, string | null>> {
    const unique = [...new Set(paths.filter(Boolean))];
    if (unique.length === 0) return new Map();

    const entries = await Promise.all(
      unique.map(async (path) => {
        const signedUrl = await this.createPostImageSignedUrl(
          path,
          expiresInSeconds,
        );
        return [path, signedUrl] as const;
      }),
    );
    return new Map(entries);
  }
}
