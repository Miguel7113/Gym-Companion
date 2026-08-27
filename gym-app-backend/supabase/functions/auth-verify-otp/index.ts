// auth-verify-otp
//
// Verifies the OTP, links the Supabase auth user to the gym_roster entry
// on first login ("claim"), and injects gym_id/member_id/role into the JWT.
//
// What it does:
//   1. Verifies the OTP via Supabase Auth
//   2. Finds the gym_roster entry for this contact + gym
//   3. If first claim: links auth_user_id to gym_roster and creates/links users row
//   4. If returning: validates the auth_user_id matches (anti-takeover)
//   5. Injects gym_id, member_id, role into auth.users.raw_user_meta_data
//   6. Refreshes session so the JWT has the new claims
//   7. Returns the full session to Flutter, which calls supabase.auth.setSession()
//
// Auth: verify_jwt = false (called before user has a valid session)

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Content-Type': 'application/json',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS })

  try {
    const { email, phone, token, gym_id, display_name } = await req.json()

    if (!token || !gym_id || (!email && !phone)) {
      return json({ error: 'token, gym_id and email or phone are required' }, 400)
    }

    const admin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    // ── 1. Verify the OTP ─────────────────────────────────────────────────────
    const otpType = email ? 'email' : 'sms'
    const { data: authData, error: authErr } = await admin.auth.verifyOtp({
      email: email ?? undefined,
      phone: phone ?? undefined,
      token,
      type: otpType,
    } as any)

    if (authErr || !authData?.user) {
      console.error('OTP verify error:', authErr)
      return json({ error: 'Invalid or expired verification code' }, 401)
    }

    const authUserId = authData.user.id

    // ── 2. Find roster entry ──────────────────────────────────────────────────
    let rosterQuery = admin
      .from('gym_roster')
      .select('id, email, phone, status, matched_user_id, member_name')
      .eq('gym_id', gym_id)

    if (email) rosterQuery = rosterQuery.eq('email', email.toLowerCase().trim())
    else rosterQuery = rosterQuery.eq('phone', phone.trim())

    const { data: roster, error: rosterErr } = await rosterQuery.maybeSingle()

    if (rosterErr || !roster) {
      return json({ error: 'Member not found in this gym. Contact your administrator.' }, 404)
    }

    // ── 3. Anti-takeover check ────────────────────────────────────────────────
    if (roster.matched_user_id && roster.matched_user_id !== authUserId) {
      return json({ error: 'Account mismatch. Contact support.' }, 403)
    }

    // ── 4. Find or create the users row ──────────────────────────────────────
    // Our schema: users table has auth_provider_id (= Supabase auth user ID)
    let { data: user } = await admin
      .from('users')
      .select('id, gym_id, display_name')
      .eq('auth_provider_id', authUserId)
      .maybeSingle()

    const isFirstClaim = !roster.matched_user_id

    if (!user) {
      // First ever login — create the users row
      const { data: newUser, error: createErr } = await admin
        .from('users')
        .insert({
          gym_id,
          roster_id: roster.id,
          email: email?.toLowerCase().trim() ?? null,
          phone: phone?.trim() ?? null,
          display_name: display_name ?? roster.member_name ?? null,
          auth_provider_id: authUserId,
        })
        .select('id, gym_id, display_name')
        .single()

      if (createErr) {
        console.error('Failed to create user:', createErr)
        return json({ error: 'Failed to activate account' }, 500)
      }
      user = newUser
    }

    // ── 5. Link roster entry to auth user (first claim) ───────────────────────
    if (isFirstClaim) {
      await admin
        .from('gym_roster')
        .update({ matched_user_id: user.id, status: 'matched' })
        .eq('id', roster.id)
    }

    // ── 6. Inject gym context into JWT via user metadata ──────────────────────
    // This is what makes RLS work — the JWT will contain gym_id, member_id, role.
    // We derive the role from gym_staff table: if the user is staff, use that role,
    // otherwise default to 'member'.
    const { data: staffRow } = await admin
      .from('gym_staff')
      .select('role')
      .eq('gym_id', gym_id)
      .eq('auth_provider_id', authUserId)
      .maybeSingle()

    const role = staffRow?.role ?? 'member'

    await admin.auth.admin.updateUserById(authUserId, {
      user_metadata: {
        gym_id,
        member_id: user.id,
        role,
        display_name: user.display_name ?? display_name ?? null,
      },
    })

    // ── 7. Refresh session to get updated JWT claims ───────────────────────────
    const refreshToken = authData.session?.refresh_token
    if (!refreshToken) {
      return json({ error: 'No refresh token available' }, 500)
    }

    const { data: refreshed, error: refreshErr } = await admin.auth.refreshSession({
      refresh_token: refreshToken,
    })

    if (refreshErr || !refreshed?.session) {
      console.error('Session refresh error:', refreshErr)
      return json({ error: 'Session refresh failed' }, 500)
    }

    return json({
      success: true,
      // These map directly to Flutter AuthResponse fields
      accessToken: refreshed.session.access_token,
      refreshToken: refreshed.session.refresh_token,
      user: {
        id: user.id,
        gymId: gym_id,
        email: email ?? null,
        phone: phone ?? null,
        displayName: user.display_name ?? display_name ?? null,
        subscriptionTier: 'free',
      },
      isFirstClaim,
    }, 200)

  } catch (err) {
    console.error('auth-verify-otp unexpected error:', err)
    return json({ error: 'Internal server error' }, 500)
  }
})

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: CORS })
}
