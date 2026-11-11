# Tether Redesign - Phase 1 Implementation

**Status:** ✅ Core foundation complete, ready for testing  
**Date:** October 7, 2026  
**Implemented:** Home screen redesign with theme system

---

## What Was Implemented

### 1. Theme System Foundation (✅ Complete)

**Files Created:**
- `lib/core/theme/tether_tokens.dart` - Raw design values (colors, radii, spacing)
- `lib/core/theme/tether_palette.dart` - Light/dark color palette with gym branding support
- `lib/core/theme/tether_text.dart` - Typography system (Bricolage Grotesque + Instrument Serif)

**Usage:**
```dart
final p = context.tether; // Access palette anywhere
Text('Hello', style: TetherText.screenTitle(p.onGround));
```

**Key Features:**
- Automatic light/dark mode support
- Gym accent color integration (ready for branding provider)
- WCAG contrast-compliant text colors
- Consistent typography across all screens

---

### 2. Reusable Widgets (✅ Complete)

**Files Created:**
- `lib/core/widgets/redesign/header_sheet_layout.dart` - Signature Tether layout pattern
- `lib/core/widgets/redesign/section_label.dart` - Uppercase section headers
- `lib/core/widgets/redesign/bento_tile.dart` - Colored cards for grid layout
- `lib/core/widgets/redesign/tether_ring.dart` - Iconic ring graphic with progress
- `lib/core/widgets/redesign/week_strip.dart` - 7-day calendar with workout indicators

**Widget Showcase:**
```dart
// Header + sheet layout
HeaderSheetLayout(
  header: Text('Header on ground color'),
  children: [Text('Content on white/cream sheet')],
);

// Bento card
BentoTile(
  color: palette.accent,
  height: 132,
  onTap: () {},
  child: Text('Card content'),
);

// Week calendar
WeekStrip(days: [
  DayDot('M', DayState.completed),
  DayDot('T', DayState.today, date: '17'),
  DayDot('W', DayState.upcoming),
]);

// Tether ring
TetherRing(size: 190, progress: 0.5); // 50% filled
```

---

### 3. Redesigned Home Screen (✅ Complete)

**File Created:**
- `lib/features/home/screens/home_screen_redesign.dart`

**Features Implemented:**

#### Hero Section
- Personalized greeting ("Morning, Miguel")
- Giant streak number (56pt bold)
- Tether ring graphic with progress fill
- Highlighted text in accent color (serif italic)

#### Week Strip
- 7-day calendar (Monday-Sunday)
- States: completed (check), today (date in circle), upcoming (empty), off (dash)
- Auto-calculates current week
- Shows session count progress

#### Bento Grid Cards

**Class Update Card** (Left, accent color):
- Next class name and time
- "Start workout" CTA button
- Tap to navigate to class details

**Active Workout Card** (Right, always dark):
- Shows "IN PROGRESS" badge if session active
- Session name/notes
- "Resume" button to continue workout
- Falls back to "Ready to train?" when no active session

**Gym Feed Card** (Full width, always dark):
- Shows recent member/coach activity
- Stacked avatars preview
- Tap to open social feed

---

## Testing Instructions

### Option 1: Side-by-Side Comparison

Add a debug toggle to switch between old and new home:

```dart
// In app_shell.dart or home navigation
bool useRedesign = true; // Toggle this

Widget _buildHomeTab() {
  return useRedesign 
    ? const HomeScreenRedesign()
    : const HomeScreen(); // Original
}
```

### Option 2: Direct Replacement

Replace the current home screen import:

```dart
// In your app_shell.dart or nav
import 'package:gym_app_mobile/features/home/screens/home_screen_redesign.dart';

// Use HomeScreenRedesign() instead of HomeScreen()
```

### Option 3: New Route for Testing

Add a route to test redesign independently:

```dart
// In routes or navigation
'/home-redesign': (context) => const HomeScreenRedesign(),
```

---

## Data Integration Status

### ✅ Already Wired
- Streak days (from `homeDataProvider`)
- Active session (from `homeDataProvider`)
- This week session count (from `homeDataProvider`)
- User name (from `authProvider`)

### 🔄 Needs Wiring
- **Week strip workout completion**: Currently shows mock data. Wire to actual workout dates:
  ```dart
  // Check if user worked out on specific date
  final workedOutOnDate = await workoutService.hasWorkoutOnDate(date);
  ```

- **Next class info**: Currently hardcoded to "Pilates open". Wire to:
  ```dart
  // Gym notices or class schedule provider
  final nextClass = ref.watch(nextClassProvider);
  ```

- **Gym logo**: Currently shows placeholder "T". Wire to:
  ```dart
  // From gym branding provider
  final gym = ref.watch(gymBrandingProvider);
  Image.network(gym.logoUrl);
  ```

- **Recent feed avatars**: Shows mock initials. Wire to:
  ```dart
  final recentPosts = ref.watch(recentPostsProvider).take(3);
  ```

---

## Visual Comparison

### Before (Original Home)
- Simple list layout
- Small streak pill
- Basic "Start your streak" card
- No visual hierarchy
- Generic spacing

### After (Redesign)
- Header + sheet layout with depth
- Giant 56pt streak number
- Animated Tether ring graphic
- Personalized greeting
- Bento grid with color-coded cards
- Week calendar visualization
- Dark feature cards (always ink background)

---

## Next Steps

### Immediate (This Week)
1. **Test on Device**
   - Run `flutter run` and navigate to home
   - Toggle between light/dark mode (system settings)
   - Check all cards are tappable
   - Verify text is readable in both modes

2. **Wire Real Data**
   - Replace mock week workout data
   - Connect gym logo
   - Add real next class info
   - Show actual recent posts

3. **Polish**
   - Add animations (ring progress, card taps)
   - Loading states (skeleton loaders)
   - Error states (no data, no internet)

### Phase 2 (Next 2-3 Weeks)
See `DESIGN_PHASES_2-4.md` for:
- Train screen with program carousel
- Feed with expandable posts
- Profile with tabs
- Log workout with timer

---

## Design System Usage

### Colors
```dart
final p = context.tether;

// Surfaces
p.ground      // Screen background
p.sheet       // Raised content area
p.card        // Card backgrounds
p.tile        // Smaller tiles

// Text
p.onGround    // Primary text
p.mutedOnGround // Secondary text
p.accent      // Brand color
p.onAccent    // Text on accent

// Borders & dividers
p.border      // Subtle borders
p.dashed      // Dashed lines
```

### Typography
```dart
// Display text
TetherText.screenTitle(color)       // 40pt bold
TetherText.screenTitleAccent(color) // 46pt serif italic

// Numbers
TetherText.numeral(56, color) // Heavy weight numerals

// Body text
TetherText.cardTitle(color)   // 18pt semi-bold
TetherText.body(color)        // 14pt regular
TetherText.bodySmall(color)   // 13pt regular

// Labels
TetherText.sectionLabel(color) // 11pt uppercase tracking
```

### Layout
```dart
// Spacing
TetherTokens.screenPad  // 20px side padding
TetherTokens.navHeight  // 68px nav bar

// Radii
TetherTokens.rSheet     // 32px sheet corners
TetherTokens.rCard      // 28px card corners
TetherTokens.rTile      // 24px tile corners
```

---

## Known Limitations

### Not Yet Implemented
- [ ] Animations (ring fill, card press, page transitions)
- [ ] Loading skeletons
- [ ] Error states
- [ ] Pull-to-refresh
- [ ] Deep linking from cards
- [ ] Offline mode indicators

### Requires Backend
- [ ] Class schedule API
- [ ] Recent posts API (with limit)
- [ ] Workout history by date
- [ ] Gym branding API

### Future Enhancements
- [ ] Customizable bento grid (users pick cards)
- [ ] Multiple ring variants (monthly, yearly)
- [ ] Streak milestones (7, 30, 100 days)
- [ ] Personal records on home
- [ ] Coach recommendations card

---

## Troubleshooting

### Fonts Not Loading
**Issue:** Bricolage Grotesque or Instrument Serif not showing  
**Fix:** Google Fonts downloads on first run. Check internet connection.

**Alternative:** Download fonts manually and add to `pubspec.yaml`:
```yaml
fonts:
  - family: BricolageGrotesque
    fonts:
      - asset: fonts/BricolageGrotesque-Regular.ttf
      - asset: fonts/BricolageGrotesque-SemiBold.ttf
        weight: 600
      - asset: fonts/BricolageGrotesque-ExtraBold.ttf
        weight: 800
```

### Colors Look Wrong
**Issue:** Accent color not applying or wrong mode colors  
**Fix:** Check `Theme.of(context).brightness` is set correctly. Restart app after theme change.

### Layout Overflows
**Issue:** Text or cards overflow on small screens  
**Fix:** Test on smallest supported device (iPhone SE, ~320px width). May need to reduce font sizes for very small screens.

### Week Strip Not Updating
**Issue:** Today's date not highlighting  
**Fix:** Check device date/time is correct. Week strip calculates from `DateTime.now()`.

---

## Performance Notes

- **Google Fonts**: Downloads fonts on first load (~500KB total). Subsequent loads are cached.
- **Tether Ring**: CustomPainter is efficient, redraws only on progress change.
- **Bento Cards**: Stateless widgets, minimal rebuilds.
- **Week Strip**: Recalculates week on every build - consider memoization if performance issues.

---

## File Structure

```
lib/
├── core/
│   ├── theme/
│   │   ├── tether_tokens.dart      ✅ Design constants
│   │   ├── tether_palette.dart     ✅ Color system
│   │   └── tether_text.dart        ✅ Typography
│   └── widgets/
│       └── redesign/
│           ├── header_sheet_layout.dart ✅
│           ├── section_label.dart       ✅
│           ├── bento_tile.dart          ✅
│           ├── tether_ring.dart         ✅
│           └── week_strip.dart          ✅
└── features/
    └── home/
        └── screens/
            ├── home_screen.dart          (original)
            └── home_screen_redesign.dart ✅ NEW
```

---

## Credits

**Design:** Tether Design Kit v2  
**Implementation:** Phase 1 - Home Screen  
**Typography:** Bricolage Grotesque + Instrument Serif  
**State Management:** Riverpod

---

**Last Updated:** October 7, 2026  
**Next Review:** After device testing  
**Status:** Ready for QA 🚀
