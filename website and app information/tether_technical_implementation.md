# TETHER — Complete Technical Implementation Guide
## Version 1.0 | Flutter + Supabase + Next.js

---

# PART A: DATABASE SCHEMA & SQL

## A.1 Core Schema Additions & Fixes

Run these in Supabase SQL Editor in order:

```sql
-- ============================================================
-- 1. MULTI-GYM SUPPORT: Junction Table
-- ============================================================
CREATE TABLE IF NOT EXISTS public.user_gyms (
  id text NOT NULL DEFAULT gen_random_uuid()::text,
  user_id text NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  gym_id text NOT NULL REFERENCES public.gyms(id) ON DELETE CASCADE,
  role text NOT NULL DEFAULT 'member' CHECK (role IN ('member', 'coach')),
  is_active boolean NOT NULL DEFAULT true,
  joined_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT user_gyms_pkey PRIMARY KEY (id),
  CONSTRAINT user_gyms_unique UNIQUE (user_id, gym_id)
);

-- Migrate existing single-gym users into user_gyms
INSERT INTO public.user_gyms (user_id, gym_id, role)
SELECT id, gym_id, COALESCE(role, 'member') 
FROM public.users 
WHERE gym_id IS NOT NULL
ON CONFLICT (user_id, gym_id) DO NOTHING;

-- ============================================================
-- 2. ENHANCE USERS TABLE
-- ============================================================
ALTER TABLE public.users 
  ADD COLUMN IF NOT EXISTS avatar_url text,
  ADD COLUMN IF NOT EXISTS bio text,
  ADD COLUMN IF NOT EXISTS is_active boolean NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS last_selected_gym_id text REFERENCES public.gyms(id);

-- ============================================================
-- 3. POSTS TABLE ENHANCEMENTS
-- ============================================================
ALTER TABLE public.posts 
  ADD COLUMN IF NOT EXISTS post_type text NOT NULL DEFAULT 'general' 
    CHECK (post_type IN ('general', 'workout_share', 'coach_tip')),
  ADD COLUMN IF NOT EXISTS workout_session_id text 
    REFERENCES public.workout_sessions(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS image_urls jsonb DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS is_pinned boolean NOT NULL DEFAULT false;

-- Migrate existing single image into array
UPDATE public.posts 
SET image_urls = CASE 
  WHEN image_url IS NOT NULL AND image_url != '' 
  THEN jsonb_build_array(image_url) 
  ELSE '[]'::jsonb 
END;

-- ============================================================
-- 4. FOLLOWING SYSTEM
-- ============================================================
CREATE TABLE IF NOT EXISTS public.user_follows (
  id text NOT NULL DEFAULT gen_random_uuid()::text,
  follower_id text NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  following_id text NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  gym_id text NOT NULL REFERENCES public.gyms(id) ON DELETE CASCADE,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT user_follows_pkey PRIMARY KEY (id),
  CONSTRAINT user_follows_unique UNIQUE (follower_id, following_id)
);

-- ============================================================
-- 5. GYM NOTICES
-- ============================================================
CREATE TABLE IF NOT EXISTS public.gym_notices (
  id text NOT NULL DEFAULT gen_random_uuid()::text,
  gym_id text NOT NULL REFERENCES public.gyms(id) ON DELETE CASCADE,
  staff_id text NOT NULL REFERENCES public.gym_staff(id) ON DELETE CASCADE,
  title text NOT NULL,
  content text,
  image_url text,
  notice_type text NOT NULL DEFAULT 'announcement' 
    CHECK (notice_type IN ('announcement', 'class_update', 'reminder')),
  is_pinned boolean NOT NULL DEFAULT false,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT gym_notices_pkey PRIMARY KEY (id)
);

-- ============================================================
-- 6. ROSTER CONSTRAINTS
-- ============================================================
ALTER TABLE public.gym_roster 
  ADD CONSTRAINT unique_gym_email UNIQUE (gym_id, email),
  ADD CONSTRAINT unique_gym_phone UNIQUE (gym_id, phone);

-- ============================================================
-- 7. INDEXES
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_posts_gym_created ON public.posts(gym_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_posts_type ON public.posts(post_type);
CREATE INDEX IF NOT EXISTS idx_posts_workout_session ON public.posts(workout_session_id);
CREATE INDEX IF NOT EXISTS idx_notices_gym_pinned ON public.gym_notices(gym_id, is_pinned, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_follows_follower ON public.user_follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_user_gyms_user ON public.user_gyms(user_id);
CREATE INDEX IF NOT EXISTS idx_user_gyms_gym ON public.user_gyms(gym_id);

-- ============================================================
-- 8. AUTO-UPDATE TRIGGER
-- ============================================================
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_gyms_updated_at BEFORE UPDATE ON public.gyms
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_posts_updated_at BEFORE UPDATE ON public.posts
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_gym_notices_updated_at BEFORE UPDATE ON public.gym_notices
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
```

---

## A.2 Complete RLS Policies

```sql
-- GYMS
ALTER TABLE public.gyms ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their gyms" ON public.gyms FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM public.user_gyms 
      WHERE user_gyms.gym_id = gyms.id 
      AND user_gyms.user_id = (SELECT id FROM public.users WHERE auth_provider_id = auth.uid())
      AND user_gyms.is_active = true)
    OR EXISTS (SELECT 1 FROM public.gym_staff 
      WHERE gym_staff.gym_id = gyms.id 
      AND gym_staff.auth_provider_id = auth.uid())
  );

-- USERS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view profiles in shared gyms" ON public.users FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM public.user_gyms ug1
      JOIN public.user_gyms ug2 ON ug1.gym_id = ug2.gym_id
      WHERE ug1.user_id = (SELECT id FROM public.users WHERE auth_provider_id = auth.uid())
      AND ug2.user_id = users.id AND ug1.is_active = true AND ug2.is_active = true)
    OR auth_provider_id = auth.uid()
  );
CREATE POLICY "Users can update own profile" ON public.users FOR UPDATE
  USING (auth_provider_id = auth.uid());

-- USER_GYMS
ALTER TABLE public.user_gyms ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their memberships" ON public.user_gyms FOR SELECT
  USING (
    user_id = (SELECT id FROM public.users WHERE auth_provider_id = auth.uid())
    OR EXISTS (SELECT 1 FROM public.gym_staff 
      WHERE gym_staff.gym_id = user_gyms.gym_id 
      AND gym_staff.auth_provider_id = auth.uid())
  );

-- GYM_ROSTER
ALTER TABLE public.gym_roster ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Staff can manage roster" ON public.gym_roster FOR ALL
  USING (EXISTS (SELECT 1 FROM public.gym_staff 
    WHERE gym_staff.gym_id = gym_roster.gym_id 
    AND gym_staff.auth_provider_id = auth.uid()));

-- WORKOUT_SESSIONS
ALTER TABLE public.workout_sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view sessions in shared gym" ON public.workout_sessions FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM public.user_gyms ug
      WHERE ug.user_id = workout_sessions.user_id
      AND ug.gym_id = workout_sessions.gym_id AND ug.is_active = true
      AND EXISTS (SELECT 1 FROM public.user_gyms viewer 
        WHERE viewer.user_id = (SELECT id FROM public.users WHERE auth_provider_id = auth.uid())
        AND viewer.gym_id = workout_sessions.gym_id AND viewer.is_active = true))
    OR user_id = (SELECT id FROM public.users WHERE auth_provider_id = auth.uid())
  );
CREATE POLICY "Users can create own sessions" ON public.workout_sessions FOR INSERT
  WITH CHECK (user_id = (SELECT id FROM public.users WHERE auth_provider_id = auth.uid()));
CREATE POLICY "Users can update own sessions" ON public.workout_sessions FOR UPDATE
  USING (user_id = (SELECT id FROM public.users WHERE auth_provider_id = auth.uid()));

-- WORKOUT_SETS
ALTER TABLE public.workout_sets ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view sets for visible sessions" ON public.workout_sets FOR SELECT
  USING (EXISTS (SELECT 1 FROM public.workout_sessions ws
    JOIN public.user_gyms ug ON ws.gym_id = ug.gym_id
    WHERE ws.id = workout_sets.session_id
    AND ug.user_id = (SELECT id FROM public.users WHERE auth_provider_id = auth.uid())
    AND ug.is_active = true));
CREATE POLICY "Users can manage own sets" ON public.workout_sets FOR ALL
  USING (EXISTS (SELECT 1 FROM public.workout_sessions 
    WHERE workout_sessions.id = workout_sets.session_id
    AND workout_sessions.user_id = (SELECT id FROM public.users WHERE auth_provider_id = auth.uid())));

-- POSTS
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view posts in their gym" ON public.posts FOR SELECT
  USING (EXISTS (SELECT 1 FROM public.user_gyms 
    WHERE user_gyms.gym_id = posts.gym_id 
    AND user_gyms.user_id = (SELECT id FROM public.users WHERE auth_provider_id = auth.uid())
    AND user_gyms.is_active = true));
CREATE POLICY "Users can create own posts" ON public.posts FOR INSERT
  WITH CHECK (user_id = (SELECT id FROM public.users WHERE auth_provider_id = auth.uid()));
CREATE POLICY "Users can update own posts" ON public.posts FOR UPDATE
  USING (user_id = (SELECT id FROM public.users WHERE auth_provider_id = auth.uid()));

-- POST_LIKES
ALTER TABLE public.post_likes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view likes" ON public.post_likes FOR SELECT
  USING (EXISTS (SELECT 1 FROM public.posts 
    WHERE posts.id = post_likes.post_id
    AND EXISTS (SELECT 1 FROM public.user_gyms 
      WHERE user_gyms.gym_id = posts.gym_id 
      AND user_gyms.user_id = (SELECT id FROM public.users WHERE auth_provider_id = auth.uid())
      AND user_gyms.is_active = true)));
CREATE POLICY "Users can like/unlike" ON public.post_likes FOR ALL
  USING (user_id = (SELECT id FROM public.users WHERE auth_provider_id = auth.uid()));

-- POST_COMMENTS
ALTER TABLE public.post_comments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view comments" ON public.post_comments FOR SELECT
  USING (EXISTS (SELECT 1 FROM public.posts 
    WHERE posts.id = post_comments.post_id
    AND EXISTS (SELECT 1 FROM public.user_gyms 
      WHERE user_gyms.gym_id = posts.gym_id 
      AND user_gyms.user_id = (SELECT id FROM public.users WHERE auth_provider_id = auth.uid())
      AND user_gyms.is_active = true)));
CREATE POLICY "Users can comment" ON public.post_comments FOR INSERT
  WITH CHECK (user_id = (SELECT id FROM public.users WHERE auth_provider_id = auth.uid()));
CREATE POLICY "Users can delete own comments" ON public.post_comments FOR DELETE
  USING (user_id = (SELECT id FROM public.users WHERE auth_provider_id = auth.uid()));

-- USER_FOLLOWS
ALTER TABLE public.user_follows ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view follows in gym" ON public.user_follows FOR SELECT
  USING (EXISTS (SELECT 1 FROM public.user_gyms 
    WHERE user_gyms.gym_id = user_follows.gym_id 
    AND user_gyms.user_id = (SELECT id FROM public.users WHERE auth_provider_id = auth.uid())
    AND user_gyms.is_active = true));
CREATE POLICY "Users can follow/unfollow" ON public.user_follows FOR ALL
  USING (follower_id = (SELECT id FROM public.users WHERE auth_provider_id = auth.uid()));

-- GYM_NOTICES
ALTER TABLE public.gym_notices ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view notices" ON public.gym_notices FOR SELECT
  USING (EXISTS (SELECT 1 FROM public.user_gyms 
    WHERE user_gyms.gym_id = gym_notices.gym_id 
    AND user_gyms.user_id = (SELECT id FROM public.users WHERE auth_provider_id = auth.uid())
    AND user_gyms.is_active = true));
CREATE POLICY "Staff can manage notices" ON public.gym_notices FOR ALL
  USING (EXISTS (SELECT 1 FROM public.gym_staff 
    WHERE gym_staff.gym_id = gym_notices.gym_id 
    AND gym_staff.auth_provider_id = auth.uid()));

-- GYM_STAFF
ALTER TABLE public.gym_staff ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Staff can view own record" ON public.gym_staff FOR SELECT
  USING (auth_provider_id = auth.uid());

-- EXERCISES
ALTER TABLE public.exercises ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Everyone can view exercises" ON public.exercises FOR SELECT USING (true);
CREATE POLICY "Users can create custom exercises" ON public.exercises FOR INSERT
  WITH CHECK (created_by_user_id = (SELECT id FROM public.users WHERE auth_provider_id = auth.uid()));

-- POST_FLAGS
ALTER TABLE public.post_flags ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can flag posts" ON public.post_flags FOR INSERT
  WITH CHECK (user_id = (SELECT id FROM public.users WHERE auth_provider_id = auth.uid()));
```


---

# PART B: SUPABASE EDGE FUNCTIONS

## B.1 CSV Roster Upload Processor

`supabase/functions/process-csv-roster/index.ts`:

```typescript
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { parse } from 'https://deno.land/std@0.168.0/csv/mod.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { auth: { persistSession: false } }
    )

    const authHeader = req.headers.get('authorization')
    if (!authHeader) throw new Error('Missing auth header')

    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await supabaseClient.auth.getUser(token)
    if (authError || !user) throw new Error('Unauthorized')

    const { gymId, csvContent, defaultRole = 'member' } = await req.json()
    if (!gymId || !csvContent) throw new Error('Missing gymId or csvContent')

    const { data: staff } = await supabaseClient
      .from('gym_staff')
      .select('id, gym_id')
      .eq('auth_provider_id', user.id)
      .eq('gym_id', gymId)
      .single()

    if (!staff) throw new Error('Not authorized for this gym')

    const records = parse(csvContent, {
      skipFirstRow: true,
      columns: ['member_name', 'email', 'phone', 'external_member_id', 'role'],
    })

    const results = { success: 0, failed: 0, errors: [] as string[] }

    for (const record of records) {
      try {
        const role = record.role || defaultRole
        if (!['member', 'coach'].includes(role)) {
          throw new Error(`Invalid role: ${role}`)
        }

        const { error } = await supabaseClient
          .from('gym_roster')
          .upsert({
            gym_id: gymId,
            member_name: record.member_name?.trim(),
            email: record.email?.trim() || null,
            phone: record.phone?.trim() || null,
            external_member_id: record.external_member_id?.trim() || null,
            status: 'unmatched',
          }, {
            onConflict: 'gym_id,email',
            ignoreDuplicates: false,
          })

        if (error) throw error
        results.success++
      } catch (err: any) {
        results.failed++
        results.errors.push(`Row ${results.success + results.failed}: ${err.message}`)
      }
    }

    return new Response(
      JSON.stringify(results),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
```

Deploy: `supabase functions deploy process-csv-roster`

## B.2 Auto-Flag Moderation

`supabase/functions/moderation-check/index.ts`:

```typescript
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    { auth: { persistSession: false } }
  )

  const { post_id } = await req.json()

  const { count } = await supabase
    .from('post_flags')
    .select('*', { count: 'exact', head: true })
    .eq('post_id', post_id)

  if (count && count >= 3) {
    await supabase
      .from('posts')
      .update({ is_flagged: true })
      .eq('id', post_id)
  }

  return new Response(JSON.stringify({ flagged: count && count >= 3 }))
})
```

## B.3 Database Trigger for Auto-Flag

```sql
CREATE OR REPLACE FUNCTION public.check_post_flags()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM net.http_post(
    url := 'https://YOUR_PROJECT.supabase.co/functions/v1/moderation-check',
    headers := '{"Content-Type": "application/json", "Authorization": "Bearer SERVICE_ROLE"}'::jsonb,
    body := jsonb_build_object('post_id', NEW.post_id)
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_flags
AFTER INSERT ON public.post_flags
FOR EACH ROW EXECUTE FUNCTION public.check_post_flags();
```

---

# PART C: FLUTTER IMPLEMENTATION

## C.1 Project Structure

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   ├── theme/
│   └── utils/
├── data/
│   ├── models/
│   ├── repositories/
│   └── services/
│       └── supabase_service.dart
├── domain/
│   ├── entities/
│   └── usecases/
├── presentation/
│   ├── screens/
│   │   ├── auth/
│   │   ├── home/
│   │   ├── train/
│   │   ├── feed/
│   │   └── profile/
│   ├── widgets/
│   └── providers/
└── router.dart
```

## C.2 Supabase Service Singleton

```dart
// lib/data/services/supabase_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  String? get currentAuthId => client.auth.currentUser?.id;

  Future<String?> getCurrentDbUserId() async {
    final authId = currentAuthId;
    if (authId == null) return null;
    final result = await client
        .from('users')
        .select('id')
        .eq('auth_provider_id', authId)
        .single();
    return result['id'] as String?;
  }

  Future<String?> getCurrentGymId() async {
    final authId = currentAuthId;
    if (authId == null) return null;
    final result = await client
        .from('users')
        .select('last_selected_gym_id')
        .eq('auth_provider_id', authId)
        .single();
    return result['last_selected_gym_id'] as String?;
  }

  Future<void> setCurrentGym(String gymId) async {
    final dbUserId = await getCurrentDbUserId();
    if (dbUserId == null) return;
    await client
        .from('users')
        .update({'last_selected_gym_id': gymId})
        .eq('id', dbUserId);
  }

  Future<String?> getCurrentRole() async {
    final gymId = await getCurrentGymId();
    final userId = await getCurrentDbUserId();
    if (gymId == null || userId == null) return null;
    final result = await client
        .from('user_gyms')
        .select('role')
        .eq('user_id', userId)
        .eq('gym_id', gymId)
        .single();
    return result['role'] as String?;
  }
}
```

## C.3 Multi-Gym Selection Screen

```dart
// lib/presentation/screens/auth/gym_selection_screen.dart
import 'package:flutter/material.dart';
import '../../../data/services/supabase_service.dart';

class GymSelectionScreen extends StatefulWidget {
  const GymSelectionScreen({super.key});

  @override
  State<GymSelectionScreen> createState() => _GymSelectionScreenState();
}

class _GymSelectionScreenState extends State<GymSelectionScreen> {
  final _supabase = SupabaseService();
  List<Map<String, dynamic>> _gyms = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadGyms();
  }

  Future<void> _loadGyms() async {
    final userId = await _supabase.getCurrentDbUserId();
    if (userId == null) return;

    final data = await _supabase.client
        .from('user_gyms')
        .select('*, gyms(*)')
        .eq('user_id', userId)
        .eq('is_active', true);

    setState(() {
      _gyms = List<Map<String, dynamic>>.from(data);
      _loading = false;
    });
  }

  Future<void> _selectGym(String gymId) async {
    await _supabase.setCurrentGym(gymId);
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SELECT GYM',
                style: TextStyle(
                  color: Color(0xFFBFFF00),
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose which gym you want to enter today',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 32),
              if (_loading)
                const Center(child: CircularProgressIndicator(color: Color(0xFFBFFF00)))
              else
                ..._gyms.map((gym) => _GymCard(
                  gymName: gym['gyms']['name'],
                  logoUrl: gym['gyms']['logo_url'],
                  role: gym['role'],
                  onTap: () => _selectGym(gym['gym_id']),
                )),
            ],
          ),
        ),
      ),
    );
  }
}

class _GymCard extends StatelessWidget {
  final String gymName;
  final String? logoUrl;
  final String role;
  final VoidCallback onTap;

  const _GymCard({
    required this.gymName,
    this.logoUrl,
    required this.role,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFBFFF00).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            if (logoUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(logoUrl!, width: 56, height: 56, fit: BoxFit.cover),
              )
            else
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFBFFF00).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.fitness_center, color: Color(0xFFBFFF00)),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gymName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: role == 'coach' 
                        ? const Color(0xFFBFFF00).withOpacity(0.15)
                        : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      role.toUpperCase(),
                      style: TextStyle(
                        color: role == 'coach' ? const Color(0xFFBFFF00) : Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}
```

## C.4 Feed Screen with Real-time

```dart
// lib/presentation/screens/feed/feed_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/services/supabase_service.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _supabase = SupabaseService();
  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _notices = [];
  bool _loading = true;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _loadFeed();
    _subscribeToRealtime();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  void _subscribeToRealtime() {
    _channel = _supabase.client
        .channel('feed_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'posts',
          callback: (payload) => _loadFeed(),
        )
        .subscribe();
  }

  Future<void> _loadFeed() async {
    final gymId = await _supabase.getCurrentGymId();
    final userId = await _supabase.getCurrentDbUserId();
    if (gymId == null || userId == null) return;

    final followingData = await _supabase.client
        .from('user_follows')
        .select('following_id')
        .eq('follower_id', userId)
        .eq('gym_id', gymId);

    final followingIds = (followingData as List)
        .map((f) => f['following_id'] as String)
        .toList();
    followingIds.add(userId);

    final noticesData = await _supabase.client
        .from('gym_notices')
        .select('*')
        .eq('gym_id', gymId)
        .order('is_pinned', ascending: false)
        .order('created_at', ascending: false)
        .limit(5);

    final postsData = await _supabase.client
        .from('posts')
        .select('*, users!inner(id, display_name, avatar_url)')
        .eq('gym_id', gymId)
        .eq('is_deleted', false)
        .or('user_id.in.(${followingIds.join(',')}),post_type.eq.coach_tip')
        .order('created_at', ascending: false)
        .limit(20);

    if (mounted) {
      setState(() {
        _notices = List<Map<String, dynamic>>.from(noticesData);
        _posts = List<Map<String, dynamic>>.from(postsData);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'TETHER FEED',
          style: TextStyle(
            color: Color(0xFFBFFF00),
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFBFFF00)))
          : RefreshIndicator(
              color: const Color(0xFFBFFF00),
              backgroundColor: const Color(0xFF1A1A1A),
              onRefresh: _loadFeed,
              child: CustomScrollView(
                slivers: [
                  if (_notices.isNotEmpty)
                    SliverToBoxAdapter(child: _NoticesCarousel(notices: _notices)),
                  if (_posts.isEmpty)
                    const SliverFillRemaining(child: _EmptyFeedState())
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _PostCard(post: _posts[index]),
                        childCount: _posts.length,
                      ),
                    ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePost(context),
        backgroundColor: const Color(0xFFBFFF00),
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text('NEW POST', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showCreatePost(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const CreatePostSheet(),
    );
  }
}

class _EmptyFeedState extends StatelessWidget {
  const _EmptyFeedState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          const Text('NO POSTS YET',
            style: TextStyle(color: Colors.white54, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 8),
          Text('Be the first to share a workout',
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 16)),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.fitness_center, color: Color(0xFFBFFF00)),
            label: const Text('START A WORKOUT', style: TextStyle(color: Color(0xFFBFFF00))),
          ),
        ],
      ),
    );
  }
}

class _NoticesCarousel extends StatelessWidget {
  final List<Map<String, dynamic>> notices;
  const _NoticesCarousel({required this.notices});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: notices.length,
        itemBuilder: (context, index) {
          final notice = notices[index];
          return Container(
            width: 300,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16),
              border: notice['is_pinned']
                  ? Border.all(color: const Color(0xFFBFFF00), width: 1)
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFBFFF00).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    notice['notice_type'].toString().toUpperCase(),
                    style: const TextStyle(color: Color(0xFFBFFF00), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Text(notice['title'],
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          );
        },
      ),
    );
  }
}
```

## C.5 Post Card Widget

```dart
// lib/presentation/screens/feed/post_card.dart
import 'package:flutter/material.dart';
import '../../../data/services/supabase_service.dart';

class PostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _liked = false;
  int _likeCount = 0;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.post['likes_count'] ?? 0;
    _checkIfLiked();
  }

  Future<void> _checkIfLiked() async {
    final userId = await SupabaseService().getCurrentDbUserId();
    if (userId == null) return;
    final data = await SupabaseService().client
        .from('post_likes')
        .select('id')
        .eq('post_id', widget.post['id'])
        .eq('user_id', userId)
        .maybeSingle();
    if (mounted) setState(() => _liked = data != null);
  }

  Future<void> _toggleLike() async {
    final userId = await SupabaseService().getCurrentDbUserId();
    if (userId == null) return;

    setState(() { _liked = !_liked; _likeCount += _liked ? 1 : -1; });

    try {
      if (_liked) {
        await SupabaseService().client.from('post_likes').insert({
          'post_id': widget.post['id'], 'user_id': userId,
        });
      } else {
        await SupabaseService().client.from('post_likes')
            .delete().eq('post_id', widget.post['id']).eq('user_id', userId);
      }
    } catch (e) {
      setState(() { _liked = !_liked; _likeCount += _liked ? 1 : -1; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = (widget.post['image_urls'] as List?) ?? [];
    final isCoachTip = widget.post['post_type'] == 'coach_tip';
    final user = widget.post['users'] as Map<String, dynamic>?;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: isCoachTip
            ? Border.all(color: const Color(0xFFBFFF00).withOpacity(0.5), width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: user?['avatar_url'] != null ? NetworkImage(user!['avatar_url']) : null,
                  backgroundColor: const Color(0xFFBFFF00).withOpacity(0.2),
                  child: user?['avatar_url'] == null ? const Icon(Icons.person, color: Colors.white54, size: 20) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(user?['display_name'] ?? 'Unknown',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          if (isCoachTip) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFBFFF00).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text('COACH', style: TextStyle(color: Color(0xFFBFFF00), fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      Text(_formatTime(widget.post['created_at']),
                        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          if (widget.post['content'] != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(widget.post['content'],
                style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5)),
            ),

          // Images (max 3)
          if (images.isNotEmpty)
            Container(
              height: 240,
              margin: const EdgeInsets.only(top: 12),
              child: PageView.builder(
                itemCount: images.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(images[index], fit: BoxFit.cover, width: double.infinity),
                  ),
                ),
              ),
            ),

          // Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _ActionButton(
                  icon: _liked ? Icons.favorite : Icons.favorite_border,
                  color: _liked ? Colors.red : Colors.white54,
                  count: _likeCount,
                  onTap: _toggleLike,
                ),
                const SizedBox(width: 24),
                _ActionButton(
                  icon: Icons.chat_bubble_outline,
                  color: Colors.white54,
                  count: widget.post['comments_count'] ?? 0,
                  onTap: () {},
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.flag_outlined, color: Colors.white54, size: 20),
                  onPressed: () => _flagPost(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    final dt = DateTime.parse(timestamp);
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _flagPost(BuildContext context) async {
    final userId = await SupabaseService().getCurrentDbUserId();
    if (userId == null) return;
    await SupabaseService().client.from('post_flags').insert({
      'post_id': widget.post['id'], 'user_id': userId,
    });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post flagged for review')));
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int count;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.color, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 6),
          Text(count.toString(), style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
        ],
      ),
    );
  }
}
```

## C.6 Create Post Sheet (3-image limit)

```dart
// lib/presentation/screens/feed/create_post_sheet.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../data/services/supabase_service.dart';

class CreatePostSheet extends StatefulWidget {
  final String? workoutSessionId;
  final String? prefillContent;
  const CreatePostSheet({super.key, this.workoutSessionId, this.prefillContent});

  @override
  State<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<CreatePostSheet> {
  final _contentController = TextEditingController();
  final _picker = ImagePicker();
  final List<XFile> _selectedImages = [];
  bool _isCoach = false;
  bool _isPosting = false;
  String? _postType;

  @override
  void initState() {
    super.initState();
    _contentController.text = widget.prefillContent ?? '';
    _postType = widget.workoutSessionId != null ? 'workout_share' : 'general';
    _checkCoachStatus();
  }

  Future<void> _checkCoachStatus() async {
    final role = await SupabaseService().getCurrentRole();
    if (mounted) setState(() => _isCoach = role == 'coach');
  }

  Future<void> _pickImage() async {
    if (_selectedImages.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 3 images allowed')));
      return;
    }
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _selectedImages.add(image));
  }

  Future<void> _submitPost() async {
    if (_contentController.text.trim().isEmpty && _selectedImages.isEmpty) return;
    setState(() => _isPosting = true);

    try {
      final gymId = await SupabaseService().getCurrentGymId();
      final userId = await SupabaseService().getCurrentDbUserId();
      if (gymId == null || userId == null) throw Exception('Not authenticated');

      final List<String> imageUrls = [];
      for (final image in _selectedImages) {
        final fileName = '${const Uuid().v4()}.jpg';
        final path = 'post-images/$gymId/$fileName';
        await SupabaseService().client.storage.from('post-images').upload(path, File(image.path));
        final url = SupabaseService().client.storage.from('post-images').getPublicUrl(path);
        imageUrls.add(url);
      }

      await SupabaseService().client.from('posts').insert({
        'gym_id': gymId,
        'user_id': userId,
        'content': _contentController.text.trim(),
        'post_type': _postType ?? 'general',
        'workout_session_id': widget.workoutSessionId,
        'image_urls': imageUrls,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post shared!')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('NEW POST', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1)),
                if (_isCoach)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFBFFF00).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _postType = _postType == 'coach_tip' ? 'general' : 'coach_tip';
                      }),
                      child: Text(
                        _postType == 'coach_tip' ? 'COACH TIP' : 'POST AS MEMBER',
                        style: const TextStyle(color: Color(0xFFBFFF00), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              maxLines: 4,
              maxLength: 500,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: _postType == 'coach_tip' 
                  ? 'Share a training tip with your gym...'
                  : 'Share your workout...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                border: InputBorder.none,
                counterStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              ),
            ),
            if (_selectedImages.isNotEmpty)
              Container(
                height: 100,
                margin: const EdgeInsets.symmetric(vertical: 12),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) => Stack(
                    children: [
                      Container(
                        width: 100, height: 100,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: FileImage(File(_selectedImages[index].path)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4, right: 12,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedImages.removeAt(index)),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(Icons.close, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Row(
              children: [
                IconButton(
                  onPressed: _selectedImages.length < 3 ? _pickImage : null,
                  icon: Icon(Icons.image,
                    color: _selectedImages.length < 3 ? const Color(0xFFBFFF00) : Colors.white.withOpacity(0.2)),
                ),
                Text('${_selectedImages.length}/3', style: TextStyle(color: Colors.white.withOpacity(0.4))),
                const Spacer(),
                ElevatedButton(
                  onPressed: _isPosting ? null : _submitPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBFFF00),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: _isPosting
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Text('POST', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

## C.7 Workout Summary → Share Flow

```dart
// lib/presentation/screens/train/workout_summary_screen.dart
import 'package:flutter/material.dart';
import '../feed/create_post_sheet.dart';

class WorkoutSummaryScreen extends StatelessWidget {
  final String sessionId;
  final int exerciseCount;
  final int totalSets;
  final Duration duration;

  const WorkoutSummaryScreen({
    super.key,
    required this.sessionId,
    required this.exerciseCount,
    required this.totalSets,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Color(0xFFBFFF00), size: 80),
              const SizedBox(height: 24),
              const Text('WORKOUT COMPLETE',
                style: TextStyle(color: Color(0xFFBFFF00), fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 2)),
              const SizedBox(height: 32),
              _StatRow(label: 'EXERCISES', value: '$exerciseCount'),
              _StatRow(label: 'TOTAL SETS', value: '$totalSets'),
              _StatRow(label: 'DURATION', value: '${duration.inMinutes}m'),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: () => _shareToFeed(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBFFF00),
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.share),
                label: const Text('SHARE TO FEED', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false),
                child: const Text('SKIP & GO HOME', style: TextStyle(color: Colors.white54)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareToFeed(BuildContext context) {
    final prefill = 'Crushed a workout: $exerciseCount exercises, $totalSets sets in ${duration.inMinutes}m 🔥';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => CreatePostSheet(
        workoutSessionId: sessionId,
        prefillContent: prefill,
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
```

## C.8 Member Directory with Follow

```dart
// lib/presentation/screens/feed/member_directory_screen.dart
import 'package:flutter/material.dart';
import '../../../data/services/supabase_service.dart';

class MemberDirectoryScreen extends StatefulWidget {
  const MemberDirectoryScreen({super.key});

  @override
  State<MemberDirectoryScreen> createState() => _MemberDirectoryScreenState();
}

class _MemberDirectoryScreenState extends State<MemberDirectoryScreen> {
  final _supabase = SupabaseService();
  List<Map<String, dynamic>> _members = [];
  Set<String> _followingIds = {};
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final gymId = await _supabase.getCurrentGymId();
    final userId = await _supabase.getCurrentDbUserId();
    if (gymId == null || userId == null) return;

    final membersData = await _supabase.client
        .from('user_gyms')
        .select('*, users!inner(id, display_name, avatar_url, bio)')
        .eq('gym_id', gymId)
        .eq('is_active', true);

    final followsData = await _supabase.client
        .from('user_follows')
        .select('following_id')
        .eq('follower_id', userId)
        .eq('gym_id', gymId);

    if (mounted) {
      setState(() {
        _members = List<Map<String, dynamic>>.from(membersData)
          .where((m) => m['users']['id'] != userId)
          .toList();
        _followingIds = Set<String>.from(
          followsData.map((f) => f['following_id'] as String)
        );
        _loading = false;
      });
    }
  }

  Future<void> _toggleFollow(String targetUserId) async {
    final gymId = await _supabase.getCurrentGymId();
    final userId = await _supabase.getCurrentDbUserId();
    if (gymId == null || userId == null) return;

    final isFollowing = _followingIds.contains(targetUserId);

    setState(() {
      if (isFollowing) _followingIds.remove(targetUserId);
      else _followingIds.add(targetUserId);
    });

    try {
      if (isFollowing) {
        await _supabase.client.from('user_follows')
            .delete()
            .eq('follower_id', userId)
            .eq('following_id', targetUserId)
            .eq('gym_id', gymId);
      } else {
        await _supabase.client.from('user_follows').insert({
          'follower_id': userId,
          'following_id': targetUserId,
          'gym_id': gymId,
        });
      }
    } catch (e) {
      setState(() {
        if (isFollowing) _followingIds.add(targetUserId);
        else _followingIds.remove(targetUserId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _members.where((m) {
      final name = (m['users']['display_name'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('MEMBERS', style: TextStyle(color: Color(0xFFBFFF00), fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search members...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFBFFF00)))
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final member = filtered[index];
                    final user = member['users'];
                    final isCoach = member['role'] == 'coach';
                    final isFollowing = _followingIds.contains(user['id']);

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: user['avatar_url'] != null ? NetworkImage(user['avatar_url']) : null,
                        backgroundColor: const Color(0xFFBFFF00).withOpacity(0.2),
                        child: user['avatar_url'] == null ? const Icon(Icons.person, color: Colors.white54) : null,
                      ),
                      title: Row(
                        children: [
                          Text(user['display_name'] ?? 'Unknown',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          if (isCoach) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFBFFF00).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text('COACH', style: TextStyle(color: Color(0xFFBFFF00), fontSize: 10)),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(user['bio'] ?? '',
                        style: TextStyle(color: Colors.white.withOpacity(0.5)),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: TextButton(
                        onPressed: () => _toggleFollow(user['id']),
                        style: TextButton.styleFrom(
                          backgroundColor: isFollowing
                            ? Colors.white.withOpacity(0.1)
                            : const Color(0xFFBFFF00).withOpacity(0.15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: Text(
                          isFollowing ? 'FOLLOWING' : 'FOLLOW',
                          style: TextStyle(
                            color: isFollowing ? Colors.white70 : const Color(0xFFBFFF00),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
```


---

# PART D: NEXT.JS ADMIN WEBSITE

## D.1 Project Setup

```bash
npx create-next-app@latest tether-admin --typescript --tailwind --eslint --app --src-dir

cd tether-admin
npm install @supabase/supabase-js @supabase/auth-helpers-nextjs lucide-react
```

## D.2 Supabase Client Setup

```typescript
// src/lib/supabase.ts
import { createClient } from '@supabase/supabase-js'

export const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
)

// Server-side client
import { createServerClient } from '@supabase/auth-helpers-nextjs'
import { cookies } from 'next/headers'

export const createServerSupabase = () => {
  const cookieStore = cookies()
  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    { cookies: { get: (name) => cookieStore.get(name)?.value } }
  )
}
```

## D.3 Middleware (Route Protection)

```typescript
// src/middleware.ts
import { createMiddlewareClient } from '@supabase/auth-helpers-nextjs'
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export async function middleware(req: NextRequest) {
  const res = NextResponse.next()
  const supabase = createMiddlewareClient({ req, res })
  const { data: { session } } = await supabase.auth.getSession()

  if (!session && !req.nextUrl.pathname.startsWith('/login')) {
    return NextResponse.redirect(new URL('/login', req.url))
  }

  // Verify staff role for protected routes
  if (session && req.nextUrl.pathname.startsWith('/dashboard')) {
    const { data: staff } = await supabase
      .from('gym_staff')
      .select('id')
      .eq('auth_provider_id', session.user.id)
      .single()

    if (!staff) {
      return NextResponse.redirect(new URL('/unauthorized', req.url))
    }
  }

  return res
}

export const config = {
  matcher: ['/dashboard/:path*', '/login'],
}
```

## D.4 Login Page

```typescript
// src/app/login/page.tsx
'use client'

import { useState } from 'react'
import { supabase } from '@/lib/supabase'

export default function LoginPage() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    const { error } = await supabase.auth.signInWithPassword({ email, password })
    if (error) alert(error.message)
    else window.location.href = '/dashboard'
    setLoading(false)
  }

  return (
    <div className="min-h-screen bg-[#0A0A0A] flex items-center justify-center">
      <div className="bg-[#1A1A1A] p-8 rounded-2xl w-full max-w-md border border-[#BFFF00]/20">
        <h1 className="text-[#BFFF00] text-3xl font-bold tracking-wider mb-2">TETHER ADMIN</h1>
        <p className="text-white/50 mb-8">Gym Management Portal</p>

        <form onSubmit={handleLogin} className="space-y-4">
          <div>
            <label className="text-white/70 text-sm">Email</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full bg-black/50 border border-white/10 rounded-lg px-4 py-3 text-white mt-1 focus:border-[#BFFF00] outline-none"
              required
            />
          </div>
          <div>
            <label className="text-white/70 text-sm">Password</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full bg-black/50 border border-white/10 rounded-lg px-4 py-3 text-white mt-1 focus:border-[#BFFF00] outline-none"
              required
            />
          </div>
          <button
            type="submit"
            disabled={loading}
            className="w-full bg-[#BFFF00] text-black font-bold py-3 rounded-lg hover:bg-[#BFFF00]/90 transition"
          >
            {loading ? 'Signing in...' : 'SIGN IN'}
          </button>
        </form>
      </div>
    </div>
  )
}
```

## D.5 Dashboard Layout

```typescript
// src/app/dashboard/layout.tsx
import { createServerSupabase } from '@/lib/supabase'
import { redirect } from 'next/navigation'
import Link from 'next/link'

export default async function DashboardLayout({
  children,
}: {
  children: React.ReactNode
}) {
  const supabase = createServerSupabase()
  const { data: { session } } = await supabase.auth.getSession()

  if (!session) redirect('/login')

  const { data: staff } = await supabase
    .from('gym_staff')
    .select('*, gyms(*)')
    .eq('auth_provider_id', session.user.id)
    .single()

  if (!staff) redirect('/unauthorized')

  return (
    <div className="min-h-screen bg-[#0A0A0A] flex">
      {/* Sidebar */}
      <aside className="w-64 bg-[#1A1A1A] border-r border-white/5 p-6">
        <h2 className="text-[#BFFF00] text-xl font-bold tracking-wider mb-8">TETHER</h2>
        <nav className="space-y-2">
          <NavLink href="/dashboard" icon="home">Overview</NavLink>
          <NavLink href="/dashboard/members" icon="users">Members</NavLink>
          <NavLink href="/dashboard/roster" icon="upload">CSV Upload</NavLink>
          <NavLink href="/dashboard/notices" icon="bell">Notices</NavLink>
          <NavLink href="/dashboard/moderation" icon="shield">Moderation</NavLink>
        </nav>

        <div className="mt-auto pt-8 border-t border-white/5">
          <p className="text-white/40 text-sm">{staff.gyms.name}</p>
          <p className="text-white/20 text-xs mt-1">{staff.role}</p>
        </div>
      </aside>

      {/* Main Content */}
      <main className="flex-1 p-8 overflow-auto">
        {children}
      </main>
    </div>
  )
}

function NavLink({ href, icon, children }: { href: string; icon: string; children: React.ReactNode }) {
  return (
    <Link
      href={href}
      className="flex items-center gap-3 text-white/60 hover:text-[#BFFF00] hover:bg-white/5 px-4 py-3 rounded-lg transition"
    >
      <span>{children}</span>
    </Link>
  )
}
```

## D.6 Members Management Page

```typescript
// src/app/dashboard/members/page.tsx
'use client'

import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase'

interface Member {
  id: string
  users: {
    id: string
    display_name: string
    email: string
    avatar_url: string | null
  }
  role: string
  is_active: boolean
  joined_at: string
}

export default function MembersPage() {
  const [members, setMembers] = useState<Member[]>([])
  const [loading, setLoading] = useState(true)
  const [gymId, setGymId] = useState<string>('')

  useEffect(() => {
    loadMembers()
  }, [])

  async function loadMembers() {
    const { data: staff } = await supabase
      .from('gym_staff')
      .select('gym_id')
      .eq('auth_provider_id', (await supabase.auth.getUser()).data.user?.id)
      .single()

    if (!staff) return
    setGymId(staff.gym_id)

    const { data } = await supabase
      .from('user_gyms')
      .select('*, users!inner(id, display_name, email, avatar_url)')
      .eq('gym_id', staff.gym_id)
      .order('joined_at', { ascending: false })

    if (data) setMembers(data as Member[])
    setLoading(false)
  }

  async function toggleRole(userId: string, currentRole: string) {
    const newRole = currentRole === 'coach' ? 'member' : 'coach'
    await supabase
      .from('user_gyms')
      .update({ role: newRole })
      .eq('user_id', userId)
      .eq('gym_id', gymId)
    loadMembers()
  }

  async function deactivateMember(userId: string) {
    await supabase
      .from('user_gyms')
      .update({ is_active: false })
      .eq('user_id', userId)
      .eq('gym_id', gymId)
    loadMembers()
  }

  if (loading) return <div className="text-white">Loading...</div>

  return (
    <div>
      <div className="flex justify-between items-center mb-8">
        <h1 className="text-white text-2xl font-bold">Members</h1>
        <span className="text-white/40">{members.length} total</span>
      </div>

      <div className="bg-[#1A1A1A] rounded-xl border border-white/5 overflow-hidden">
        <table className="w-full">
          <thead className="bg-white/5">
            <tr>
              <th className="text-left text-white/60 text-sm font-medium px-6 py-4">Member</th>
              <th className="text-left text-white/60 text-sm font-medium px-6 py-4">Role</th>
              <th className="text-left text-white/60 text-sm font-medium px-6 py-4">Joined</th>
              <th className="text-right text-white/60 text-sm font-medium px-6 py-4">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-white/5">
            {members.map((member) => (
              <tr key={member.id} className="hover:bg-white/5">
                <td className="px-6 py-4">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-full bg-[#BFFF00]/20 flex items-center justify-center">
                      {member.users.avatar_url ? (
                        <img src={member.users.avatar_url} className="w-10 h-10 rounded-full" />
                      ) : (
                        <span className="text-[#BFFF00] text-sm font-bold">
                          {member.users.display_name?.[0]?.toUpperCase() || '?'}
                        </span>
                      )}
                    </div>
                    <div>
                      <p className="text-white font-medium">{member.users.display_name}</p>
                      <p className="text-white/40 text-sm">{member.users.email}</p>
                    </div>
                  </div>
                </td>
                <td className="px-6 py-4">
                  <span className={`px-3 py-1 rounded-full text-xs font-bold ${
                    member.role === 'coach' 
                      ? 'bg-[#BFFF00]/15 text-[#BFFF00]' 
                      : 'bg-white/10 text-white/60'
                  }`}>
                    {member.role.toUpperCase()}
                  </span>
                </td>
                <td className="px-6 py-4 text-white/40 text-sm">
                  {new Date(member.joined_at).toLocaleDateString()}
                </td>
                <td className="px-6 py-4 text-right">
                  <button
                    onClick={() => toggleRole(member.users.id, member.role)}
                    className="text-[#BFFF00] text-sm hover:underline mr-4"
                  >
                    {member.role === 'coach' ? 'Demote' : 'Make Coach'}
                  </button>
                  <button
                    onClick={() => deactivateMember(member.users.id)}
                    className="text-red-400 text-sm hover:underline"
                  >
                    Remove
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
```

## D.7 CSV Upload Page

```typescript
// src/app/dashboard/roster/page.tsx
'use client'

import { useState } from 'react'
import { supabase } from '@/lib/supabase'

export default function RosterUploadPage() {
  const [csvContent, setCsvContent] = useState('')
  const [uploading, setUploading] = useState(false)
  const [result, setResult] = useState<any>(null)

  const handleFileUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file) return
    const reader = new FileReader()
    reader.onload = (event) => {
      setCsvContent(event.target?.result as string)
    }
    reader.readAsText(file)
  }

  const handleSubmit = async () => {
    setUploading(true)
    const { data: staff } = await supabase
      .from('gym_staff')
      .select('gym_id')
      .eq('auth_provider_id', (await supabase.auth.getUser()).data.user?.id)
      .single()

    const { data: session } = await supabase.auth.getSession()

    const response = await fetch(
      `${process.env.NEXT_PUBLIC_SUPABASE_URL}/functions/v1/process-csv-roster`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${session.session?.access_token}`,
        },
        body: JSON.stringify({
          gymId: staff?.gym_id,
          csvContent,
          defaultRole: 'member',
        }),
      }
    )

    const data = await response.json()
    setResult(data)
    setUploading(false)
  }

  return (
    <div>
      <h1 className="text-white text-2xl font-bold mb-8">CSV Roster Upload</h1>

      <div className="bg-[#1A1A1A] rounded-xl border border-white/5 p-6 mb-6">
        <p className="text-white/60 mb-4">
          CSV format: member_name, email, phone, external_member_id, role (optional)
        </p>
        <input
          type="file"
          accept=".csv"
          onChange={handleFileUpload}
          className="block w-full text-white/60 file:mr-4 file:py-2 file:px-4 file:rounded-lg file:border-0 file:bg-[#BFFF00] file:text-black file:font-bold hover:file:bg-[#BFFF00]/90"
        />
      </div>

      {csvContent && (
        <div className="bg-[#1A1A1A] rounded-xl border border-white/5 p-6 mb-6">
          <h3 className="text-white font-medium mb-3">Preview</h3>
          <pre className="text-white/40 text-sm overflow-auto max-h-64">{csvContent}</pre>
          <button
            onClick={handleSubmit}
            disabled={uploading}
            className="mt-4 bg-[#BFFF00] text-black font-bold px-6 py-3 rounded-lg hover:bg-[#BFFF00]/90 disabled:opacity-50"
          >
            {uploading ? 'Processing...' : 'Upload Roster'}
          </button>
        </div>
      )}

      {result && (
        <div className="bg-[#1A1A1A] rounded-xl border border-white/5 p-6">
          <p className="text-green-400">Success: {result.success}</p>
          <p className="text-red-400">Failed: {result.failed}</p>
          {result.errors?.length > 0 && (
            <div className="mt-4">
              <p className="text-white/60 mb-2">Errors:</p>
              {result.errors.map((err: string, i: number) => (
                <p key={i} className="text-red-400/60 text-sm">{err}</p>
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  )
}
```

## D.8 Notices Management Page

```typescript
// src/app/dashboard/notices/page.tsx
'use client'

import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase'

interface Notice {
  id: string
  title: string
  content: string
  notice_type: 'announcement' | 'class_update' | 'reminder'
  is_pinned: boolean
  created_at: string
}

export default function NoticesPage() {
  const [notices, setNotices] = useState<Notice[]>([])
  const [gymId, setGymId] = useState('')
  const [newNotice, setNewNotice] = useState({
    title: '',
    content: '',
    notice_type: 'announcement' as const,
    is_pinned: false,
  })

  useEffect(() => {
    loadNotices()
  }, [])

  async function loadNotices() {
    const { data: staff } = await supabase
      .from('gym_staff')
      .select('gym_id')
      .eq('auth_provider_id', (await supabase.auth.getUser()).data.user?.id)
      .single()

    if (!staff) return
    setGymId(staff.gym_id)

    const { data } = await supabase
      .from('gym_notices')
      .select('*')
      .eq('gym_id', staff.gym_id)
      .order('is_pinned', { ascending: false })
      .order('created_at', { ascending: false })

    if (data) setNotices(data as Notice[])
  }

  async function createNotice(e: React.FormEvent) {
    e.preventDefault()
    const { data: staff } = await supabase
      .from('gym_staff')
      .select('id')
      .eq('auth_provider_id', (await supabase.auth.getUser()).data.user?.id)
      .single()

    await supabase.from('gym_notices').insert({
      gym_id: gymId,
      staff_id: staff?.id,
      ...newNotice,
    })

    setNewNotice({ title: '', content: '', notice_type: 'announcement', is_pinned: false })
    loadNotices()
  }

  async function deleteNotice(id: string) {
    await supabase.from('gym_notices').delete().eq('id', id)
    loadNotices()
  }

  return (
    <div>
      <h1 className="text-white text-2xl font-bold mb-8">Gym Notices</h1>

      {/* Create Notice Form */}
      <form onSubmit={createNotice} className="bg-[#1A1A1A] rounded-xl border border-white/5 p-6 mb-8">
        <h3 className="text-white font-medium mb-4">Create New Notice</h3>
        <div className="space-y-4">
          <input
            type="text"
            placeholder="Title"
            value={newNotice.title}
            onChange={(e) => setNewNotice({ ...newNotice, title: e.target.value })}
            className="w-full bg-black/50 border border-white/10 rounded-lg px-4 py-3 text-white placeholder:text-white/30"
            required
          />
          <textarea
            placeholder="Content (optional)"
            value={newNotice.content}
            onChange={(e) => setNewNotice({ ...newNotice, content: e.target.value })}
            className="w-full bg-black/50 border border-white/10 rounded-lg px-4 py-3 text-white placeholder:text-white/30 h-24"
          />
          <div className="flex gap-4">
            <select
              value={newNotice.notice_type}
              onChange={(e) => setNewNotice({ ...newNotice, notice_type: e.target.value as any })}
              className="bg-black/50 border border-white/10 rounded-lg px-4 py-3 text-white"
            >
              <option value="announcement">Announcement</option>
              <option value="class_update">Class Update</option>
              <option value="reminder">Reminder</option>
            </select>
            <label className="flex items-center gap-2 text-white/60">
              <input
                type="checkbox"
                checked={newNotice.is_pinned}
                onChange={(e) => setNewNotice({ ...newNotice, is_pinned: e.target.checked })}
                className="accent-[#BFFF00]"
              />
              Pin to top
            </label>
          </div>
          <button
            type="submit"
            className="bg-[#BFFF00] text-black font-bold px-6 py-3 rounded-lg hover:bg-[#BFFF00]/90"
          >
            Post Notice
          </button>
        </div>
      </form>

      {/* Notices List */}
      <div className="space-y-4">
        {notices.map((notice) => (
          <div
            key={notice.id}
            className={`bg-[#1A1A1A] rounded-xl border p-6 ${
              notice.is_pinned ? 'border-[#BFFF00]/30' : 'border-white/5'
            }`}
          >
            <div className="flex justify-between items-start mb-2">
              <div className="flex items-center gap-3">
                <span className={`px-3 py-1 rounded-full text-xs font-bold ${
                  notice.notice_type === 'announcement'
                    ? 'bg-[#BFFF00]/15 text-[#BFFF00]'
                    : notice.notice_type === 'class_update'
                    ? 'bg-blue-500/15 text-blue-400'
                    : 'bg-orange-500/15 text-orange-400'
                }`}>
                  {notice.notice_type.replace('_', ' ').toUpperCase()}
                </span>
                {notice.is_pinned && (
                  <span className="text-[#BFFF00] text-xs">PINNED</span>
                )}
              </div>
              <button
                onClick={() => deleteNotice(notice.id)}
                className="text-red-400 text-sm hover:underline"
              >
                Delete
              </button>
            </div>
            <h3 className="text-white font-bold text-lg">{notice.title}</h3>
            {notice.content && (
              <p className="text-white/60 mt-2">{notice.content}</p>
            )}
          </div>
        ))}
      </div>
    </div>
  )
}
```

## D.9 Moderation Page

```typescript
// src/app/dashboard/moderation/page.tsx
'use client'

import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase'

interface FlaggedPost {
  id: string
  content: string
  post_type: string
  users: { display_name: string }
  flag_count: number
}

export default function ModerationPage() {
  const [flaggedPosts, setFlaggedPosts] = useState<FlaggedPost[]>([])

  useEffect(() => {
    loadFlaggedPosts()
  }, [])

  async function loadFlaggedPosts() {
    const { data: staff } = await supabase
      .from('gym_staff')
      .select('gym_id')
      .eq('auth_provider_id', (await supabase.auth.getUser()).data.user?.id)
      .single()

    if (!staff) return

    const { data } = await supabase
      .from('posts')
      .select('*, users!inner(display_name), post_flags(count)')
      .eq('gym_id', staff.gym_id)
      .eq('is_flagged', true)
      .eq('is_deleted', false)

    if (data) {
      setFlaggedPosts(data.map((p: any) => ({
        ...p,
        flag_count: p.post_flags?.[0]?.count || 0,
      })))
    }
  }

  async function approvePost(id: string) {
    await supabase.from('posts').update({ is_flagged: false }).eq('id', id)
    loadFlaggedPosts()
  }

  async function deletePost(id: string) {
    await supabase.from('posts').update({ is_deleted: true }).eq('id', id)
    loadFlaggedPosts()
  }

  return (
    <div>
      <h1 className="text-white text-2xl font-bold mb-8">Content Moderation</h1>

      {flaggedPosts.length === 0 ? (
        <div className="bg-[#1A1A1A] rounded-xl border border-white/5 p-12 text-center">
          <p className="text-white/40">No flagged posts to review</p>
        </div>
      ) : (
        <div className="space-y-4">
          {flaggedPosts.map((post) => (
            <div key={post.id} className="bg-[#1A1A1A] rounded-xl border border-red-500/20 p-6">
              <div className="flex justify-between items-start mb-3">
                <div>
                  <p className="text-white font-medium">{post.users.display_name}</p>
                  <p className="text-red-400 text-sm">{post.flag_count} flags</p>
                </div>
                <span className="text-white/40 text-sm">{post.post_type}</span>
              </div>
              <p className="text-white/70 mb-4">{post.content}</p>
              <div className="flex gap-3">
                <button
                  onClick={() => approvePost(post.id)}
                  className="bg-green-500/20 text-green-400 px-4 py-2 rounded-lg text-sm font-bold hover:bg-green-500/30"
                >
                  Approve
                </button>
                <button
                  onClick={() => deletePost(post.id)}
                  className="bg-red-500/20 text-red-400 px-4 py-2 rounded-lg text-sm font-bold hover:bg-red-500/30"
                >
                  Delete
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
```

---

# PART E: STORAGE BUCKETS & SECURITY

Create these buckets in Supabase Storage with the following policies:

```sql
-- Create buckets (run in SQL editor or Supabase dashboard)
-- avatars, post-images, gym-notices, coach-tips

-- Storage policies
CREATE POLICY "Avatar uploads" ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'avatars' AND auth.role() = 'authenticated');

CREATE POLICY "Avatar public read" ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');

CREATE POLICY "Post image uploads" ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'post-images' AND auth.role() = 'authenticated');

CREATE POLICY "Post image public read" ON storage.objects FOR SELECT
  USING (bucket_id = 'post-images');

CREATE POLICY "Gym notice uploads" ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'gym-notices' AND auth.role() = 'authenticated');

CREATE POLICY "Gym notice public read" ON storage.objects FOR SELECT
  USING (bucket_id = 'gym-notices');
```

---

# PART F: ENVIRONMENT VARIABLES

## Flutter (.env)
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

## Next.js (.env.local)
```
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

## Supabase Edge Functions (.env)
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```
