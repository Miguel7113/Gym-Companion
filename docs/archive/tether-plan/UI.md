What Needs Improvement
Table
Issue	Severity	Details
Neon yellow is too aggressive	🔴 High	The #CCFF00-style lime yellow feels cheap/corporate rather than premium. It vibrates against the dark background and causes eye strain. WHOOP and Strava use more refined accent colors.
Typography is too "techy"	🟡 Medium	The wide letter-spacing + uppercase everywhere feels like a terminal/font from 2010. Modern fitness apps use tighter, more editorial typography.
Muscle anatomy images look dated	🟡 Medium	The 3D anatomical renders feel like stock assets from a medical textbook. They lack the polished illustration style of modern apps.
Cards lack depth/elevation	🟡 Medium	Flat cards with thin borders feel unfinished. Subtle gradients, shadows, or glassmorphism would elevate the premium feel.
Empty states are too plain	🟡 Medium	"Could not load notices" and "Profile details are unavailable" are just text + retry. No illustration, no personality, no helpful guidance.
Iconography is inconsistent	🟡 Medium	Some icons are filled, some outlined, some custom (dumbbell), some standard (home/person). Pick one style and stick to it.
No visual reward for progress	🟡 Medium	"0 workouts today" and "0 day streak" feel punishing rather than motivating. Gamification elements (rings, progress arcs, confetti) would help.
CTA buttons lack hierarchy	🟡 Medium	"START BLANK WORKOUT" and "MY ROUTINES" are the same shape/size. The primary action should dominate visually.
🏆 Top Reference Apps to Study (With Specific Screens)
Here are the apps doing it best right now, and exactly what to steal from each:
1. Hevy — Best Overall Modern Fitness UI
Why study it: Hevy has become the gold standard for workout tracking UI in 2026. It beat Strong in user satisfaction by combining social features with a polished interface.
What to copy:
Muscle heatmap — Instead of static anatomy images, Hevy shows a body silhouette with color-coded heat indicating trained muscles. This is infinitely more modern than your current 3D renders. 
Social feed cards — Workout cards with user avatars, exercise lists, and like/comment actions. Your "Feed" tab could mirror this.
Streak visualization — Hevy uses flame icons + day-by-day bars instead of just a number. Much more motivating than "0".
Screens to screenshot: Muscle heatmap, workout logging flow, social feed, profile stats
2. Strong — Best for Minimal, Fast Logging
Why study it: Strong is the veteran with a 4.9★ rating from 108K reviews. Its UI philosophy is "no fluff" — every pixel serves the core loop of logging sets. 
What to copy:
In-workout logging screen — Large tap targets, swipe-to-complete sets, built-in rest timer. Your "Start Blank Workout" flow should feel this fast.
Plate calculator — A visual tool showing which plates to load. If Tether targets serious lifters, this is a killer feature.
Data-dense but clean — Strong proves you can show sets, reps, weight, and rest time without clutter. Study their spacing and typography. 
Screens to screenshot: Active workout screen, exercise history, plate calculator, progress charts
3. WHOOP — Best for Dark UI + Data Hierarchy
Why study it: WHOOP's app carries 100% of the UX (no screen on the wearable). Their three-tier data disclosure is masterful. 
What to copy:
Three-tier info architecture — Tier 1: Glanceable score (e.g., "Recovery 85%"). Tier 2: Tap for 7-day trend. Tier 3: Deep-dive graph. Apply this to your stats: "7 workouts this week" → tap → weekly bar chart → tap → full history.
Color-coded metrics — Green = good, yellow = moderate, red = needs attention. Your "0 day streak" could turn red as a warning, not just display a number.
Tile customization — Let users reorder their home screen stats cards. Not everyone cares about "Active Today" vs "Day Streak".
Dark UI refinement — WHOOP uses pure black (#000000) backgrounds with subtle elevation layers (#1C1C1E). Your current dark gray feels a bit muddy in comparison.
Screens to screenshot: Overview dashboard, Recovery detail, Sleep trends, Strain coach
4. Strava — Best for Social + Activity Cards
Why study it: Strava turns workout data into social stories. Their activity cards and dark mode are industry-leading. 
What to copy:
Activity card design — Map preview + stats overlay + kudos/comments. Your "Recent Workouts" list could be much richer.
Segment achievements — "PR on Bench Press!" badges with glow effects. Your app should celebrate milestones visually.
Brand color discipline — Strava uses ONE accent color (orange) everywhere. Your neon yellow is fine, but use it more sparingly — maybe only for primary CTAs and active states.
Screens to screenshot: Activity feed, segment details, profile overview, challenge cards
5. Nike Training Club — Best for Imagery + Content Presentation
Why study it: NTC uses full-bleed photography with gradient overlays to make workouts feel cinematic. 
What to copy:
Hero imagery treatment — Your home screen gym photo is good, but add a stronger gradient overlay so text pops more. NTC uses linear-gradient(to top, rgba(0,0,0,0.8), transparent 60%).
Workout program cards — Large thumbnail + difficulty badge + duration. Your "Push Day" card is close, but could use more visual weight.
Typography pairing — NTC uses bold, tight headlines (no wide letter-spacing) with clean body text. Much more editorial than your current all-caps approach.
Screens to screenshot: Workout library, program detail, workout player, achievement screens
6. Freeletics — Best for AI Coaching UI
Why study it: Freeletics uses a stark black/white/blue palette that feels futuristic and focused. Their AI coach interface is clean and uncluttered. 
What to copy:
High-contrast minimalism — If you want to keep the neon yellow, study how Freeletics uses ONE accent color against black/white. Everything else is grayscale.
Input prompts — Their AI coach asks clear questions with big tappable options. If Tether has any onboarding or workout generation, copy this pattern.
Progress rings — Circular progress indicators are more engaging than number counters.
Screens to screenshot: AI coach chat, workout preview, progress dashboard, settings
7. Fitbod — Best for Muscle Recovery Visualization
Why study it: Fitbod tracks muscle recovery and uses that data to recommend exercises. Their body visualization is smarter than static images. 
What to copy:
Recovery state body map — Muscles fade from red (freshly trained) → yellow (recovering) → green (ready). This is way more useful than your current static muscle grid.
Exercise substitution UI — When suggesting alternatives, Fitbod shows a horizontal scroll of options with muscle target icons. Your exercise browser could use this.
Screens to screenshot: Body recovery map, workout generator, exercise substitution, volume analytics
🎨 Specific Design Recommendations for Tether
1. Fix the Accent Color
Your neon yellow (#CCFF00) is too harsh. Try:
Option A (Premium): Desaturate to a more "electric lime" — #B8E600 or #A3D900. Still energetic but less vibrating.
Option B (WHOOP-style): Use the yellow ONLY for CTAs and active nav states. Use white/gray for everything else.
Option C (Strava-style): Add a secondary accent. Yellow for actions, a cool color (cyan or blue) for data/stats.
2. Redesign the Muscle Group Grid
Instead of static 3D renders:
Use a silhouette-style body map (like Hevy/Fitbod)
Add color-coded recovery states (red = trained recently, green = ready)
Show a subtle pulse/glow on recommended muscle groups
Use flat illustration style instead of 3D renders — it's more modern and loads faster
3. Upgrade the Home Screen Stats
Current: 3 cards with big "0" numbers
Better:
Workouts Today: Circular progress ring (0/3) instead of just "0"
Day Streak: Flame icon + 7-day bar chart (filled/empty dots for each day)
Active Today: Avatar stack (overlapping profile pics) + "12 members" text
4. Improve Empty States
Current: Plain text + "RETRY"
Better:
Add a small illustration (dumbbell with a sad face, or a cloud with a lightning bolt)
Change copy to be more conversational: "Your gym notices are taking a rest day. Pull to refresh or try again."
Make the retry button more prominent (full-width, accent color)
5. Typography Overhaul
Current: Wide-spaced uppercase everywhere (TODAY, GYM NOTICES, PROGRAMS)
Better:
Section headers: Sentence case, medium weight, 14px, muted color. E.g., "Today" not "TODAY"
Stats numbers: Large, bold, tight tracking. E.g., 72 not 7 2
Body text: Regular weight, comfortable line height (1.5)
CTAs: Uppercase is fine, but tighten letter-spacing to 0.05em max
6. Add Micro-Interactions
Card press: Scale to 0.98 on tap, subtle shadow reduction
Streak counter: Animate number count-up when opening app
Workout complete: Confetti burst or checkmark animation
Nav switch: Smooth icon morphing (filled ↔ outline)
7. Redesign the "Ready to Train?" Card
Current: Icon + text + arrow
Better:
Full-width image background (gym equipment, darkened)
Large headline: "Ready to train?" (bold, white)
Two stacked buttons: Primary (Start Workout) + Secondary (My Routines)
Subtle gradient glow behind the primary button (neon yellow at 20% opacity)
8. Profile Stats Grid
Current: 4 squares with icons and numbers
Better:
Bigger numbers (32px+), smaller labels
Trend indicators (+2 vs last week) with small arrows
Tap to expand into full-screen charts (WHOOP's three-tier model)
Add a "Weekly Volume" chart — this is what serious lifters care about