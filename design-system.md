# Pulse — Design System Reference
### Consolidated from Stitch mockups: Login, Feed, Train, Nutrition, Workout Complete, Notifications, Post Detail, Create Post

Give this whole file to Cursor as context before generating any Flutter UI screen — paste it into a `design.mdc` rule (see bottom) or reference it by path in your prompt.

---

## 1. Color System — maps directly to Flutter's Material 3 `ColorScheme`

These are genuine Material 3 color role names, which means you don't need a custom theme system — define a `ColorScheme.dark(...)` with these exact values and Flutter's Material widgets (buttons, cards, app bars) inherit them automatically.

```dart
const colorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFFFFFFF),
  onPrimary: Color(0xFF283500),
  primaryContainer: Color(0xFFC3F400),      // <- the signature neon lime
  onPrimaryContainer: Color(0xFF556D00),
  secondary: Color(0xFFC8C6C5),
  onSecondary: Color(0xFF313030),
  secondaryContainer: Color(0xFF4A4949),
  onSecondaryContainer: Color(0xFFBAB8B7),
  tertiary: Color(0xFFFFFFFF),
  onTertiary: Color(0xFF313030),
  tertiaryContainer: Color(0xFFE5E2E1),
  onTertiaryContainer: Color(0xFF656464),
  error: Color(0xFFFFB4AB),
  onError: Color(0xFF690005),
  errorContainer: Color(0xFF93000A),
  onErrorContainer: Color(0xFFFFDAD6),
  surface: Color(0xFF121317),
  onSurface: Color(0xFFE3E2E7),
  surfaceContainerLowest: Color(0xFF0D0E12),
  surfaceContainerLow: Color(0xFF1A1B1F),
  surfaceContainer: Color(0xFF1E1F23),
  surfaceContainerHigh: Color(0xFF292A2E),
  surfaceContainerHighest: Color(0xFF343539),
  onSurfaceVariant: Color(0xFFC4C9AC),
  outline: Color(0xFF8E9379),
  outlineVariant: Color(0xFF444933),
  inverseSurface: Color(0xFFE3E2E7),
  onInverseSurface: Color(0xFF2F3034),
  inversePrimary: Color(0xFF506600),
);

// Two extra brand-specific tones used for glow/press states, not part of
// the standard ColorScheme — keep as named constants:
const primaryFixedDim = Color(0xFFABD600);   // pressed/active lime variant
const onPrimaryFixed  = Color(0xFF161E00);   // text/icon on lime buttons
```

**The one non-negotiable rule:** `primaryContainer` (#C3F400, the neon lime) is used ONLY for primary actions, active states, and positive/celebratory moments (PR badges, progress bars, unread indicators). Nothing else touches this color — that restraint is what makes it feel premium instead of garish.

---

## 2. Typography

| Role | Font | Size/Line-height | Weight | Used for |
|---|---|---|---|---|
| `display-lg` | Oswald | 48/56, -0.02em | 700 | Hero stat (e.g. "52 MIN") |
| `headline-lg` | Oswald | 32/40, 0.01em | 600 | Screen titles, desktop |
| `headline-lg-mobile` | Oswald | 28/34 | 600 | Screen titles, mobile (e.g. "WORKOUT COMPLETE", "ACTIVITY") |
| `headline-md` | Oswald | 24/32 | 500 | Buttons, section headers |
| `stat-lg` | Oswald | 36/44 | 700 | Secondary stat numbers (bento grid) |
| `body-lg` | Inter | 18/28 | 400 | Captions, longer text |
| `body-md` | Inter | 16/24 | 400 | Standard body text |
| `label-caps` | JetBrains Mono | 12/16, 0.1em, UPPERCASE | 700 | Every tag/stat label/timestamp — the "data" feel |

**Rule:** Oswald condensed = anything meant to feel bold/heroic. Inter = anything meant to be read comfortably. JetBrains Mono uppercase = every piece of metadata (timestamps, stat labels, tags). Never substitute between these three roles.

---

## 3. Spacing & Shape

```
Spacing scale: unit=8px, stack-sm=12px, gutter=16px, stack-md=24px, container-margin=20px, stack-lg=40px
Border radius: DEFAULT=4px, lg=8px, xl=12px, full=9999px (pill/circle)
```

Cards use `xl` (12px). Buttons and tags use `full` (pill-shaped). Small UI elements (icon badges) use `lg` (8px).

---

## 4. Signature Effects

```css
/* Glassmorphism panel — used for cards, stat tiles, toggle sections */
background: rgba(18, 19, 23, 0.6);
backdrop-filter: blur(16px);
border: 1px solid rgba(255, 255, 255, 0.1);

/* Neon glow — used on PR badges, primary buttons, unread notification accents */
box-shadow: 0 0 20px rgba(195, 244, 0, 0.15);   /* subtle, resting */
box-shadow: 0 0 20px rgba(195, 244, 0, 0.2-0.3); /* stronger, on primary CTAs */

/* Photo scrim — dark gradient over hero photography so text stays legible */
background: linear-gradient(to top, rgba(18,19,23,1) 0%, rgba(18,19,23,0.8) 40%, rgba(18,19,23,0.3) 100%);
```

Flutter equivalents: `BackdropFilter` + `ImageFilter.blur(sigmaX: 16, sigmaY: 16)` for glass panels; `BoxShadow(color: primaryContainer.withOpacity(0.15-0.3), blurRadius: 20)` for glow; `LinearGradient` in a `ShaderMask` or stacked `Container` for the photo scrim.

---

## 5. Icons

**System: Material Symbols Outlined**, variable weight (200–400 depending on context, heavier weight when active/emphasized), with `FILL 1` applied for "active/selected" states (e.g., a filled bell when there are unread notifications, filled heart when already liked).

This is good news for Flutter specifically — Flutter's own `Icons` class is Material Design icons natively, and the `material_symbols_icons` package gives you the exact variable-weight/fill outlined variant used in these mockups. No need to source a separate icon library.

**Icons seen in use:** `favorite` (heart/like), `chat_bubble` (comment), `share`, `notifications`, `fitness_center`, `list`, `local_fire_department`, `military_tech` (PR/achievement), `emoji_events` (trophy/announcement), `person`, `public`, `group`, `add_a_photo`, `edit`, `close`, `chevron_right`, `graphic_eq` (music), `open_in_new`, `timer`.

---

## 6. Emoji Usage Rule

Emoji (🔥, 😤) appear **only inside user-generated post captions** — never in system UI chrome (buttons, labels, nav, headers). This keeps the app's own voice clean and technical (matching the JetBrains Mono data-label aesthetic) while letting member posts feel human and social. Don't let this line blur as you add more screens.

---

## 7. Photography / AI Image Generation Style Guide

Every image prompt used so far follows one formula — reuse it for consistency on any new screen needing imagery:

> **"[Shot type], moody/dark-mode high-contrast photography of [subject], illuminated by subtle [neon lime-green / cool-toned] lighting, deep charcoal shadows, gritty/elite/high-performance mood."**

Actual prompts used, for direct reuse:
- **Gym environment (hero/banner):** "Dark, moody, high-contrast photography of a modern elite gym environment. Focus on heavy matte black weight plates and barbells illuminated by subtle, dramatic rim lighting in neon green and cool white. Deep charcoal shadows and a sense of raw intensity."
- **Profile avatar style:** "A close-up, high-contrast portrait of a fit, athletic person looking confidently into the camera, dramatically lit with subtle neon green edge lighting against a dark charcoal background."
- **Equipment detail shot:** "A moody, high-contrast photograph of heavy iron dumbbells racked in a dark, premium gym environment, illuminated by subtle, cool-toned studio lighting, emphasizing the gritty texture of the knurling."
- **Abstract/texture (music, recovery):** "Abstract, moody gradient texture featuring deep charcoal blending into subtle neon electric lime and muted cyan."

---

## 8. Component Library — reusable patterns identified across screens

| Component | Where used | Key traits |
|---|---|---|
| **Top App Bar** | Every screen | Fixed, glass-blurred, bottom border `white/10`, 64px height. Center: PULSE wordmark (lime, Oswald) or screen title. Sides vary: avatar+bell (Feed/Notifications) or back-arrow+kebab (Post Detail) or close+spacer (Create Post) |
| **Primary CTA button** | Log In, Start Training, Done, Post to Feed | Pill shape, solid lime fill, dark text, Oswald uppercase, neon glow shadow, `active:scale-95` press feedback |
| **Secondary/glass button** | Share to Pulse Feed, Join the Community | Pill, glass-panel background, white or lime outline/text |
| **Tag/chip pill** | Stat tags (140 KG, SQUAT, PR), filter chips (ALL/STRENGTH/CARDIO), achievement tag picker | Pill, label-caps font. Selected state = lime border + tinted lime background + glow. Unselected = white/10 border, gray fill. "Add new" = dashed border |
| **Stat tile (bento grid)** | Workout Complete metrics | Glass-panel, rounded-lg, icon + big stat number (stat-lg) + label-caps caption, in a 3-column grid |
| **Feed post card** | Pulse Feed | Rounded-xl, full-bleed image with bottom scrim, tag pills overlaid bottom-left, avatar+name+timestamp header, caption, footer (like/comment/share + counts) |
| **Notification list item** | Notifications | Glass container, 4px left accent border in lime + subtle glow tint if unread, icon-in-circle (filled lime if unread, gray outline if read), bold name + description + label-caps timestamp |
| **Celebration callout** | PR badge on Workout Complete | Glass-panel + neon-glow, colored icon circle (`military_tech`), lime label-caps heading + detail text, chevron affordance |
| **Toggle switch** | Create Post visibility settings | Custom pill switch, lime when on |
| **Bottom fixed action bar** | Create Post, Workout Complete | Glass/blurred, safe-area padded, holds the primary CTA so it's reachable while scrolling |
| **Staff/coach name highlight** | Comments (Post Detail) | A commenter's name renders in lime instead of white when they're gym staff/a coach — a nice existing detail, worth formalizing as a rule: `isStaff ? lime : white` for any displayed name across the app |

---

## 9. Decision Log

- **Reaction icon: resolved to heart (`favorite`).** Post Detail's flame icon was a mockup inconsistency, not an intentional second reaction type — standardize on heart everywhere a like count appears.
- **Login: OTP only, no password field.** Works with either the email or phone number that's on the gym's roster — same flow whether it's someone's first login or their hundredth. No separate "signup" vs "login" screen is needed; `request-otp` handles both by checking roster status.
- Gym name shown on posts ("MARCUS T. · 2 hours ago · Ironforge Gym") — fine as-is for a single-gym pilot, but if a gym chain has multiple locations sharing one feed later, decide whether this is meant to disambiguate locations or is just decorative.

---

## 10. Screen-by-Screen Inventory

| Screen | Purpose | Components used |
|---|---|---|
| **Login** | Gym selection + OTP-based auth (per architecture decision — drop the password field shown in the mockup) | Dropdown (Find Your Gym), input fields, primary + secondary CTA buttons |
| **Feed / Home** (combined, per recommendation above) | Gym announcements, social posts, trainer/fueling tips | Top app bar, horizontal announcement carousel, feed post card, tip cards |
| **Train** | Active plan + workout browsing | Progress card, filter chips, workout cards |
| **Nutrition/Macros** | Daily macro tracking + meal plan | Macro progress bars, meal list items with state-dependent buttons |
| **Workout Complete** | Post-workout summary | Hero stat, stat tile bento grid, celebration callout, secondary button, recovery playlist card, bottom fixed primary CTA |
| **Notifications/Activity** | Notification center | Top app bar, section headers (Today/Earlier), notification list items |
| **Post Detail** | Expanded post view + comments | Top app bar (back+kebab), hero image with overlaid tags, reaction/comment/share row, comment list, comment input |
| **Create Post** | Compose a new post | Top app bar (close+title), photo upload area, caption textarea, tag picker chips, toggle settings, bottom fixed primary CTA |
