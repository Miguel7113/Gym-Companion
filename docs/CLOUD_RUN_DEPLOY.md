# Cloud Run deployment — Tether

Deploy **two** Cloud Run services (same GCP project):

1. `tether-api` — NestJS (`gym-app-backend/`)
2. `tether-web` — staff portal (`tether-web/`)

Database / Auth / Storage stay on **Supabase**. Flutter points at the API URL after deploy.

---

## Local production test (before touching GCP)

Runs both images exactly as Cloud Run will, against the real Supabase project:

```bash
cd gym-app-backend && docker build -t tether-api:local .
set -a && . ./.env && set +a
docker run -d --name tether-api-test -p 8081:8080 -e NODE_ENV=production \
  -e CORS_ORIGIN=http://localhost:8090 -e DATABASE_URL -e SUPABASE_URL \
  -e SUPABASE_SERVICE_ROLE_KEY -e SUPABASE_JWT_SECRET tether-api:local
curl localhost:8081/health/ready

cd ../tether-web
docker build --build-arg NEXT_PUBLIC_API_URL=http://localhost:8081 -t tether-web:local .
docker run -d --name tether-web-test --network host -e PORT=8090 tether-web:local
# open http://localhost:8090/login
```

`--network host` lets the portal's server reach the API on `localhost:8081`.

---

## Local production test (before touching GCP)

Runs both images exactly as Cloud Run will, against the real Supabase project:

```bash
cd gym-app-backend && docker build -t tether-api:local .
set -a && . ./.env && set +a
docker run -d --name tether-api-test -p 8081:8080 -e NODE_ENV=production \
  -e CORS_ORIGIN=http://localhost:8090 -e DATABASE_URL -e SUPABASE_URL \
  -e SUPABASE_SERVICE_ROLE_KEY -e SUPABASE_JWT_SECRET tether-api:local
curl localhost:8081/health/ready

cd ../tether-web
docker build --build-arg NEXT_PUBLIC_API_URL=http://localhost:8081 -t tether-web:local .
docker run -d --name tether-web-test --network host -e PORT=8090 tether-web:local
# open http://localhost:8090/login
```

`--network host` lets the portal's server reach the API on `localhost:8081`.

---

## 0. Prerequisites

Install and sign in:

```bash
# https://cloud.google.com/sdk/docs/install
gcloud auth login
gcloud config set project YOUR_GCP_PROJECT_ID
```

Enable APIs:

```bash
gcloud services enable \
  run.googleapis.com \
  artifactregistry.googleapis.com \
  cloudbuild.googleapis.com \
  secretmanager.googleapis.com
```

Create an Artifact Registry repo (once):

```bash
gcloud artifacts repositories create tether \
  --repository-format=docker \
  --location=europe-west1 \
  --description="Tether images"
```

Set helpers (adjust region if you prefer):

```bash
export PROJECT_ID=$(gcloud config get-value project)
export REGION=europe-west1
export REPO=europe-west1-docker.pkg.dev/$PROJECT_ID/tether
```

Docker auth for Artifact Registry:

```bash
gcloud auth configure-docker europe-west1-docker.pkg.dev
```

---

## 1. Secrets (API)

Store Nest secrets in Secret Manager (do **not** put these in the image):

```bash
# Paste each value when prompted (or use --data-file=...)
echo -n 'YOUR_DATABASE_URL' | gcloud secrets create DATABASE_URL --data-file=-
echo -n 'https://YOUR_PROJECT.supabase.co' | gcloud secrets create SUPABASE_URL --data-file=-
echo -n 'YOUR_SERVICE_ROLE_KEY' | gcloud secrets create SUPABASE_SERVICE_ROLE_KEY --data-file=-
echo -n 'YOUR_JWT_SECRET' | gcloud secrets create SUPABASE_JWT_SECRET --data-file=-
```

**DATABASE_URL tip:** prefer Supabase **connection pooler** (port `6543`, `?pgbouncer=true`) for Cloud Run. Direct `5432` can exhaust connections under scale-to-zero.

If a secret already exists, add a new version:

```bash
echo -n 'new-value' | gcloud secrets versions add DATABASE_URL --data-file=-
```

Grant the Cloud Run runtime service account access (default compute SA is fine for pilot):

```bash
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
export RUNTIME_SA="$PROJECT_NUMBER-compute@developer.gserviceaccount.com"

for S in DATABASE_URL SUPABASE_URL SUPABASE_SERVICE_ROLE_KEY SUPABASE_JWT_SECRET; do
  gcloud secrets add-iam-policy-binding $S \
    --member="serviceAccount:$RUNTIME_SA" \
    --role="roles/secretmanager.secretAccessor"
done
```

---

## 2. Deploy the API (`tether-api`)

Build and push:

```bash
cd gym-app-backend

gcloud builds submit --tag $REPO/tether-api:latest .
```

First deploy (CORS can be tightened after the portal URL exists):

```bash
gcloud run deploy tether-api \
  --image=$REPO/tether-api:latest \
  --region=$REGION \
  --platform=managed \
  --allow-unauthenticated \
  --port=8080 \
  --memory=512Mi \
  --cpu=1 \
  --min-instances=0 \
  --max-instances=5 \
  --set-secrets=DATABASE_URL=DATABASE_URL:latest,SUPABASE_URL=SUPABASE_URL:latest,SUPABASE_SERVICE_ROLE_KEY=SUPABASE_SERVICE_ROLE_KEY:latest,SUPABASE_JWT_SECRET=SUPABASE_JWT_SECRET:latest \
  --set-env-vars=NODE_ENV=production,CORS_ORIGIN=*
```

Save the URL:

```bash
export API_URL=$(gcloud run services describe tether-api --region=$REGION --format='value(status.url)')
echo $API_URL
# e.g. https://tether-api-xxxxx-ew.a.run.app
```

Smoke:

```bash
curl -sS "$API_URL/health"        # {"status":"ok"}
curl -sS "$API_URL/health/ready"  # {"status":"ok","database":"up"}
```

The API refuses to start in production if `DATABASE_URL`, `SUPABASE_URL`,
`SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_JWT_SECRET` or `CORS_ORIGIN` is missing —
check the Cloud Run logs for `Missing required environment variables` if the
revision fails to become ready. Point the Cloud Run startup probe at `/health`.

Apply DB migrations against Supabase **before** relying on the API (from a trusted machine):

```bash
cd gym-app-backend
# Use the same DATABASE_URL as production (or migrate via Supabase SQL)
npm run prisma:deploy
```

---

## 3. Deploy the portal (`tether-web`)

`NEXT_PUBLIC_API_URL` is **build-time**. Rebuild the portal whenever the API URL changes.

```bash
cd tether-web

gcloud builds submit \
  --config=- <<EOF
steps:
  - name: gcr.io/cloud-builders/docker
    args:
      - build
      - --build-arg=NEXT_PUBLIC_API_URL=$API_URL
      - -t
      - $REPO/tether-web:latest
      - .
images:
  - $REPO/tether-web:latest
EOF
```

Or with a one-liner docker build locally then push:

```bash
docker build \
  --build-arg NEXT_PUBLIC_API_URL=$API_URL \
  -t $REPO/tether-web:latest .
docker push $REPO/tether-web:latest
```

Deploy:

```bash
gcloud run deploy tether-web \
  --image=$REPO/tether-web:latest \
  --region=$REGION \
  --platform=managed \
  --allow-unauthenticated \
  --port=8080 \
  --memory=512Mi \
  --cpu=1 \
  --min-instances=0 \
  --max-instances=3 \
  --set-env-vars=NODE_ENV=production,COOKIE_SECURE=true
```

Save portal URL:

```bash
export WEB_URL=$(gcloud run services describe tether-web --region=$REGION --format='value(status.url)')
echo $WEB_URL
```

### Lock CORS to the portal

```bash
gcloud run services update tether-api \
  --region=$REGION \
  --update-env-vars=CORS_ORIGIN=$WEB_URL
```

---

## 4. First login smoke

1. Open `$WEB_URL/login`
2. Sign in with an existing `gym_staff` account
3. Check Overview / Members / Roster
4. From Flutter release or a LAN build, point at the API:

```bash
cd Tether
flutter run --dart-define=API_BASE_URL=$API_URL
```

### Android release build

Release builds refuse to start without `API_BASE_URL`, and need the upload
keystore to be accepted by the Play Store. Create the keystore **once** and
back it up (losing it means you can't ship updates under the same listing):

```bash
keytool -genkey -v -keystore ~/tether-upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Create `Tether/android/key.properties` (gitignored):

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=/home/YOU/tether-upload-keystore.jks
```

Build:

```bash
cd Tether
flutter build appbundle --release --dart-define=API_BASE_URL=$API_URL   # Play Store
flutter build apk --release --dart-define=API_BASE_URL=$API_URL         # side-load to a phone
```

Without `key.properties`, release builds fall back to debug signing — fine for
side-loading, rejected by the Play Store.

---

## 5. Recommended Cloud Run settings (pilot)

| Setting | Suggestion |
|---------|------------|
| Auth | `--allow-unauthenticated` on both (portal is public login; API validates JWTs) |
| Min instances | `0` to save cost; set API `min-instances=1` if cold starts hurt OTP/login |
| Memory | `512Mi` start; raise API to `1Gi` if Prisma + uploads feel tight |
| Region | Same as you prefer for latency; keep API + web in **one** region |
| Custom domain | Optional: map `api.yourdomain.com` / `admin.yourdomain.com` in Cloud Run + DNS |

---

## 6. Common failures

| Symptom | Fix |
|---------|-----|
| Portal login network error | Rebuild web with correct `NEXT_PUBLIC_API_URL`; confirm API URL in browser Network tab |
| API crash on boot | Check Cloud Run logs; secret values / `DATABASE_URL` pooler |
| Prisma connection errors | Use Supabase pooler URL; confirm IP allowlist / Supabase network |
| Cookies not sticking | Ensure `COOKIE_SECURE=true` and HTTPS Cloud Run URL |
| CORS errors | Set `CORS_ORIGIN` to exact `$WEB_URL` (no trailing slash mismatch) |
| Tailwind / Next build fails in CI | Image must use **Node 20+** (Dockerfiles use 22) |

View logs:

```bash
gcloud run services logs read tether-api --region=$REGION --limit=50
gcloud run services logs read tether-web --region=$REGION --limit=50
```

---

## 7. Cost / ops notes

- Scale-to-zero is fine for a private pilot.
- Cold start: first request after idle may take a few seconds.
- Secrets rotation: add a new secret version, then redeploy (or update service to pick `:latest`).
- Do not commit `.env` or service-role keys.

---

## Checklist

- [ ] Artifact Registry repo created
- [ ] Secrets created + SA accessor role
- [ ] `tether-api` deployed; `$API_URL` works
- [ ] Prisma migrations applied on production DB
- [ ] `tether-web` built **with** `$API_URL` and deployed
- [ ] `CORS_ORIGIN` set to `$WEB_URL`
- [ ] Staff login smoke passed
- [ ] Flutter `API_BASE_URL` pointed at `$API_URL`
