# Tether — Gym Admin Dashboard · Implementation Guide

Companion to the interactive design concept (v2). Everything needed to build it in React +
TypeScript + Tailwind: dependencies, design tokens, every component with code, the animation
recipes, mock data, backend notes, and a build order.

---

## 1. Stack

| Layer | Choice | Version note |
|---|---|---|
| Build tool | Vite + React + TypeScript | `npm create vite@latest tether-admin -- --template react-ts` |
| Styling | Tailwind CSS | v3 (or v4 with `@theme`) |
| Components | shadcn/ui (Radix + Tailwind) | `npx shadcn@latest init` |
| Charts | Recharts | the line chart and donut |
| Animations | Framer Motion | entrances, hover, count-up, pop |
| Icons | lucide-react | |
| Tables | TanStack Table v8 | members table |
| Data | TanStack Query | caching + loading/error states |
| Routing | React Router v6 | |
| Backend | Supabase (Postgres + Realtime + Auth) | optional but recommended for live feed/capacity |

### Install

```bash
npm create vite@latest tether-admin -- --template react-ts
cd tether-admin
npm i tailwindcss postcss autoprefixer framer-motion lucide-react recharts react-router-dom @tanstack/react-query @tanstack/react-table
npx shadcn@latest init
npx shadcn@latest add card table badge dialog dropdown-menu avatar separator button
```

Dev server: `npm run dev`

---

## 2. Design tokens

### tailwind.config.ts

```ts
import type { Config } from 'tailwindcss'

export default {
  darkMode: 'class',
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        // one accent family only — all data viz uses these blue steps
        brand: {
          DEFAULT: 'var(--chart-1)',        // #3B82F6-ish; replace with your hex
          62:    'color-mix(in srgb, var(--chart-1) 62%, transparent)',
          38:    'color-mix(in srgb, var(--chart-1) 38%, transparent)',
          20:    'color-mix(in srgb, var(--chart-1) 20%, transparent)',
          tint:  'color-mix(in srgb, var(--chart-1) 5%, transparent)',
        },
        surface: {
          DEFAULT: 'hsl(220 9% 7%)',   // page
          raised:  'hsl(225 8% 10%)',   // cards
          muted:   'hsl(228 7% 14%)',   // hover / chips
        },
        line: 'hsl(0 0% 100% / 0.07)',
      },
      borderRadius: { card: '12px' },
      fontFamily: { sans: ['Inter', 'ui-sans-serif', 'system-ui'] },
      transitionTimingFunction: { out: 'cubic-bezier(.22,.9,.3,1)' },
    },
  },
  plugins: [],
} satisfies Config
```

Replace the `var(--chart-1)` references with your actual accent hex if you are not porting the
tokens from the mockup. Keep the sequential steps (100 / 62 / 38 / 20%) — the donut and heatmap
depend on them.

### src/styles/globals.css (essentials)

```css
@tailwind base; @tailwind components; @tailwind utilities;

@layer base {
  body { @apply bg-surface text-neutral-100 font-sans antialiased; }
  .tnum { font-variant-numeric: tabular-nums; }
}

/* hover lift used on every card */
.card-lift { transition: border-color 150ms cubic-bezier(.22,.9,.3,1), transform 150ms cubic-bezier(.22,.9,.3,1); }
.card-lift:hover { border-color: rgb(255 255 255 / 0.18); transform: translateY(-2px); }
```

---

## 3. Folder structure

```
src/
├── app/
│   ├── App.tsx            # QueryClientProvider + RouterProvider
│   ├── router.tsx         # routes
│   └── AppLayout.tsx      # topbar + nav rail + <Outlet/>
├── components/
│   ├── KpiCard.tsx
│   ├── RangePill.tsx
│   ├── CheckInsChart.tsx
│   ├── MembershipDonut.tsx
│   ├── CapacityHeatmap.tsx
│   ├── ShiftStack.tsx
│   ├── GoalRing.tsx
│   ├── FeedCard.tsx
│   ├── ClassList.tsx
│   ├── ExpiringList.tsx
│   └── MembersTable.tsx
├── features/feed/Composer.tsx
├── pages/
│   ├── OverviewPage.tsx
│   ├── AnalyticsPage.tsx
│   ├── ClassesPage.tsx
│   ├── MembersPage.tsx
│   └── FeedPage.tsx
├── data/mock.ts
├── lib/motion.ts          # shared variants
├── lib/utils.ts           # cn() from shadcn
└── styles/globals.css
```

---

## 4. Mock data — src/data/mock.ts

```ts
export const kpis = [
  { label: 'Members',        value: 1284, delta: '+3.1%', up: true,  tag: 'M' },
  { label: 'Active now',     value: 87,   delta: 'live',  up: true,  tag: 'A', live: true },
  { label: 'Check-ins today',value: 342,  delta: '+12% vs avg', up: true, tag: 'C' },
  { label: 'Class bookings', value: 312,  delta: '-2.4%', up: false, tag: 'B' },
]

export const checkIns: Record<string, { cur: number[]; prev: number[] }> = {
  all:  { cur: [18,24,21,30,27,35,32], prev: [15,20,22,26,24,30,28] },
  hiit: { cur: [8,10,9,14,12,16,13],   prev: [7,9,10,12,11,14,12] },
  spin: { cur: [5,8,7,9,10,12,11],     prev: [4,6,8,7,8,10,9] },
  yoga: { cur: [6,7,8,8,7,9,10],       prev: [5,6,6,7,7,8,9] },
}
export const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun']

export const plans = [
  { name: 'Pro annual', value: 539 },
  { name: 'Monthly',    value: 398 },
  { name: 'Off-peak',   value: 218 },
  { name: 'Student',    value: 129 },
]

export const classes = [
  { time: '6:00 PM', name: 'HIIT Burn',    trainer: 'Maya', booked: 22, capacity: 24 },
  { time: '7:15 PM', name: 'Spin express', trainer: 'Leo',  booked: 14, capacity: 20 },
  { time: '8:00 PM', name: 'Yoga flow',    trainer: 'Ana',  booked: 9,  capacity: 18 },
  { time: '9:00 AM', name: 'Powerlifting', trainer: 'Raj',  booked: 11, capacity: 16 },
  { time: '12:15 PM',name: 'Lunch spin',   trainer: 'Leo',  booked: 18, capacity: 20 },
  { time: '5:30 PM', name: 'Boxing basics',trainer: 'Maya', booked: 7,  capacity: 14 },
]

export const expiring = [
  { name: 'Bessie Cooper', date: 'Oct 2', state: 'due' },
  { name: 'Eleanor Pena',  date: 'Oct 4', state: 'due' },
  { name: 'Cody Fisher',   date: 'Oct 9', state: 'overdue' },
]

export const posts = [
  { id: 1, author: 'Tether official', initials: 'T', color: 'text-brand',  time: 'Pinned · 2h', pinned: true,
    body: 'New spin bikes arrived! 12 Keiser M3i units on the floor starting Monday. Book your first ride now.', likes: 64, comments: 18 },
  { id: 2, author: 'Coach Maya', initials: 'M', color: 'text-purple-400', time: '1h',
    body: "6pm HIIT is full again — adding a 7:15 slot on Thursday. Who's in?", likes: 41, comments: 12 },
  { id: 3, author: 'Dana Ruiz', initials: 'D', color: 'text-emerald-400', time: '3h',
    body: 'September challenge results are in. Top 3 members get a free month — check the board by reception.', likes: 97, comments: 26 },
]

export const members = [
  { name: 'Bessie Cooper', plan: 'Pro annual', status: 'Active',  lastVisit: 'Today' },
  { name: 'Eleanor Pena',  plan: 'Monthly',    status: 'Active',  lastVisit: 'Yesterday' },
  { name: 'Cody Fisher',   plan: 'Monthly',    status: 'Expired', lastVisit: 'Sep 12' },
  { name: 'Ana Garsia',    plan: 'Pro annual', status: 'Active',  lastVisit: 'Today' },
  { name: 'Leo Kramer',    plan: 'Off-peak',   status: 'Frozen',  lastVisit: 'Aug 30' },
]

export const trainers = [
  { name: 'Maya', color: 'text-purple-400' },
  { name: 'Leo',  color: 'text-emerald-400' },
  { name: 'Ana',  color: 'text-rose-400' },
  { name: 'Raj',  color: 'text-neutral-400' },
]
```

---

## 5. Shared motion — src/lib/motion.ts

```ts
export const easeOut = [0.22, 0.9, 0.3, 1] as const

// staggered card entrance — parent wraps a grid of cards
export const staggerParent = {
  hidden: {},
  show: { transition: { staggerChildren: 0.06, delayChildren: 0.05 } },
}
export const cardIn = {
  hidden: { opacity: 0, y: 10 },
  show:   { opacity: 1, y: 0, transition: { duration: 0.45, ease: easeOut } },
}

// count-up easing (matches the mockup's cubic ease-out)
export const countEase = (p: number) => 1 - Math.pow(1 - p, 3)
```

---

## 6. Components

### 6.1 KpiCard.tsx — count-up number, delta pill, live pulse

```tsx
import { motion } from 'framer-motion'
import { useEffect, useRef, useState } from 'react'
import { cardIn } from '../lib/motion'
import { cn } from '../lib/utils'

function useCountUp(target: number, duration = 900, delay = 150) {
  const [val, setVal] = useState(0)
  const raf = useRef<number>()
  useEffect(() => {
    let start: number | undefined
    const t = setTimeout(() => {
      const step = (ts: number) => {
        if (start === undefined) start = ts
        const p = Math.min((ts - start) / duration, 1)
        setVal(Math.round(target * (1 - Math.pow(1 - p, 3))))
        if (p < 1) raf.current = requestAnimationFrame(step)
      }
      raf.current = requestAnimationFrame(step)
    }, delay)
    return () => { clearTimeout(t); cancelAnimationFrame(raf.current!) }
  }, [target, duration, delay])
  return val
}

export function KpiCard({ label, value, delta, up, tag, live, index }:
  { label: string; value: number; delta: string; up: boolean; tag: string; live?: boolean; index: number }) {
  const display = useCountUp(value, 900, 150 + index * 60)
  return (
    <motion.div variants={cardIn}
      className={cn('relative rounded-card border border-line bg-surface-raised p-4 card-lift',
        live && 'bg-brand-tint')}>
      <div className="absolute right-3.5 top-3.5 flex h-7 w-7 items-center justify-center rounded-lg bg-brand-20 text-brand text-xs font-medium">{tag}</div>
      <div className="mb-1 flex items-center gap-1.5 text-xs text-neutral-400">
        {live && <span className="relative flex h-1.5 w-1.5">
          <span className="absolute h-full w-full animate-ping rounded-full bg-emerald-400 opacity-60" />
          <span className="h-1.5 w-1.5 rounded-full bg-emerald-400" />
        </span>}
        {label}
      </div>
      <div className={cn('tnum text-[28px] font-medium leading-[1.1]', live && 'text-brand')}>
        {display.toLocaleString()}
      </div>
      <div className="mt-1.5">
        <span className={cn('rounded-md px-2 py-px text-xs font-medium',
          up ? 'bg-emerald-400/10 text-emerald-400' : 'bg-rose-400/10 text-rose-400')}>{delta}</span>
      </div>
    </motion.div>
  )
}
```

### 6.2 RangePill.tsx — cycles This week / This month / Today

```tsx
import { useState } from 'react'
import { ChevronDown } from 'lucide-react'

const RANGES = ['This week', 'This month', 'Today']
export function RangePill({ onChange }: { onChange?: (r: string) => void }) {
  const [i, setI] = useState(0)
  return (
    <button onClick={() => { const n = (i + 1) % RANGES.length; setI(n); onChange?.(RANGES[n]) }}
      className="flex items-center gap-1.5 rounded-full border border-line px-3.5 py-1.5 text-[13px] text-neutral-400 hover:text-neutral-200 transition-colors">
      {RANGES[i]} <ChevronDown size={12} />
    </button>
  )
}
```

### 6.3 CheckInsChart.tsx — line chart + filter chips (draw-on animation)

```tsx
import { useMemo, useState } from 'react'
import { Area, CartesianGrid, Line, LineChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts'
import { checkIns, days } from '../data/mock'
import { cn } from '../lib/utils'

const CHIPS = [['all', 'All classes'], ['hiit', 'HIIT'], ['spin', 'Spin'], ['yoga', 'Yoga']] as const

export function CheckInsChart() {
  const [chip, setChip] = useState<string>('all')
  // re-key the chart on chip change so Recharts replays its entrance animation
  const data = useMemo(() =>
    days.map((d, i) => ({ day: d, cur: checkIns[chip].cur[i], prev: checkIns[chip].prev[i] })), [chip])

  return (
    <div className="flex flex-col rounded-card border border-line bg-surface-raised p-4 card-lift">
      <div className="mb-2 flex flex-wrap items-center gap-2 text-xs text-neutral-400">
        <span className="mr-auto text-sm font-medium text-neutral-100">Member check-ins</span>
        <span className="flex items-center gap-1.5"><span className="h-0.5 w-3.5 rounded bg-brand" />This week</span>
        <span className="flex items-center gap-1.5"><span className="w-3.5 border-t border-dashed border-neutral-500" />Last week</span>
      </div>
      <div className="mb-2 flex flex-wrap gap-2">
        {CHIPS.map(([k, label]) => (
          <button key={k} onClick={() => setChip(k)}
            className={cn('rounded-lg border px-3 py-1.5 text-[13px] transition-colors',
              chip === k ? 'border-neutral-100 bg-neutral-100 text-surface'
                         : 'border-line text-neutral-400 hover:text-neutral-200')}>
            {label}
          </button>
        ))}
      </div>
      <ResponsiveContainer width="100%" height={230}>
        <LineChart key={chip} data={data} margin={{ top: 8, right: 8, bottom: 0, left: -18 }}>
          <CartesianGrid stroke="var(--line-color, rgba(255,255,255,.07))" vertical={false} />
          <XAxis dataKey="day" tick={{ fontSize: 11, fill: '#737373' }} axisLine={false} tickLine={false} />
          <YAxis domain={[0, 40]} tick={{ fontSize: 11, fill: '#737373' }} axisLine={false} tickLine={false} />
          <Tooltip contentStyle={{ background: '#17181B', border: '1px solid rgba(255,255,255,.07)', borderRadius: 10, fontSize: 13 }}
                   labelStyle={{ color: '#a3a3a3' }} />
          <Area type="monotone" dataKey="cur" stroke="none" fill="var(--chart-1)" fillOpacity={0.07} isAnimationActive={true} animationDuration={800} />
          <Line type="monotone" dataKey="prev" stroke="#737373" strokeWidth={2} strokeDasharray="5 5" dot={false}
                animationDuration={900} animationEasing="ease-out" />
          <Line type="monotone" dataKey="cur" stroke="var(--chart-1)" strokeWidth={2.5} dot={{ r: 3.5, fill: '#0B0C0E', stroke: 'var(--chart-1)', strokeWidth: 2 }}
                animationDuration={900} animationEasing="ease-out" />
        </LineChart>
      </ResponsiveContainer>
    </div>
  )
}
```

Note: the mockup's stroke draw-on effect (dash-offset sweep) needs a custom SVG; Recharts'
`animationDuration` entrance is the pragmatic 90% version. If you want the exact sweep, render a
plain `<svg>` with `pathLength` animated by Framer Motion instead of Recharts for that one chart.

### 6.4 MembershipDonut.tsx — sequential blue donut + legend

```tsx
import { useEffect, useState } from 'react'
import { Cell, Pie, PieChart, ResponsiveContainer } from 'recharts'
import { motion } from 'framer-motion'
import { cardIn } from '../lib/motion'
import { plans } from '../data/mock'

const STEPS = ['var(--chart-1)',
  'color-mix(in srgb, var(--chart-1) 62%, transparent)',
  'color-mix(in srgb, var(--chart-1) 38%, transparent)',
  'color-mix(in srgb, var(--chart-1) 20%, transparent)']
const total = plans.reduce((s, p) => s + p.value, 0)

export function MembershipDonut() {
  const [t, setT] = useState(0)
  useEffect(() => { const id = setTimeout(() => setT(total), 900); return () => clearTimeout(id) }, [])
  return (
    <div className="flex flex-col rounded-card border border-line bg-surface-raised p-4 card-lift">
      <div className="mb-2 flex items-center justify-between">
        <span className="text-sm font-medium">Membership plans</span>
        <span className="text-xs text-neutral-400">Active members</span>
      </div>
      <div className="flex items-center gap-4">
        <div className="relative h-[132px] w-[132px] shrink-0">
          <ResponsiveContainer>
            <PieChart>
              <Pie data={plans} dataKey="value" nameKey="name" innerRadius={44} outerRadius={62}
                   startAngle={90} endAngle={-270} stroke="none" isAnimationActive animationDuration={900}>
                {plans.map((_, i) => <Cell key={i} fill={STEPS[i]} />)}
              </Pie>
            </PieChart>
          </ResponsiveContainer>
          <div className="pointer-events-none absolute inset-0 flex flex-col items-center justify-center">
            <span className="tnum text-[21px] font-medium leading-none">{t.toLocaleString()}</span>
            <span className="mt-1 text-[10px] text-neutral-400">members</span>
          </div>
        </div>
        <div className="flex min-w-0 flex-1 flex-col gap-2">
          {plans.map((p, i) => (
            <motion.div key={p.name} variants={cardIn} initial="hidden" animate="show"
              transition={{ delay: 0.3 + i * 0.08 }}
              className="flex items-center gap-2 text-[13px]">
              <span className="h-2.5 w-2.5 shrink-0 rounded-[3px]" style={{ background: STEPS[i] }} />
              <span className="flex-1 text-neutral-300">{p.name}</span>
              <span className="tnum font-medium">{Math.round((p.value / total) * 100)}%</span>
            </motion.div>
          ))}
        </div>
      </div>
    </div>
  )
}
```

### 6.5 CapacityHeatmap.tsx — dot grid (occupancy by hour)

```tsx
import { useMemo } from 'react'
import { motion } from 'framer-motion'

// value 0..1 per cell; 12 columns (hours 6a–9p) x 6 rows (zones/floors)
function cellValue(col: number, row: number) {
  const peak = Math.exp(-Math.pow(col - 8, 2) / 7)      // gaussian peak ~2–6pm
  return Math.max(0.04, Math.min(1, 0.15 + 0.85 * peak - row * 0.14 + Math.sin((col * 6 + row) * 7) * 0.08))
}

export function CapacityHeatmap() {
  const cells = useMemo(() => Array.from({ length: 72 }, (_, i) => ({ col: i % 12, row: Math.floor(i / 12) })), [])
  return (
    <div className="flex flex-col rounded-card border border-line bg-surface-raised p-4 card-lift">
      <div className="mb-3 flex items-center justify-between">
        <span className="text-sm font-medium">Gym capacity</span>
        <span className="text-xs text-neutral-400">Today, by hour</span>
      </div>
      <div className="grid grid-cols-12 gap-1.5">
        {cells.map((c, i) => (
          <motion.div key={i} className="aspect-square w-full rounded-full"
            initial={{ opacity: 0, scale: 0.4 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ delay: 0.35 + i * 0.006, duration: 0.3 }}
            style={{ background: `color-mix(in srgb, var(--chart-1) ${Math.round(cellValue(c.col, c.row) * 100)}%, transparent)`,
                     boxShadow: c.col === 8 && c.row > 2 && c.row < 9 ? '0 0 0 1.5px var(--neutral-100)' : undefined }}
            whileHover={{ scale: 1.5 }} />
        ))}
      </div>
      <div className="mt-2 flex justify-between text-xs text-neutral-400"><span>6a</span><span>12p</span><span>9p</span></div>
    </div>
  )
}
```

### 6.6 ShiftStack.tsx — overlapping avatar stack + plus button

```tsx
import { Plus } from 'lucide-react'
import { motion } from 'framer-motion'
import { trainers } from '../data/mock'

export function ShiftStack() {
  return (
    <div className="flex flex-col rounded-card border border-line bg-surface-raised p-4 card-lift">
      <div className="flex items-center justify-between">
        <span className="text-sm font-medium">Trainers on shift</span>
        <button className="flex h-7 w-7 items-center justify-center rounded-full border border-line text-neutral-400 hover:text-neutral-200 transition-colors">
          <Plus size={13} />
        </button>
      </div>
      <div className="mt-2.5 flex items-center">
        {trainers.map((t, i) => (
          <motion.div key={t.name}
            initial={{ opacity: 0, x: -6 }} animate={{ opacity: 1, x: 0 }}
            transition={{ delay: 0.4 + i * 0.07 }}
            className={`flex h-[34px] w-[34px] items-center justify-center rounded-full border-2 border-surface bg-surface-raised text-xs font-medium ${t.color} ${i > 0 ? '-ml-2' : ''}`}>
            {t.name[0]}
          </motion.div>
        ))}
        <div className="-ml-2 flex h-[34px] w-[34px] items-center justify-center rounded-full border-2 border-surface bg-surface-muted text-[11px] font-medium text-neutral-300">+3</div>
        <div className="ml-auto text-right text-xs text-neutral-400">
          <span className="tnum text-base font-medium text-neutral-100">4</span> on shift<br />
          <span className="tnum text-base font-medium text-neutral-100">9</span> total
        </div>
      </div>
    </div>
  )
}
```

### 6.7 GoalRing.tsx — weekly check-in goal

```tsx
import { motion } from 'framer-motion'

export function GoalRing({ pct = 0.78, size = 96 }: { pct?: number; size?: number }) {
  const r = 38, C = 2 * Math.PI * r
  return (
    <div className="flex flex-col items-center justify-center gap-2 rounded-card border border-line bg-surface-raised p-4 card-lift">
      <span className="self-start text-sm font-medium">Weekly check-in goal</span>
      <svg viewBox="0 0 96 96" style={{ width: size }}>
        <circle cx="48" cy="48" r={r} fill="none" stroke="var(--surface-muted, #1C1E22)" strokeWidth="9" />
        <motion.circle cx="48" cy="48" r={r} fill="none" stroke="var(--chart-1)" strokeWidth="9" strokeLinecap="round"
          transform="rotate(-90 48 48)"
          strokeDasharray={`${pct * C} ${C}`}
          initial={{ strokeDasharray: `0 ${C}` }}
          animate={{ strokeDasharray: `${pct * C} ${C}` }}
          transition={{ duration: 1.1, delay: 0.4, ease: [0.22, 0.9, 0.3, 1] }} />
        <text x="48" y="54" textAnchor="middle" fontSize="19" fontWeight="500" fill="currentColor"
          style={{ fontVariantNumeric: 'tabular-nums' }}>{Math.round(pct * 100)}%</text>
      </svg>
      <div className="text-center text-xs text-neutral-400">1,873 of 2,400 check-ins<br />Tue – Sun · 4 days left</div>
    </div>
  )
}
```

### 6.8 FeedCard.tsx — like pop, pinned badge, hover-revealed actions

```tsx
import { useState } from 'react'
import { motion } from 'framer-motion'
import { Heart, MessageCircle, Share2, Pin, Trash2 } from 'lucide-react'
import { cn } from '../lib/utils'

type Post = { id: number; author: string; initials: string; color: string; time: string; pinned?: boolean; body: string; likes: number; comments: number }

export function FeedCard({ post }: { post: Post }) {
  const [liked, setLiked] = useState(false)
  return (
    <div className="group flex gap-2.5">
      <div className={`flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-surface-muted text-[13px] font-medium ${post.color}`}>
        {post.initials}
      </div>
      <div className="min-w-0 flex-1">
        <div className="flex flex-wrap items-center gap-2">
          <span className="text-sm font-medium">{post.author}</span>
          {post.pinned && (
            <span className="flex items-center gap-1 rounded-md bg-surface-muted px-2 py-px text-xs text-neutral-400">
              <Pin size={10} /> pinned
            </span>
          )}
          <span className="text-xs text-neutral-500">{post.time}</span>
          <button className="ml-auto opacity-0 transition-opacity group-hover:opacity-100 text-neutral-500 hover:text-rose-400" title="Remove">
            <Trash2 size={14} />
          </button>
        </div>
        <p className="my-1 text-sm leading-relaxed text-neutral-300">{post.body}</p>
        <div className="flex gap-4 text-xs text-neutral-400">
          <motion.button whileTap={{ scale: 1.35 }} onClick={() => setLiked(!liked)}
            className={cn('flex items-center gap-1.5 transition-colors', liked && 'text-rose-400')}>
            <Heart size={15} fill={liked ? 'currentColor' : 'none'} />
            {post.likes + (liked ? 1 : 0)}
          </motion.button>
          <span className="flex items-center gap-1.5"><MessageCircle size={15} />{post.comments}</span>
          <span className="flex items-center gap-1.5"><Share2 size={15} />Share</span>
        </div>
      </div>
    </div>
  )
}
```

### 6.9 ClassList.tsx — capacity bars, warn at >90%

```tsx
import { motion } from 'framer-motion'
import { classes } from '../data/mock'

export function ClassList({ items = classes.slice(0, 3) }: { items?: typeof classes }) {
  return (
    <div className="flex flex-col gap-2.5">
      {items.map((c, i) => {
        const pct = Math.round((c.booked / c.capacity) * 100)
        return (
          <div key={c.name}>
            <div className="flex justify-between text-[13px]">
              <span className="font-medium">{c.name}</span>
              <span className="text-neutral-400">{c.time}</span>
            </div>
            <div className="mb-[5px] mt-0.5 flex justify-between text-xs text-neutral-500">
              <span>{c.trainer}</span><span>{c.booked}/{c.capacity}</span>
            </div>
            <div className="h-1 overflow-hidden rounded bg-surface-muted">
              <motion.div className="h-full rounded" style={{ background: pct > 90 ? 'var(--color-warning, #EAB308)' : 'var(--chart-1)' }}
                initial={{ width: 0 }} whileInView={{ width: `${pct}%` }} viewport={{ once: true }}
                transition={{ duration: 0.8, delay: 0.2 + i * 0.1, ease: [0.22, 0.9, 0.3, 1] }} />
            </div>
          </div>
        )
      })}
    </div>
  )
}
```

### 6.10 ExpiringList.tsx

```tsx
import { expiring } from '../data/mock'

export function ExpiringList() {
  return (
    <div className="flex flex-col gap-2.5">
      {expiring.map(m => (
        <div key={m.name} className="flex items-center gap-2.5">
          <div className="flex h-[30px] w-[30px] shrink-0 items-center justify-center rounded-full bg-surface-muted text-[11px] font-medium text-neutral-300">
            {m.name.split(' ').map(s => s[0]).join('')}
          </div>
          <div className="min-w-0 flex-1">
            <div className="truncate text-[13px] font-medium">{m.name}</div>
            <div className="text-xs text-neutral-400">Expires {m.date}</div>
          </div>
          <span className={`rounded-md px-2 py-px text-xs font-medium ${
            m.state === 'due' ? 'bg-amber-400/10 text-amber-400' : 'bg-rose-400/10 text-rose-400'}`}>
            {m.state === 'due' ? 'Due soon' : 'Overdue'}
          </span>
        </div>
      ))}
    </div>
  )
}
```

### 6.11 MembersTable.tsx — TanStack Table v8

```tsx
import { createColumnHelper, flexRender, getCoreRowModel, useReactTable } from '@tanstack/react-table'
import { members } from '../data/mock'

type Member = typeof members[number]
const ch = createColumnHelper<Member>()
const pill: Record<string, string> = {
  Active:  'bg-emerald-400/10 text-emerald-400',
  Expired: 'bg-rose-400/10 text-rose-400',
  Frozen:  'bg-amber-400/10 text-amber-400',
}
const cols = [
  ch.accessor('name', { header: 'Member', cell: c => (
    <span className="flex items-center gap-2.5 font-medium">
      <span className="flex h-7 w-7 items-center justify-center rounded-full bg-surface-muted text-[11px] text-neutral-300">
        {c.getValue().split(' ').map((s: string) => s[0]).join('')}
      </span>{c.getValue()}</span>) }),
  ch.accessor('plan', { header: 'Plan' }),
  ch.accessor('status', { header: 'Status', cell: c => (
    <span className={`rounded-md px-2 py-px text-xs font-medium ${pill[c.getValue()]}`}>{c.getValue()}</span>) }),
  ch.accessor('lastVisit', { header: 'Last visit', cell: c => <span className="text-neutral-400 text-[13px]">{c.getValue()}</span> }),
]

export function MembersTable() {
  const table = useReactTable({ data: members, columns: cols, getCoreRowModel: getCoreRowModel() })
  return (
    <div className="rounded-card border border-line bg-surface-raised p-4">
      <div className="mb-3 text-sm font-medium">All members</div>
      <div className="grid grid-cols-[2fr_1fr_1fr_1fr] px-2 pb-2 text-xs text-neutral-500 border-b border-line">
        {table.getHeaderGroups()[0].headers.map(h => <span key={h.id}>{flexRender(h.column.columnDef.header, h.getContext())}</span>)}
      </div>
      {table.getRowModel().rows.map(row => (
        <div key={row.id} className="grid grid-cols-[2fr_1fr_1fr_1fr] items-center border-b border-line px-2 py-2.5 text-sm last:border-0">
          {row.getVisibleCells().map(cell => <span key={cell.id}>{flexRender(cell.column.columnDef.cell, cell.getContext())}</span>)}
        </div>
      ))}
    </div>
  )
}
```

---

## 7. Pages

### pages/OverviewPage.tsx

```tsx
import { motion } from 'framer-motion'
import { KpiCard } from '../components/KpiCard'
import { CheckInsChart } from '../components/CheckInsChart'
import { MembershipDonut } from '../components/MembershipDonut'
import { CapacityHeatmap } from '../components/CapacityHeatmap'
import { ShiftStack } from '../components/ShiftStack'
import { GoalRing } from '../components/GoalRing'
import { FeedCard } from '../components/FeedCard'
import { ClassList } from '../components/ClassList'
import { ExpiringList } from '../components/ExpiringList'
import { kpis, posts } from '../data/mock'
import { staggerParent } from '../lib/motion'

export function OverviewPage() {
  return (
    <div className="flex flex-col gap-4">
      <motion.div variants={staggerParent} initial="hidden" animate="show"
        className="grid grid-cols-4 gap-3">
        {kpis.map((k, i) => <KpiCard key={k.label} {...k} index={i} />)}
      </motion.div>

      <div className="grid grid-cols-[2fr_1fr] gap-3">
        <CheckInsChart />
        <MembershipDonut />
      </div>

      <div className="grid grid-cols-[2fr_1fr] gap-3">
        <div className="rounded-card border border-line bg-surface-raised p-4 card-lift">
          <div className="mb-3 flex items-center justify-between">
            <span className="text-sm font-medium">Community feed</span>
            <a href="/feed" className="text-[13px] text-neutral-400 hover:text-neutral-200">View all</a>
          </div>
          <div className="flex flex-col gap-3">{posts.slice(0, 2).map(p => <FeedCard key={p.id} post={p} />)}</div>
        </div>
        <div className="flex flex-col gap-3">
          <CapacityHeatmap />
          <ShiftStack />
        </div>
      </div>

      <div className="grid grid-cols-3 gap-3">
        <div className="rounded-card border border-line bg-surface-raised p-4 card-lift">
          <div className="mb-2.5 text-sm font-medium">Today's classes</div>
          <ClassList items={undefined} />
        </div>
        <div className="rounded-card border border-line bg-surface-raised p-4 card-lift">
          <div className="mb-2.5 text-sm font-medium">Expiring memberships</div>
          <ExpiringList />
        </div>
        <GoalRing pct={0.78} />
      </div>
    </div>
  )
}
```

### pages/AnalyticsPage.tsx

```tsx
import { CheckInsChart } from '../components/CheckInsChart'
import { MembershipDonut } from '../components/MembershipDonut'
import { CapacityHeatmap } from '../components/CapacityHeatmap'

export function AnalyticsPage() {
  return (
    <div className="flex flex-col gap-3">
      <CheckInsChart />
      <div className="grid grid-cols-2 gap-3">
        <MembershipDonut />
        <CapacityHeatmap />
      </div>
    </div>
  )
}
```

### pages/ClassesPage.tsx — three-column: today / this week / expiring

```tsx
import { ClassList } from '../components/ClassList'
import { ExpiringList } from '../components/ExpiringList'
import { classes } from '../data/mock'

export function ClassesPage() {
  return (
    <div className="grid grid-cols-3 gap-3">
      <Panel title="Today's classes"><ClassList items={classes.slice(0, 4)} /></Panel>
      <Panel title="This week"><ClassList items={classes.slice(2, 6)} /></Panel>
      <Panel title="Expiring memberships"><ExpiringList /></Panel>
    </div>
  )
}
function Panel({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div className="flex flex-col rounded-card border border-line bg-surface-raised p-4 card-lift">
      <div className="mb-2.5 text-sm font-medium">{title}</div>
      {children}
    </div>
  )
}
```

### pages/FeedPage.tsx

```tsx
import { FeedCard } from '../components/FeedCard'
import { posts } from '../data/mock'

export function FeedPage() {
  return (
    <div className="flex max-w-[640px] flex-col gap-3">
      <div className="flex items-center gap-2.5 rounded-card border border-line bg-surface-raised p-4">
        <div className="flex h-9 w-9 items-center justify-center rounded-full bg-surface-muted text-[13px] font-medium">DR</div>
        <div className="flex-1 rounded-[10px] border border-line px-3 py-2 text-sm text-neutral-400">
          Announce something to your members…
        </div>
        <button className="rounded-[10px] bg-neutral-100 px-4 py-2 text-sm font-medium text-surface">Post</button>
      </div>
      <div className="flex flex-col gap-3">
        {posts.map(p => (
          <div key={p.id} className="rounded-card border border-line bg-surface-raised p-4 card-lift"><FeedCard post={p} /></div>
        ))}
      </div>
    </div>
  )
}
```

### app/AppLayout.tsx — topbar + nav rail

```tsx
import { Outlet, NavLink } from 'react-router-dom'
import { LayoutList, Users, LineChart, CalendarDays, Mail, ShieldCheck, Settings, Bell, Plus } from 'lucide-react'
import { RangePill } from '../components/RangePill'

const NAV = [
  { to: '/',            icon: LayoutList,   label: 'Overview'  },
  { to: '/members',     icon: Users,        label: 'Members'   },
  { to: '/analytics',   icon: LineChart,    label: 'Analytics' },
  { to: '/classes',     icon: CalendarDays, label: 'Classes'   },
  { to: '/feed',        icon: Mail,         label: 'Feed'      },
  { to: '/payments',    icon: ShieldCheck,  label: 'Payments'  },
]

export function AppLayout() {
  return (
    <div className="flex min-h-screen gap-4 p-5">
      <aside className="flex w-[168px] shrink-0 flex-col gap-1">
        <div className="flex items-center gap-2 px-2.5 pb-4 pt-2">
          <div className="flex h-7 w-7 items-center justify-center rounded-lg bg-neutral-100 text-[15px] font-medium text-surface">T</div>
          <span className="text-base font-medium">Tether</span>
        </div>
        {NAV.map(({ to, icon: Icon, label }) => (
          <NavLink key={to} to={to} end={to === '/'}
            className={({ isActive }) =>
              `flex items-center gap-2.5 rounded-[10px] px-2.5 py-2 text-sm transition-colors ${
                isActive ? 'bg-surface-muted text-neutral-100' : 'text-neutral-400 hover:bg-surface-muted'}`}>
            <Icon size={18} /> {label}
          </NavLink>
        ))}
        <div className="flex-1" />
        <button className="flex items-center gap-2.5 rounded-[10px] px-2.5 py-2 text-sm text-neutral-400 hover:bg-surface-muted">
          <Settings size={18} /> Settings
        </button>
      </aside>

      <main className="flex min-w-0 flex-1 flex-col gap-4">
        <header className="flex items-center gap-3">
          <div className="mr-auto">
            <div className="text-[17px] font-medium">Good evening, Dana</div>
            <div className="mt-0.5 text-[13px] text-neutral-400">Here is your gym at a glance</div>
          </div>
          <RangePill />
          <button className="flex items-center gap-1.5 rounded-[10px] bg-neutral-100 px-4 py-2 text-sm font-medium text-surface">
            <Plus size={14} /> Add member
          </button>
          <button className="relative flex h-9 w-9 items-center justify-center rounded-lg border border-line text-neutral-400">
            <Bell size={18} />
            <span className="absolute right-2 top-[7px] h-[7px] w-[7px] rounded-full bg-rose-500" />
          </button>
          <div className="flex h-9 w-9 items-center justify-center rounded-full bg-purple-400/20 text-[13px] font-medium text-purple-400">DR</div>
        </header>
        <Outlet />
      </main>
    </div>
  )
}
```

### app/router.tsx

```tsx
import { createBrowserRouter } from 'react-router-dom'
import { AppLayout } from './AppLayout'
import { OverviewPage } from '../pages/OverviewPage'
import { AnalyticsPage } from '../pages/AnalyticsPage'
import { ClassesPage } from '../pages/ClassesPage'
import { MembersPage } from '../pages/MembersPage'
import { FeedPage } from '../pages/FeedPage'

export const router = createBrowserRouter([
  { element: <AppLayout />, children: [
    { path: '/', element: <OverviewPage /> },
    { path: '/members', element: <MembersPage /> },
    { path: '/analytics', element: <AnalyticsPage /> },
    { path: '/classes', element: <ClassesPage /> },
    { path: '/feed', element: <FeedPage /> },
  ]},
])
```

(MembersPage = `<div className="max-w-5xl"><MembersTable /></div>` plus a header row with search input.)

---

## 8. Animation reference — the full spec in one place

| Effect | Where | Implementation |
|---|---|---|
| Count-up KPI numbers | KpiCard | `useCountUp` hook, 900ms, cubic ease-out, per-card delay `150 + i*60ms` |
| Staggered card entrance | KPI grid, page sections | `staggerParent` / `cardIn` variants (staggerChildren 0.06) |
| Line chart draw-in | CheckInsChart | Recharts `animationDuration={900}`, `animationEasing="ease-out"`; re-key chart on chip change to replay. Exact SVG sweep = custom pathLength animation |
| Donut sweep + legend stagger | MembershipDonut | Recharts Pie `animationDuration={900}`; legend rows `cardIn` with `delay 0.3 + i*0.08` |
| Heatmap dot pop | CapacityHeatmap | `scale 0.4→1, opacity 0→1`, delay `0.35 + i*0.006` |
| Capacity bar fill | ClassList | `whileInView width: 0→pct%`, 800ms, stagger 100ms |
| Goal ring sweep | GoalRing | `strokeDasharray` animate, 1100ms, delay 400ms |
| Avatar stack slide-in | ShiftStack | `x: -6→0`, stagger 70ms |
| Like pop | FeedCard | `whileTap={{ scale: 1.35 }}` |
| Live pulse | Active-now KPI | Tailwind `animate-ping` on a dot (the one justified looping animation) |
| Card hover lift | all cards | CSS `.card-lift` — translateY(-2px) + border brighten, 150ms |
| Moderation reveal | FeedCard | delete icon `opacity-0 group-hover:opacity-100` |

Global rules: durations 150–1100ms, one easing curve `cubic-bezier(.22,.9,.3,1)`, nothing loops
except the live-status pulse, accent color never used for static decoration.

---

## 9. Backend notes (Supabase)

```sql
create table members (id uuid primary key default gen_random_uuid(),
  name text, email text unique, plan text, status text default 'Active',
  expires_at date, last_visit_at timestamptz, avatar_url text);
create table classes (id uuid primary key default gen_random_uuid(),
  name text, trainer text, starts_at timestamptz, capacity int, booked_count int default 0);
create table posts (id uuid primary key default gen_random_uuid(),
  author_id uuid references members(id), body text, image_url text,
  pinned boolean default false, created_at timestamptz default now());
create table likes (post_id uuid references posts(id) on delete cascade,
  member_id uuid references members(id), primary key (post_id, member_id));
create table comments (id uuid primary key default gen_random_uuid(),
  post_id uuid references posts(id) on delete cascade,
  member_id uuid references members(id), body text, created_at timestamptz default now());
```

- Wrap fetches in TanStack Query (`useQuery(['posts'], …)` etc.).
- **Realtime feed:** `supabase.channel('posts').on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'posts' }, …).subscribe()` → invalidate the `['posts']` query on event.
- **Live capacity / active-now:** same pattern on a `checkins` table, or poll every 30s.
- Row Level Security: admins full access; members can read posts and insert likes/comments on their own behalf.

---

## 10. Build order

1. **Scaffold** — Vite + TS + Tailwind tokens + shadcn init + router + AppLayout (nav + topbar). Verify dark theme renders.
2. **Mock pages** — drop in `data/mock.ts` and the page components; everything should render with zero backend.
3. **Animations pass** — hook up motion.ts variants, useCountUp, Recharts animation props.
4. **Wire backend** — Supabase schema, TanStack Query, replace mock reads with queries.
5. **Realtime** — feed inserts + capacity updates push live.
6. **Polish** — skeleton loaders (render card shells while `isLoading`), empty states, responsive collapse (`w-12` icon-only rail under `lg`), light-mode token pass if wanted.
