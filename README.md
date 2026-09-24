# Gym-Companion (Tether)

Multi-tenant gym companion: Flutter member app, NestJS API and a Next.js staff portal.

## Layout

| Path | Role |
|------|------|
| `Tether/` | Flutter mobile app |
| `gym-app-backend/` | NestJS + Prisma API |
| `tether-web/` | Next.js staff portal + marketing pages |
| `docs/` | Living monorepo docs |
| `docs/archive/` | Superseded plans, product notes and design guides |

## Start here

1. [`docs/CODEBASE_OVERVIEW.md`](docs/CODEBASE_OVERVIEW.md) — what exists today  
2. [`docs/EXECUTION_PLAN.md`](docs/EXECUTION_PLAN.md) — **what to build next (ticketed)**  
3. [`docs/WEBSITE_PLAN.md`](docs/WEBSITE_PLAN.md) — admin + marketing plan  
4. [`docs/OPS_RUNBOOK.md`](docs/OPS_RUNBOOK.md) — local ports, env packaging, pilot ops  
5. [`docs/CLOUD_RUN_DEPLOY.md`](docs/CLOUD_RUN_DEPLOY.md) — Google Cloud Run deploy (API + portal)  

## Local development

| Service | Command | Port |
|---------|---------|------|
| API | `cd gym-app-backend && PORT=3001 npm run start:dev` | 3001 |
| Portal | `cd tether-web && NEXT_PUBLIC_API_URL=http://localhost:3001 npm run dev` | 3000 |
| App | `cd Tether && flutter run --dart-define=API_BASE_URL=http://YOUR_LAN_IP:3001` | — |

**Architecture:** clients → NestJS → PostgreSQL (Supabase Auth/Storage).
