# Admin Portal Guide

## Overview

The admin portal is a **Next.js 14** web application for gym staff (owners, managers, coaches) to manage their gym, members, content, and view analytics.

**Why Next.js instead of Flutter Web?**
- Better for data-heavy dashboards (tables, charts, forms)
- SEO-friendly for potential gym landing pages
- Massive React ecosystem for admin UI components
- Server-side rendering for auth-protected routes

## Tech Stack

- **Framework:** Next.js 14 (App Router)
- **Language:** TypeScript
- **Styling:** Tailwind CSS
- **UI Components:** shadcn/ui
- **Tables:** TanStack Table (React Table)
- **Auth:** Supabase SSR (server-side sessions)
- **Charts:** Recharts or Tremor
- **Forms:** React Hook Form + Zod
- **Payments:** Stripe.js

## Project Structure

```
admin-web/
├── src/
│   ├── app/                          # Next.js App Router
│   │   ├── (auth)/                   # Auth group (no sidebar)
│   │   │   ├── login/
│   │   │   │   └── page.tsx
│   │   │   └── layout.tsx
│   │   ├── (dashboard)/              # Dashboard group (with sidebar)
│   │   │   ├── layout.tsx            # Sidebar + auth guard
│   │   │   ├── page.tsx              # Dashboard overview
│   │   │   ├── members/
│   │   │   │   ├── page.tsx          # Member list table
│   │   │   │   └── import/
│   │   │   │       └── page.tsx      # CSV bulk upload
│   │   │   ├── workouts/
│   │   │   │   ├── page.tsx          # Template library
│   │   │   │   └── create/
│   │   │   │       └── page.tsx      # Build new template
│   │   │   ├── feed/
│   │   │   │   └── page.tsx          # Moderate posts, send notices
│   │   │   ├── schedule/
│   │   │   │   └── page.tsx          # Class schedules
│   │   │   └── settings/
│   │   │       ├── branding/
│   │   │       │   └── page.tsx      # Logo, colors, info
│   │   │       └── billing/
│   │   │           └── page.tsx      # Stripe checkout, invoices
│   │   └── api/
│   │       └── webhooks/
│   │           └── stripe/
│   │               └── route.ts      # Stripe webhook handler
│   ├── components/
│   │   ├── ui/                       # shadcn/ui components
│   │   ├── data-table.tsx            # Reusable table wrapper
│   │   ├── member-import-dialog.tsx  # CSV upload modal
│   │   ├── stats-card.tsx            # Dashboard stat cards
│   │   └── gym-switcher.tsx          # Multi-gym staff switcher
│   ├── lib/
│   │   ├── supabase/
│   │   │   ├── client.ts             # Browser Supabase client
│   │   │   ├── server.ts             # Server-side client
│   │   │   └── middleware.ts         # Auth + gym context
│   │   └── utils.ts                  # cn(), formatters
│   └── types/
│       └── database.ts               # Generated Supabase types
├── components.json                   # shadcn/ui config
├── tailwind.config.ts
└── next.config.js
```

## Auth Flow

### Staff Login (Email + Password)

Unlike members who use OTP, staff log in with email and password:

```
Staff opens admin.yourapp.com
    │
    ▼
Enters email + password
    │
    ▼
Supabase Auth validates credentials
    │
    ▼
Middleware checks gym_staff table
    │
    ▼
If valid: attach gym_id to request, render dashboard
    │
    ▼
If invalid: redirect to /login
```

### Middleware Implementation

```typescript
// src/lib/supabase/middleware.ts
import { createServerClient } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'

export async function updateSession(request: NextRequest) {
  let response = NextResponse.next({ request: { headers: request.headers } })

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        get(name) { return request.cookies.get(name)?.value },
        set(name, value, options) {
          request.cookies.set({ name, value, ...options })
          response = NextResponse.next({ request: { headers: request.headers } })
          response.cookies.set({ name, value, ...options })
        },
        remove(name, options) {
          request.cookies.set({ name, value: '', ...options })
          response = NextResponse.next({ request: { headers: request.headers } })
          response.cookies.set({ name, value: '', ...options })
        },
      },
    }
  )

  const { data: { user } } = await supabase.auth.getUser()

  // Public routes
  if (request.nextUrl.pathname.startsWith('/login')) {
    return response
  }

  // No session → login
  if (!user) {
    return NextResponse.redirect(new URL('/login', request.url))
  }

  // Verify staff membership
  const { data: staff } = await supabase
    .from('gym_staff')
    .select('gym_id, role, gyms(*)')
    .eq('auth_user_id', user.id)
    .single()

  if (!staff) {
    await supabase.auth.signOut()
    return NextResponse.redirect(new URL('/login?error=unauthorized', request.url))
  }

  // Attach gym context
  response.headers.set('x-gym-id', staff.gym_id)
  response.headers.set('x-staff-role', staff.role)

  return response
}
```

### Server Component: Access Gym Data

```typescript
// src/app/(dashboard)/page.tsx
import { createClient } from '@/lib/supabase/server'

export default async function DashboardPage() {
  const supabase = createClient()

  // Get current staff's gym
  const { data: staff } = await supabase
    .from('gym_staff')
    .select('gym_id')
    .single()

  const gymId = staff?.gym_id

  // Fetch stats (RLS ensures only this gym's data)
  const { count: totalMembers } = await supabase
    .from('gym_members')
    .select('*', { count: 'exact', head: true })
    .eq('gym_id', gymId)

  const { count: activeToday } = await supabase
    .from('workout_sessions')
    .select('*', { count: 'exact', head: true })
    .eq('gym_id', gymId)
    .gte('started_at', new Date().toISOString().split('T')[0])

  return (
    <div className="grid gap-4 md:grid-cols-3">
      <StatsCard title="Total Members" value={totalMembers ?? 0} />
      <StatsCard title="Active Today" value={activeToday ?? 0} />
      <StatsCard title="PRs This Week" value={/* ... */} />
    </div>
  )
}
```

## Key Pages

### Members Page

Features:
- Search/filter members
- Activate/deactivate members
- View member activity
- **Bulk CSV import**

### CSV Import Implementation

```typescript
// components/member-import-dialog.tsx
'use client'
import { useState } from 'react'
import { useSupabase } from '@/lib/supabase/client'
import Papa from 'papaparse'

export function MemberImportDialog() {
  const supabase = useSupabase()
  const [preview, setPreview] = useState<any[]>([])
  const [importing, setImporting] = useState(false)

  const handleFile = (file: File) => {
    Papa.parse(file, {
      header: true,
      skipEmptyLines: true,
      complete: (results) => {
        const valid = results.data.filter((row: any) =>
          row.email || row.phone
        )
        setPreview(valid)
      },
    })
  }

  const handleImport = async () => {
    setImporting(true)
    const { data, error } = await supabase.functions.invoke(
      'admin-import-members',
      {
        body: { members: preview },
      }
    )
    setImporting(false)

    if (error) {
      alert('Import failed: ' + error.message)
    } else {
      alert(`Imported ${data.imported} members!`)
      setPreview([])
    }
  }

  return (
    <div>
      <input
        type="file"
        accept=".csv"
        onChange={(e) => e.target.files?.[0] && handleFile(e.target.files[0])}
      />
      {preview.length > 0 && (
        <>
          <p>{preview.length} members ready to import</p>
          <button onClick={handleImport} disabled={importing}>
            {importing ? 'Importing...' : 'Confirm Import'}
          </button>
        </>
      )}
    </div>
  )
}
```

### Feed Moderation Page

Features:
- View all posts in gym
- Pin/unpin notices
- Delete inappropriate posts
- Create coach tips / announcements

```typescript
// Pin a post (admin only)
const { error } = await supabase
  .from('feed_posts')
  .update({ is_pinned: true })
  .eq('id', postId)
```

### Workout Template Builder

Features:
- Search exercise library
- Add exercises to template
- Set defaults (sets, reps, weight)
- Save as gym template
- Assign to members/groups

### Settings / Branding

Features:
- Upload gym logo
- Set primary color
- Update gym info
- Feature toggles (from `gyms.settings` JSONB)

### Billing Page

Features:
- Current plan display
- Stripe Checkout for upgrades
- Invoice history
- Cancel subscription

```typescript
// Stripe Checkout
const handleSubscribe = async (priceId: string) => {
  const response = await fetch('/api/stripe/checkout', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ priceId }),
  })
  const { sessionId } = await response.json()

  const stripe = await loadStripe(process.env.NEXT_PUBLIC_STRIPE_KEY!)
  await stripe?.redirectToCheckout({ sessionId })
}
```

## Stripe Webhook

```typescript
// src/app/api/webhooks/stripe/route.ts
import Stripe from 'stripe'
import { createClient } from '@/lib/supabase/server'

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: '2024-06-20',
})

const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET!

export async function POST(req: Request) {
  const payload = await req.text()
  const signature = req.headers.get('stripe-signature')!

  let event: Stripe.Event
  try {
    event = stripe.webhooks.constructEvent(payload, signature, webhookSecret)
  } catch (err: any) {
    return new Response(`Webhook Error: ${err.message}`, { status: 400 })
  }

  const supabase = createClient()

  switch (event.type) {
    case 'invoice.payment_succeeded': {
      const subscription = event.data.object as Stripe.Invoice
      await supabase
        .from('gyms')
        .update({
          subscription_status: 'active',
          subscription_expires_at: new Date(
            (subscription.period_end || 0) * 1000
          ).toISOString(),
        })
        .eq('stripe_customer_id', subscription.customer as string)
      break
    }

    case 'invoice.payment_failed': {
      const invoice = event.data.object as Stripe.Invoice
      await supabase
        .from('gyms')
        .update({ subscription_status: 'past_due' })
        .eq('stripe_customer_id', invoice.customer as string)
      break
    }

    case 'customer.subscription.deleted': {
      const subscription = event.data.object as Stripe.Subscription
      await supabase
        .from('gyms')
        .update({ subscription_status: 'cancelled' })
        .eq('stripe_subscription_id', subscription.id)
      break
    }
  }

  return new Response('OK', { status: 200 })
}
```

## Environment Variables

Create `.env.local`:
```
NEXT_PUBLIC_SUPABASE_URL=https://yourproject.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
```

## Running Locally

```bash
cd admin-web/
npm install
npm run dev
```

Open http://localhost:3000

## Deployment

### Vercel (Recommended)
1. Push to GitHub
2. Import repo in Vercel
3. Add environment variables
4. Deploy

### Custom Domain
Set up `admin.yourdomain.com` in Vercel project settings.
