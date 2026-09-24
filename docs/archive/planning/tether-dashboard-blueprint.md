# Tether — Gym Admin Dashboard Blueprint

> Design + engineering plan for the Tether gym admin portal: gym info, KPIs, and social feed.
> Companion to the visual reference board (goJim, FitNexus, Gymove, Gymzen styles).

> **Implementation note (locked):** build this UI inside existing **`tether-web/` (Next.js App Router)**, not a Vite greenfield app.
> Keep NestJS staff cookie auth + APIs. Brand accent remains **`#C3F400`**.
> Scope for the rebuild: Overview, Members, Roster, Notices, Feed, Settings.
> Classes / Payments / live occupancy / revenue charts wait until backend data exists.
> Capacity heatmap may ship as a **visual placeholder** labeled non-live.

---

## 1. Tech stack

| Layer | Choice (locked) | Why |
|---|---|---|
| Framework | **Next.js 15 (`tether-web/`)** | Already hosts marketing + staff portal + cookie auth |
| Language | **TypeScript** | Catches data-shape bugs in dashboard code early |
| Styling | **Tailwind CSS v4** + shared CSS utilities | Modern card/grid aesthetic without rewriting the app |
| Components | Shared `src/components/dashboard/*` | KPI / pills / panels — grow toward shadcn patterns later |
| Icons | **lucide-react** | Clean stroke icons matching the reference designs |
| Charts | Defer Recharts | No revenue series yet; use placeholders |
| Data | Nest staff APIs via `apiFetch` | Existing `/gyms`, `/roster`, `/staff/notices`, `/staff/social` |
| Routing | Next App Router | `/dashboard`, `/dashboard/members`, … |

### Backend path (locked)

- **NestJS + Prisma + Supabase Auth/Storage** (existing `gym-app-backend/`).
- Do not point the portal at Supabase tables directly for staff CRUD.

### Install (tether-web)

```bash
cd tether-web
npm i tailwindcss @tailwindcss/postcss postcss lucide-react
```

---

## 2. Design system decisions (the "modern cards" look)

What makes the references look premium — copy these rules into the `tailwind.config` theme:

- **Theme:** Dark mode default (goJim / FitNexus style). Accent used *sparingly*: one brand color (lime or orange) for primary buttons, active nav, and chart highlights; everything else stays neutral gray.
- **Cards:** `rounded-2xl`, border at 6–8% white opacity, subtle background raise, `hover: -translate-y-0.5` + shadow on lift. Never hard black-on-white borders.
- **KPI cards:** big tabular number (28–32px), small delta chip (`+3.1%` green tint / `-1.3%` red tint), tiny icon top-right in a tinted circle.
- **Status pills:** tinted backgrounds at 10–15% opacity — `Active` green, `Expired` red, `In progress` amber. Never solid fills.
- **Status color coding** for workouts/memberships: finished / in-progress / unfinished.
- **Typography:** one sans font (Inter), two weights (400 and 500–600), generous line-height. Numbers use `font-variant-numeric: tabular-nums`.
- **Spacing:** 4 / 8 / 12 / 16 / 24px scale, 12–16px gaps between cards, 20–24px page padding.
- **Chart colors:** sequential same-hue opacity steps for one metric; categorical hues (max 5) only for truly independent series. Never rely on color alone — always label.

### Tailwind token sketch

```js
// tailwind.config.js (excerpt)
theme: {
  extend: {
    colors: {
      brand: '#B8F135',            // one accent — lime example
      surface: { DEFAULT: '#111214', raised: '#17181B', muted: '#1C1E22' },
      line: 'rgba(255,255,255,0.07)',
    },
    borderRadius: { card: '16px' },
    fontFamily: { sans: ['Inter', 'sans-serif'] },
  },
}
```

---

## 3. Page architecture

```
┌──────────────────────────────────────────────┐
│ Topbar: Tether logo · search · bell · admin  │
├──────┬───────────────────────────────────────┤
│ Nav  │  "Good morning, Dana" + primary CTA   │
│ rail │  [+ New member]  [Create post]        │
│      │                                       │
│ 180px│  KPI row: Members · Active now ·      │
│      │  Revenue · Bookings                   │
│      │                                       │
│      │  [ Revenue bar chart    ] [ Capacity  │
│      │                             heatmap ] │
│      │                                       │
│      │  [ Social feed          ] [ Today's   │
│      │                             classes   │
│      │                           + renewals] │
└──────┴───────────────────────────────────────┘
```

### Routes

1. **Overview** — KPIs, revenue chart (Recharts `BarChart`, one accent hue + opacity steps), gym-capacity heatmap (dot grid, sequential opacity — the goJim widget), pinned announcements, mini "expiring memberships" list.
2. **Members** — TanStack table: name/avatar, plan, expiry, status pill, last visit; search + filter; row click → slide-over drawer (`Dialog`) with member detail.
3. **Feed** — composer at top (`Create post`), posts with avatar, timestamp, like/comment/share, pin-to-top for admins, moderation actions revealed on hover (delete = hover-revealed, per modern UX).
4. **Classes** — weekly schedule grid; today highlighted; class cards with booking count vs. capacity bar.
5. **Payments** — revenue table, outstanding dues, MRR chart.

### Realtime touches

Capacity widget and feed update live via Supabase subscriptions — the "wow" that separates it from a static admin template.

---

## 4. Suggested file structure

```
tether-admin/
├── src/
│   ├── app/               # router, providers, layout
│   │   ├── App.tsx
│   │   ├── routes.tsx
│   │   └── AppLayout.tsx  # topbar + nav rail
│   ├── components/
│   │   ├── ui/            # shadcn components
│   │   ├── KpiCard.tsx
│   │   ├── StatusPill.tsx
│   │   ├── CapacityHeatmap.tsx
│   │   └── RevenueChart.tsx
│   ├── features/
│   │   ├── members/       # table, drawer, forms
│   │   ├── feed/          # composer, post card, like/comment
│   │   ├── classes/       # schedule grid
│   │   └── payments/
│   ├── lib/               # supabase client, utils
│   ├── data/mock.ts       # mock data for Phase 1
│   └── styles/globals.css
├── tailwind.config.js
└── package.json
```

---

## 5. Database sketch (Supabase / Postgres)

```sql
members    (id, name, email, plan_id, status, expires_at, last_visit_at, avatar_url)
classes    (id, name, trainer_id, starts_at, capacity, booked_count)
posts      (id, author_id, body, image_url, pinned, created_at)
likes      (post_id, member_id)
comments   (id, post_id, member_id, body, created_at)
payments   (id, member_id, amount, status, paid_at)
```

---

## 6. Build plan (4 phases)

### Phase 1 — Skeleton (days 1–2)
- Vite + TS + Tailwind + shadcn init
- App shell: topbar + collapsible nav rail
- React Router routes
- Dark theme tokens
- Card / KPI components with mock data in `data/mock.ts`

### Phase 2 — Data surfaces (days 3–5)
- KPI row with delta chips
- Revenue chart (Recharts)
- Capacity heatmap (custom SVG grid — 70 dots, opacity mapped to hourly occupancy)
- Members table with sorting/filtering and status pills

### Phase 3 — Feed + realtime (days 6–8)
- Supabase schema (see §5)
- Composer, like toggles, pinned posts
- TanStack Query wiring
- Realtime subscriptions for feed + capacity

### Phase 4 — Polish (days 9–10)
- Framer Motion page/card transitions
- Animated number counters
- Skeleton loaders, empty states
- Responsive collapse (nav → icons under 1024px)
- Light-mode pass

---

## 7. Patterns worth stealing from the reference board

1. **KPI cards with delta arrows** (members gained/lost, revenue) — every strong example has these
2. **Capacity/occupancy heatmap widget** (goJim's dot matrix is the standout)
3. **Trend ring gauges** for member goals or workout streaks
4. **Status-based color coding** (active/expired members, finished/in-progress workouts)
5. **"Welcome back, [name]" banner** with one clear primary action
