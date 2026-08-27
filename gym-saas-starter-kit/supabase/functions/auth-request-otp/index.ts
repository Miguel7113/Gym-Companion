import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  // CORS headers
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Content-Type': 'application/json',
  }

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers })
  }

  try {
    const { email, phone, gym_id } = await req.json()

    if (!gym_id || (!email && !phone)) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: gym_id and (email or phone)' }),
        { status: 400, headers }
      )
    }

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    // 1. Verify gym exists and subscription is active
    const { data: gym, error: gymError } = await supabaseAdmin
      .from('gyms')
      .select('id, name, subscription_status, max_members')
      .eq('id', gym_id)
      .single()

    if (gymError || !gym) {
      return new Response(
        JSON.stringify({ error: 'Gym not found' }),
        { status: 404, headers }
      )
    }

    if (!['active', 'trialing'].includes(gym.subscription_status)) {
      return new Response(
        JSON.stringify({ error: 'Gym subscription is inactive. Contact your gym administrator.' }),
        { status: 403, headers }
      )
    }

    // 2. Check if member is pre-registered and active
    let query = supabaseAdmin
      .from('gym_members')
      .select('id, email, phone, is_active, auth_user_id, full_name')
      .eq('gym_id', gym_id)
      .eq('is_active', true)

    if (email) {
      query = query.eq('email', email.toLowerCase().trim())
    }
    if (phone) {
      query = query.eq('phone', phone.trim())
    }

    const { data: member, error: memberError } = await query.single()

    if (!member) {
      return new Response(
        JSON.stringify({ error: 'Not registered with this gym. Contact your gym admin.' }),
        { status: 403, headers }
      )
    }

    // 3. Rate limiting: max 3 OTP requests per 10 minutes per contact
    const contact = email || phone
    const tenMinutesAgo = new Date(Date.now() - 10 * 60 * 1000).toISOString()

    const { count: recentRequests, error: countError } = await supabaseAdmin
      .from('otp_logs')
      .select('*', { count: 'exact', head: true })
      .eq('contact', contact)
      .gt('created_at', tenMinutesAgo)

    if (recentRequests && recentRequests >= 3) {
      return new Response(
        JSON.stringify({ error: 'Too many requests. Try again in 10 minutes.' }),
        { status: 429, headers }
      )
    }

    // 4. Log the attempt
    await supabaseAdmin.from('otp_logs').insert({
      contact,
      gym_id,
      member_id: member.id,
    })

    // 5. Trigger Supabase OTP
    const otpPayload: any = {
      options: {
        data: {
          gym_id,
          member_id: member.id,
          gym_name: gym.name,
        },
      },
    }

    if (email) otpPayload.email = email
    if (phone) otpPayload.phone = phone

    const { error: otpError } = await supabaseAdmin.auth.signInWithOtp(otpPayload)

    if (otpError) {
      console.error('OTP Error:', otpError)
      return new Response(
        JSON.stringify({ error: 'Failed to send OTP. Please try again.' }),
        { status: 500, headers }
      )
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: 'OTP sent successfully',
        member_name: member.full_name,
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
