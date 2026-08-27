# Gym Dashboard — Feature Reference

This document tracks all features, moderation tools, and management capabilities
that need to be built into the **gym owner/staff web dashboard**.
Updated as new mobile app features are planned and built.

---

## 1. Member Management

### Roster
- Upload member roster via CSV (name, email, phone, external member ID)
- Manually add individual members
- View all members with status: `unmatched` | `active` | `pending`
- Approve pending members (matches a signup request to a roster entry)
- Remove / deactivate members

### Member Profiles (read-only from dashboard)
- View member profile: display name, gender, body weight, height
- View member's workout history (session list, volume over time)
- View member's streak and achievement history

---

## 2. Content Moderation

### Flagged Posts Queue
- View all posts that have been flagged by members
- Post detail: author, content, image, timestamp, flag count, who flagged it
- Actions per flagged post:
  - **Approve** — clear the flag, post returns to feed
  - **Remove** — soft-delete the post, notify the author (optional)
  - **Ban user from posting** — revoke posting privileges (future)
- Filter queue by: unreviewed | approved | removed

### Post Rules
- Set whether member posts are:
  - Achievement-only (current default)
  - Open (members can post freely)
  - Staff-only (no member posts)
- Set whether posts require staff approval before appearing in the feed (moderation gate)

---

## 3. Announcements

### Create Announcements
- Rich text editor for announcement body
- Optional cover image upload (stored in Supabase Storage)
- Category: `announcement` | `class update` | `reminder` | `event`
- Schedule for future publish date/time
- Target audience: all members | specific membership tier

### Manage Announcements
- View all past and scheduled announcements
- Edit / delete / reschedule announcements
- View read/seen counts (future — requires push receipt tracking)

---

## 4. Programs & Workout Templates

### Default Programs (system-level, `source = 'gym'`)
- Create workout templates visible to all gym members
- Set: name, description, category, difficulty, duration, cover image
- Add exercises to the template with default sets/reps/weight
- Reorder exercises via drag-and-drop
- Publish / unpublish templates (isActive toggle)
- View how many members have used each template (usesCount)

### Program Assignment
- Assign a specific program to a member or group of members
- View active program per member

---

## 5. Exercise Library

### Custom Exercises
- Add gym-specific exercises not in the global library
- Set: name, category, body parts, equipment, instructions, image/gif
- Custom exercises are visible only to members of that gym

---

## 6. Staff Management

### Staff Accounts
- Invite staff by email (sends OTP-based invite)
- Assign role: `admin` | `coach` | `reception`
- Roles and permissions:
  - `admin` — full dashboard access
  - `coach` — can create programs, post announcements, view member profiles
  - `reception` — can manage roster, approve pending members

### Staff Posts (Announcements from mobile)
- Staff with `coach` or `admin` role can post announcements from the mobile app
- A "Post Announcement" button is shown only when the logged-in user has a staff role
- Staff posts are visually distinguished in the feed (lime name, STAFF badge)

---

## 7. Gym Settings

### Gym Profile
- Edit gym name, logo, primary color (used for branding in the app)
- Set gym contact email
- Set subscription tier (managed by platform admin — not editable by gym)

### Operating Hours
- Set gym open/close hours per day
- Mark public holidays (triggers "early close" announcement template)

### Feed Settings
- Toggle: allow member achievement posts | staff-only feed
- Toggle: require approval before posts appear (moderation gate)
- Set default rest timer duration (syncs to member app as a gym default)

---

## 8. Analytics (future — post-launch)

- Weekly active members (members with ≥1 session in the last 7 days)
- Most popular exercises at this gym (by set count)
- Average workout duration per member
- Streak leaderboard
- Program completion rates

---

## 9. Notifications & Push

### Push Token Management
- Dashboard can send push notifications to all members or segments
- Notification types: announcement, class reminder, streak encouragement
- Schedule or send immediately

---

## Implementation Notes

### Authentication
- Gym dashboard uses the same Supabase project but a separate auth flow
- Staff log in via email OTP (same `gym_staff` table, `StaffAuthGuard`)
- Members log in via the mobile app only — no web login for members

### Data Isolation
- All gym data is scoped by `gymId` — a staff member can only see data for their gym
- System-level templates (`source = 'system'`) are read-only from the dashboard

### Moderation Queue API Endpoints (to be built)
```
GET  /staff/moderation/flagged          — list flagged posts for this gym
POST /staff/moderation/:postId/approve  — clear flag
POST /staff/moderation/:postId/remove   — soft-delete post
GET  /staff/announcements               — list gym announcements
POST /staff/announcements               — create announcement
PATCH /staff/announcements/:id          — edit announcement
DELETE /staff/announcements/:id         — delete announcement
```

### Mobile App — Staff-Only UI (to be built alongside dashboard)
- `POST /social/posts` with `type: 'announcement'` — staff only
- Staff role check: backend reads `GymStaff` table for the auth token's email
- Mobile shows "Post Announcement" FAB only when `currentUser.isStaff === true`
- Flagging: `POST /social/posts/:id/flag` — available to all members
