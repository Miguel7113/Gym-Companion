import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

interface MemberRow {
  email?: string
  phone?: string
  full_name?: string
  role?: 'member' | 'coach' | 'admin'
}

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
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers })
    }

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    // Verify the caller is gym staff
    const jwt = authHeader.replace('Bearer ', '')
    const { data: { user }, error: userError } = await supabaseAdmin.auth.getUser(jwt)

    if (userError || !user) {
      return new Response(JSON.stringify({ error: 'Invalid token' }), { status: 401, headers })
    }

    const { data: staff } = await supabaseAdmin
      .from('gym_staff')
      .select('gym_id, role')
      .eq('auth_user_id', user.id)
      .single()

    if (!staff || !['owner', 'manager'].includes(staff.role)) {
      return new Response(JSON.stringify({ error: 'Forbidden' }), { status: 403, headers })
    }

    const { members }: { members: MemberRow[] } = await req.json()

    if (!Array.isArray(members) || members.length === 0) {
      return new Response(JSON.stringify({ error: 'No members provided' }), { status: 400, headers })
    }

    // Check gym member limit
    const { data: gym } = await supabaseAdmin
      .from('gyms')
      .select('max_members')
      .eq('id', staff.gym_id)
      .single()

    const { count: currentCount } = await supabaseAdmin
      .from('gym_members')
      .select('*', { count: 'exact', head: true })
      .eq('gym_id', staff.gym_id)

    if (currentCount && currentCount + members.length > (gym?.max_members || 200)) {
      return new Response(
        JSON.stringify({ error: 'Member limit exceeded. Upgrade your plan.' }),
        { status: 400, headers }
      )
    }

    // Prepare rows
    const rows = members.map((m) => ({
      gym_id: staff.gym_id,
      email: m.email?.toLowerCase().trim() || null,
      phone: m.phone?.trim() || null,
      full_name: m.full_name?.trim() || null,
      role: m.role || 'member',
    }))

    // Insert with upsert on conflict (email/phone per gym)
    const { data: inserted, error: insertError } = await supabaseAdmin
      .from('gym_members')
      .upsert(rows, {
        onConflict: 'gym_id,email',
        ignoreDuplicates: true,
      })
      .select('id, email, phone, full_name')

    if (insertError) {
      console.error('Insert error:', insertError)
      return new Response(
        JSON.stringify({ error: 'Failed to import members', details: insertError.message }),
        { status: 500, headers }
      )
    }

    return new Response(
      JSON.stringify({
        success: true,
        imported: inserted?.length || 0,
        members: inserted,
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
