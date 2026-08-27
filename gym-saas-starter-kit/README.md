# Gym SaaS Platform — Starter Kit

A multi-tenant gym management platform built with **Flutter**, **Supabase**, and **Next.js**.

## Architecture Overview

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Flutter App   │────▶│    Supabase     │◄────│  Next.js Admin  │
│  (iOS/Android)  │     │  (Auth/DB/RLS)  │     │     Portal      │
└─────────────────┘     └─────────────────┘     └─────────────────┘
         │                       │                       │
         │              ┌────────┴────────┐              │
         │              │  Edge Functions │              │
         │              │  • OTP Gatekeeper│             │
         │              │  • Verify + Link │             │
         │              │  • Bulk Import   │             │
         │              └─────────────────┘              │
         │                       │                       │
         └───────────────▶ Twilio Verify ◄───────────────┘
```

## Project Structure

```
gym-saas-starter-kit/
├── docs/                          # Documentation
│   ├── ARCHITECTURE.md
│   ├── SETUP_GUIDE.md
│   ├── FLUTTER_GUIDE.md
│   ├── ADMIN_PORTAL_GUIDE.md
│   └── DATABASE_SCHEMA.md
├── supabase/
│   ├── migrations/
│   │   ├── 001_initial_schema.sql
│   │   ├── 002_rls_policies.sql
│   │   └── 003_triggers.sql
│   ├── functions/
│   │   ├── auth-request-otp/
│   │   ├── auth-verify-otp/
│   │   ├── admin-import-members/
│   │   └── push-notify/
│   └── config.toml
└── flutter/
    └── lib/
        ├── main.dart
        ├── core/
        │   ├── constants/
        │   ├── navigation/
        │   └── theme/
        └── features/
            ├── auth/
            │   ├── models/
            │   ├── providers/
            │   ├── services/
            │   └── screens/
            ├── workout/
            ├── feed/
            └── profile/
```

## Quick Start

1. [Read the Setup Guide](docs/SETUP_GUIDE.md)
2. [Review the Database Schema](docs/DATABASE_SCHEMA.md)
3. [Set up the Flutter app](docs/FLUTTER_GUIDE.md)
4. [Build the Admin Portal](docs/ADMIN_PORTAL_GUIDE.md)

## Key Features

| Feature | Status |
|---------|--------|
| Multi-tenant gym isolation (RLS) | ✅ |
| Pre-registered member OTP auth | ✅ |
| Gym selection by name/code | ✅ |
| Workout tracking & PR detection | ✅ |
| Social feed with auto-posts | ✅ |
| Class scheduling & booking | ✅ |
| Admin CSV member import | ✅ |
| Push notifications (placeholder) | ✅ |
| Stripe billing integration | 📝 Guide provided |

## Tech Stack

- **Mobile:** Flutter 3.x, Riverpod, Supabase Flutter
- **Backend:** Supabase (Postgres, Auth, Storage, Edge Functions, Realtime)
- **Admin:** Next.js 14, TypeScript, Tailwind, shadcn/ui
- **Auth:** Supabase Auth + Twilio Verify (SMS OTP)
- **Payments:** Stripe (subscription billing)

## License

Private — for your gym SaaS business.
