# TETHER — Complete Plan & Explanation
## Building the Social Gym App Perfectly

---

## TABLE OF CONTENTS

1. Current State Analysis
2. Key Design Decisions Explained
3. The Multi-Gym Architecture
4. How the Social Feed Works
5. Security Model (RLS Deep Dive)
6. The Auth Flow (Members, Coaches, Admins)
7. Data Flow: App ↔ Website ↔ Database
8. Implementation Phases (Week by Week)
9. Critical Pitfalls to Avoid
10. Scaling Considerations

---

## 1. CURRENT STATE ANALYSIS

Your app is at a strong MVP-plus stage. The workout tracking engine is functional, the UI language is consistent (dark theme, neon lime accents, rounded cards), and the navigation model is intuitive. However, several architectural gaps exist that would block production launch:

### What Works Well
- Workout session tracking with sets, reps, weight, and soft deletes
- Roster-based authentication preventing random signups
- The four-tab navigation model (Home, Train, Feed, Profile)
- Consistent visual hierarchy across screens

### What Needs Fixing Before Launch
- No way to distinguish coaches from members in the app
- Users can only belong to one gym, but your business model implies multi-gym users
- The social tables exist but are not wired to the UI
- Gym notices are hardcoded/static instead of dynamic
- No following system means the feed is either empty or overwhelming
- Row Level Security is missing, making the database unsafe for web access
- The "Share to Feed" flow from a completed workout does not exist yet

### Quick UI Wins
- The empty feed state should always offer a path to action (start a workout)
- The "0 members active" card on Home should open a member directory
- Coach tips should be real database posts, not static content
- The workout summary screen is the perfect place to prompt social sharing

---

## 2. KEY DESIGN DECISIONS EXPLAINED

### Why Multi-Gym Support Matters
A user might have a home gym and a travel gym, or they might switch gyms. Instead of storing gym_id directly on the users table, we created a user_gyms junction table. This means:
- One user can have memberships at multiple gyms
- Each gym membership has its own role (member or coach)
- When logging in, the user sees a gym picker
- The app remembers their last selected gym for convenience

### Why Coaches Use the Same App
Building a separate coach app doubles your maintenance burden. Instead, the same Flutter app reads the user's role from user_gyms and conditionally shows coach features:
- The "New Post" button gains a "Post as Coach Tip" toggle
- Coach profiles display a verified badge
- Coach tips appear in everyone's feed by default (broadcast behavior)
- Coaches can see all member workouts in their gym (for training purposes)

### Why 3 Images Per Post
This is a practical constraint. More than 3 images per post creates storage bloat, slows scroll performance, and complicates the upload UI. Three is enough to tell a workout story (before, during, after) without overwhelming the feed.

### Why Next.js for the Admin Website
Flutter Web is not ideal for data-heavy admin dashboards. It has slow initial load times, poor SEO, and awkward text selection. Next.js gives you:
- Server-side rendering for fast initial loads
- React's mature ecosystem for tables, charts, and forms
- Easy integration with Supabase auth helpers
- Better developer experience for admin CRUD operations

---

## 3. THE MULTI-GYM ARCHITECTURE

### Database Relationship Model

GYMS table is the root. Every other table either belongs directly to a gym or belongs to a user who belongs to a gym.

The critical junction is USER_GYMS:
- user_id references the user
- gym_id references the gym
- role is either "member" or "coach"
- is_active allows soft-removal without deleting history

This replaces the old model where users.gym_id was the single source of truth.

### How Gym Isolation Works
Every database query in the app is filtered by the currently selected gym_id. The user picks their gym at login, and that gym_id is passed into every subsequent query. Row Level Security enforces this at the database level, so even if a malicious client tries to query another gym's data, the database rejects it.

### What Happens When a User Switches Gyms
1. User taps a different gym on the gym selection screen
2. The app updates users.last_selected_gym_id
3. The app refreshes all local state
4. The feed now shows posts from the new gym
5. Their following list is gym-specific (you follow different people at different gyms)

---

## 4. HOW THE SOCIAL FEED WORKS

### Feed Composition
The feed is not just posts. It is a merged timeline of:
1. Pinned gym notices (announcements from the gym admin)
2. Recent gym notices (last 7 days, unpinned)
3. Social posts from people you follow
4. Coach tips (broadcast to all gym members regardless of following)
5. Your own posts

This creates a rich experience where the gym's official voice mixes with community content.

### Following Logic
Following is gym-scoped. You can follow someone at Gym A but not at Gym B. This prevents confusion and keeps each gym's community distinct.

When you follow someone:
- A row is inserted into user_follows
- Their posts start appearing in your feed
- Unfollowing removes the row

### Post Types
There are three types of posts, and each renders differently:

GENERAL: Standard text and image post. Used for casual updates, questions, or bragging about a PR.

WORKOUT_SHARE: Created automatically when a user finishes a workout and taps "Share to Feed." It links back to the workout_session via workout_session_id. The UI shows a special workout card that can be tapped to view the full session details.

COACH_TIP: Only coaches can create these. They render with a lime border and "COACH" badge. They appear in everyone's feed by default because they are authoritative content from the gym's coaching staff.

### The Empty Feed Solution
When a user opens the feed and sees no posts, they see:
- A friendly illustration and "No Posts Yet" message
- A "Start a Workout" button that navigates to the Train tab
- This seeds the social loop: workout → share → feed content → engagement

---

## 5. SECURITY MODEL (RLS DEEP DIVE)

Row Level Security is the gatekeeper. Without it, anyone with your Supabase anon key could read any row in any table. With RLS, every query is checked against policies.

### The Core Pattern
Every policy answers one question: "Is this authenticated user allowed to see/modify this specific row?"

For example, the posts table SELECT policy checks:
"Does this user have an active membership in the gym that owns this post?"

It does this by looking up user_gyms where gym_id matches the post's gym_id and the user is authenticated.

### Why This Matters for the Website
The admin website uses the same Supabase project and the same anon key. The only difference is that gym admins authenticate into gym_staff instead of users. The RLS policies check both tables:
- "Is this user a member of this gym?" (checks user_gyms)
- "OR is this user staff at this gym?" (checks gym_staff)

This means one database serves both audiences safely.

### The Service Role Exception
Edge Functions (serverless functions running in Supabase) use the service role key. They bypass RLS. This is necessary for bulk operations like CSV processing, but it means your Edge Functions must do their own authorization checks. The CSV processor verifies the caller is gym_staff before inserting roster rows.

### Critical Security Rules
1. Never expose the service role key in client code
2. Always enable RLS before adding data
3. Never use "true" as a policy condition except for truly public data
4. Test policies by querying as different users in the Supabase SQL editor

---

## 6. THE AUTH FLOW (MEMBERS, COACHES, ADMINS)

### Member / Coach Signup Flow
1. Gym admin uploads member email/phone to gym_roster via CSV or manual entry
2. User opens the app and enters their email or phone
3. App checks gym_roster: "Is this identifier in our database?"
4. If yes, Supabase Auth sends an OTP or magic link
5. User verifies identity and creates a password
6. App creates a users row linked to the auth account
7. App creates a user_gyms row linking them to their gym
8. If the roster entry had role="coach", user_gyms.role is set to coach
9. User is now fully authenticated and can use the app

### Admin Signup Flow
1. Super admin (you) creates a gym_staff row manually or via a separate super-admin interface
2. Staff member receives an invitation email
3. They sign up via the Next.js website login page
4. Their auth account is linked to gym_staff.auth_provider_id
5. They can now access the dashboard for their gym

### Why This Flow Is Secure
Random people cannot sign up. They must be pre-registered by a gym admin. This prevents spam, ensures gym isolation, and gives gym owners control over their community.

---

## 7. DATA FLOW: APP ↔ WEBSITE ↔ DATABASE

### Normal App Operations
App (Flutter) → Supabase Client (anon key) → RLS Check → Database
All app operations go through RLS. The app never sees data from other gyms.

### Normal Website Operations
Website (Next.js) → Supabase Client (anon key) → RLS Check → Database
Same path, different user table checked by RLS.

### Bulk Operations (CSV Upload)
Website (Next.js) → User selects CSV → Uploads to temporary storage
→ Calls Edge Function (with auth token) → Edge Function verifies staff
→ Edge Function uses service role → Bulk inserts into gym_roster
→ Returns success/failure report

### Why Not Upload Directly from Browser?
Browser uploads with the anon key would hit RLS row-by-row. For 500 roster entries, that's 500 round trips and 500 RLS evaluations. The Edge Function does it in one batch with a single authorization check.

---

## 8. IMPLEMENTATION PHASES (WEEK BY WEEK)

### PHASE 1: FOUNDATION (Weeks 1-2)
Goal: Secure the database and make authentication bulletproof.

Week 1 Tasks:
- Deploy your Supabase project to production
- Run all schema migrations (multi-gym support, posts enhancements, following system, gym notices)
- Enable RLS on every table
- Write and test all RLS policies using the Supabase SQL editor
- Create Storage buckets: avatars, post-images, gym-notices
- Set up Storage policies for image uploads

Week 2 Tasks:
- Implement the multi-gym selection screen in Flutter
- Update auth flow to support gym picking after login
- Fix the user creation flow to insert both users and user_gyms rows
- Test edge cases: user in two gyms, coach at one gym and member at another
- Add avatar_url and bio fields to the profile editing screen

Deliverable: A user can log in, see their gyms, pick one, and view their profile.

### PHASE 2: SOCIAL CORE (Weeks 3-4)
Goal: Make the Feed tab alive with real content.

Week 3 Tasks:
- Build the post composer with 3-image limit
- Implement image compression before upload (critical for mobile performance)
- Add the "Share to Feed" flow on the workout summary screen
- Build the post card widget with like and comment buttons
- Implement real-time subscriptions so likes and comments update live

Week 4 Tasks:
- Build the member directory screen with search
- Implement follow/unfollow functionality
- Wire the feed query to respect the following list
- Add coach badge rendering in posts and member directory
- Build the comments screen (threaded view under each post)
- Implement post flagging with the 3-flag auto-hide rule

Deliverable: A user can finish a workout, share it with photos, browse members, follow people, and see a personalized feed.

### PHASE 3: ADMIN WEBSITE (Weeks 5-6)
Goal: Gym admins can manage everything without your help.

Week 5 Tasks:
- Scaffold the Next.js project with the Tether dark theme
- Build the login page with Supabase auth
- Build the dashboard layout with sidebar navigation
- Implement the members management page (view, search, toggle coach role, deactivate)
- Implement the CSV upload page with preview and Edge Function integration

Week 6 Tasks:
- Build the notices management page (create, edit, delete, pin)
- Build the content moderation page (review flagged posts, approve or delete)
- Add basic analytics (member count, active today, recent posts)
- Deploy the website to Vercel

Deliverable: A gym admin can log in, upload a CSV of 500 members, post a notice, and moderate content.

### PHASE 4: POLISH & SCALE (Week 7+)
Goal: Production readiness and growth features.

Tasks (prioritized):
- Push notifications for new notices, likes, comments, and coach tips
- Deep linking so notifications open the correct screen
- Image optimization pipeline (compress on device, generate thumbnails in Supabase)
- Feed pagination with cursor-based infinite scroll
- Coach tip push notifications to all gym members
- Analytics dashboard for gym admins (busiest hours, popular exercises, member retention)
- App store submission preparation (screenshots, descriptions, privacy policy)

---

## 9. CRITICAL PITFALLS TO AVOID

### Pitfall 1: Forgetting RLS on New Tables
Every table you create must have RLS enabled immediately. It is easy to forget, and it creates a security hole. Make it a habit: create table, enable RLS, write policies, then test.

### Pitfall 2: N+1 Queries in the Feed
Do not query posts, then loop through them to query users one by one. Use Supabase's select with joins:
.select('*, users!inner(display_name, avatar_url)')
This returns everything in one round trip.

### Pitfall 3: Storing Images as Base64
Never store image data in the database. Always use Supabase Storage. Store only the public URL (or path) in the database.

### Pitfall 4: Not Handling Offline States
Your Train tab already shows an offline state. Extend this pattern to the Feed tab. If the user is offline, show cached posts with a "Last updated" timestamp and a retry button.

### Pitfall 5: Hardcoding the Service Role Key
The service role key bypasses all RLS. It must only exist in Edge Functions and server environments. If you accidentally commit it to GitHub or embed it in the Flutter app, your entire database is exposed.

### Pitfall 6: Not Indexing Feed Queries
Without indexes on posts(gym_id, created_at) and user_follows(follower_id), your feed will become unusably slow after a few hundred posts. The schema includes these indexes, but verify they exist.

### Pitfall 7: Ignoring Image Compression
Users will upload 4MB iPhone photos. If you upload these raw, your Storage costs will explode and your feed will load slowly. Compress images to 1080px width and 80% quality before upload.

---

## 10. SCALING CONSIDERATIONS

### When You Hit 1,000 Users Per Gym
- Add pagination to the member directory
- Implement feed pagination (cursor-based, not offset-based)
- Consider adding a materialized view for feed counts (likes, comments)

### When You Hit 10,000 Users Per Gym
- Move the feed query to an Edge Function that returns pre-computed feeds
- Implement Redis caching for gym notices and pinned posts
- Add database read replicas if Supabase supports them in your region

### When You Add a Second Gym Chain
- The multi-gym architecture already supports this
- Consider adding a "franchise" or "chain" table above gyms if you need cross-gym analytics
- Keep each gym's data isolated unless explicitly designed otherwise

### Monetization Path
Your schema includes subscription_tier on both gyms and users. This suggests a freemium model:
- Free members: basic workout tracking, view-only feed
- Premium members: advanced analytics, unlimited post images, custom exercises
- Gym subscription tiers: trial, basic, pro (more admin seats, more storage)

The database is already structured to support this. You just need to gate features based on these tier columns.

---

## SUMMARY

Tether is well-positioned to become a production-grade social fitness platform. The core architecture decisions are sound: roster-based auth prevents spam, the multi-gym junction table supports real-world usage, and the social primitives are already in the schema.

The path forward is:
1. Secure the database with RLS (non-negotiable)
2. Wire the existing social tables to the Flutter UI
3. Build the admin website on Next.js
4. Polish the sharing flow so every workout has a path to the feed

Execute Phase 1 and 2 first. Do not build the website until the app can generate real social data. An admin dashboard is useless without members, posts, and notices to manage.

Your biggest competitive advantage is the gym-specific isolation. General fitness apps are noisy. Tether is intimate, local, and community-driven. Lean into that.
