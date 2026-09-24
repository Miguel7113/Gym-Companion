# Tether Ops Runbook

Short guide for running and handing off a private pilot.

## Local ports

| Service | Default URL | Notes |
|---------|-------------|--------|
| Staff portal (`tether-web`) | http://localhost:3000 | Node **20+** (Tailwind v4). `npm run dev` or `npm run build && npm start` |
| Nest API (`gym-app-backend`) | http://localhost:3001 | `PORT=3001 npm run start` |
| Flutter app | LAN API | Physical device needs `--dart-define=API_BASE_URL=...` |

`npm run start port 3001` does **not** set the port. Use `PORT=3001` (backend) or `next start -p 3001` (portal).

## Start order

1. Backend

```bash
cd gym-app-backend
# Node 22+ recommended (Supabase client)
PORT=3001 npm run start
```

2. Portal

```bash
cd tether-web
# Day-to-day:
npm run dev
# Or production build:
npm run build && npm start
```

3. Flutter (physical phone)

```bash
cd Tether
flutter run --dart-define=API_BASE_URL=http://YOUR_LAN_IP:3001
```

Use the same Wi‑Fi. Emulator can keep `http://10.0.2.2:3001`.

## Required env

### Backend (`gym-app-backend/.env`)

- `DATABASE_URL`
- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `SUPABASE_JWT_SECRET`
- `PORT` (local with portal: `3001`)
- `CORS_ORIGIN` (production: your portal origin)

### Portal (`tether-web/.env.local`)

- `NEXT_PUBLIC_API_URL` → Nest base URL
- `COOKIE_SECURE=true` on HTTPS production

### Flutter

- Compile-time `API_BASE_URL` for non-emulator devices

## First gym checklist

1. Apply Prisma / Supabase migrations
2. Ensure one `gyms` row exists
3. Ensure one `gym_staff` admin can log in at `/login`
4. Ensure at least one member belongs to that gym
5. Smoke: roster → notices → member share → feed moderation

## Common failures

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Portal login fails / network errors | Wrong `NEXT_PUBLIC_API_URL` or API down | Confirm API on 3001; rebuild portal after env change |
| `EADDRINUSE :3000` | Portal already using 3000 | Run API with `PORT=3001` |
| Flutter feed timeouts / share fails | Phone hitting `10.0.2.2` or wrong LAN IP | Pass `API_BASE_URL=http://LAN_IP:3001` |
| Feed / profile empty on phone | Backend not bound / firewall | API listens on `0.0.0.0`; allow LAN |
| Staff cookie issues on HTTPS | Missing Secure flag | Set `NODE_ENV=production` or `COOKIE_SECURE=true` |
| Nest fails on startup (WebSocket) | Node too old for current Supabase SDK | Use Node 22+ |
| Portal UI changes missing | Running stale `next start` build | `npm run build` again, or use `npm run dev` |

## Production packaging notes

1. Deploy Nest with the same secrets as local Supabase/Postgres
2. Deploy `tether-web` with `NEXT_PUBLIC_API_URL` pointing at the hosted API
3. Set `CORS_ORIGIN` to the portal origin(s)
4. Prefer HTTPS end-to-end; enable Secure cookies
5. Point Flutter release builds at the hosted API URL (not LAN)

**Google Cloud Run (chosen):** step-by-step in [`docs/CLOUD_RUN_DEPLOY.md`](CLOUD_RUN_DEPLOY.md) (Dockerfiles live in `gym-app-backend/` and `tether-web/`).

## Support contacts (fill for your gym)

- Ops owner:
- Supabase project:
- API host:
- Portal host:
