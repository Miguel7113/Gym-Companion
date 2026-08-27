import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Content-Type': 'application/json',
  }

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers })
  }

  try {
    const { email, phone, token, gym_id } = await req.json()

    if (!token || (!email && !phone) || !gym_id) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields' }),
        { status: 400, headers }
      )
    }

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    // 1. Verify OTP via Supabase Auth
    const { data: authData, error: authError } = await supabaseAdmin.auth.verifyOtp({
      email,
      phone,
      token,
      type: email ? 'email' : 'sms',
    })

    if (authError || !authData.user) {
      return new Response(
        JSON.stringify({ error: 'Invalid or expired OTP' }),
        { status: 401, headers }
      )
    }

    // 2. Find the pre-registered member
    const { data: member, error: memberError } = await supabaseAdmin
      .from('gym_members')
      .select('id, auth_user_id, gym_id, role')
      .eq('gym_id', gym_id)
      .or(`email.eq.${email},phone.eq.${phone}`)
      .single()

    if (!member) {
      return new Response(
        JSON.stringify({ error: 'Member not found in this gym' }),
        { status: 404, headers }
      )
    }

    // 3. If first time claim, link auth user to gym_member
    if (!member.auth_user_id) {
      const { error: updateError } = await supabaseAdmin
        .from('gym_members')
        .update({
          auth_user_id: authData.user.id,
          claimed_at: new Date().toISOString(),
        })
        .eq('id', member.id)

      if (updateError) {
        console.error('Failed to link member:', updateError)
        return new Response(
          JSON.stringify({ error: 'Failed to activate account' }),
          { status: 500, headers }
        )
      }
    } else if (member.auth_user_id !== authData.user.id) {
      // Security: prevent account takeover
      return new Response(
        JSON.stringify({ error: 'Account mismatch. Contact support.' }),
        { status: 403, headers }
      )
    }

    // 4. Update auth user metadata (ensures JWT has gym context)
    await supabaseAdmin.auth.admin.updateUserById(authData.user.id, {
      user_metadata: {
        gym_id: member.gym_id,
        member_id: member.id,
        role: member.role,
      },
    })

    // 5. Refresh session to get updated JWT claims
    const { data: refreshData, error: refreshError } = await supabaseAdmin.auth.refreshSession({
      refresh_token: authData.session!.refresh_token,
    })

    if (refreshError) {
      console.error('Refresh error:', refreshError)
      return new Response(
        JSON.stringify({ error: 'Session refresh failed' }),
        { status: 500, headers }
      )
    }

    return new Response(
      JSON.stringify({
        success: true,
        session: refreshData.session,
        user: refreshData.user,
        is_first_claim: !member.auth_user_id,
      }),
      { status: 200, headers }
    )

  } catch (err) {
    console.error('Unexpected error:', err)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers }
    )
  }
})
