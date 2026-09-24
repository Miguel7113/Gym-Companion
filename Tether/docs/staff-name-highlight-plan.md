# Staff / Coach Name Highlight — Implementation Plan

**Spec origin:** docs/archive/planning/design-system.md §8 Component Library  
> "A commenter's name renders in lime instead of white when they're gym staff/a coach — a nice existing detail, worth formalizing as a rule: `isStaff ? lime : white` for any displayed name across the app."

---

## Current state (placeholder)

The `SocialScreen` feed post cards already carry an `authorIsStaff` boolean on the local `_Post` model and branch on it:

```dart
// lib/features/social/screens/social_screen.dart — _PostHeader
Text(
  post.authorName,
  style: Theme.of(context).textTheme.titleMedium?.copyWith(
    color: post.authorIsStaff
        ? AppTheme.primaryContainer   // lime for staff
        : AppTheme.onSurface,         // white for members
    fontWeight: FontWeight.w600,
  ),
),
```

This is intentionally stubbed — the flag is hardcoded in placeholder data and not yet wired to a real user role from the backend.

---

## Backend work required (Phase 2)

### 1. User model — add `role` field

In `prisma/schema.prisma`, add a `role` column to the `User` table:

```prisma
enum UserRole {
  member
  coach
  staff
  admin
}

model User {
  // ... existing fields
  role  UserRole @default(member)
}
```

Run a migration after this change.

### 2. JWT payload — include role

In `auth/auth.service.ts`, when building the JWT payload after OTP verification, include the user's role:

```typescript
const payload = {
  sub: user.id,
  gymId: user.gymId,
  role: user.role,          // add this
};
```

### 3. API responses — expose role on user objects

Any endpoint that returns a user object embedded in a post, comment, or notification should include the `role` field. Specifically:

- `GET /social/posts` → each post's `author` object should include `role`
- `GET /social/posts/:id/comments` → each comment's `author` object should include `role`
- `GET /notifications` → notification items that reference a user should include `role`

### 4. Gym staff setup

Gym staff are onboarded via the `gym_roster` table and the admin portal. When a gym admin marks a roster member as `coach` or `staff`, that should update the `User.role` field. The admin portal branding/member screen needs a "Set as Coach" action.

---

## Flutter work required

### 1. User model — add `role` field

In `lib/features/auth/models/auth_models.dart`, extend the `User`-like objects:

```dart
enum UserRole { member, coach, staff, admin }

// Add to any model that represents an author / commenter:
final UserRole role;

// Helper:
bool get isStaff =>
    role == UserRole.coach ||
    role == UserRole.staff ||
    role == UserRole.admin;
```

### 2. Shared helper — `nameColor(UserRole role)`

Add to `AppTheme` or a separate `UserDisplayHelper`:

```dart
static Color nameColor(UserRole role) {
  switch (role) {
    case UserRole.coach:
    case UserRole.staff:
    case UserRole.admin:
      return AppTheme.primaryContainer; // lime
    case UserRole.member:
      return AppTheme.onSurface;        // white
  }
}
```

### 3. Apply everywhere a user name appears

Screens / widgets to update once the backend field is live:

| Location | Widget | Current |
|---|---|---|
| Social feed post header | `_PostHeader` in `social_screen.dart` | `authorIsStaff` bool stub → replace with `nameColor(post.author.role)` |
| Post detail comments | Future `post_detail_screen.dart` comment list | Same pattern |
| Notification tiles | `_NotifTile` in `notifications_screen.dart` | Not yet shown — add when notification items carry an `author` |
| Trainer tip card | `_TrainerTipCard` in `home_screen.dart` | Currently static — wire to real coach user object |

### 4. Remove the `authorIsStaff` bool stub

Once the `UserRole` enum is live in the Flutter model, remove the temporary `bool authorIsStaff` field from `_Post` in `social_screen.dart` and replace with `post.author.role`.

---

## Rule (permanent, enforce as you add screens)

> Any widget that displays a user's name must accept either a `UserRole` or an `isStaff` bool and apply `AppTheme.primaryContainer` for staff/coach/admin, `AppTheme.onSurface` for members. No hardcoded white for names — always go through this check.
