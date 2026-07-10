# Sahali (سهلي)

A civic reporting platform for Tunisia. Citizens report public infrastructure issues — potholes, broken streetlights, waste overflow, water leaks — directly to their municipality through a mobile app, and municipal staff triage, assign, and resolve them through a web dashboard.

The name means "easy" / "made simple" in Tunisian Arabic — the goal is to make reporting a civic problem as easy as taking a photo.

---

## Part 1 — Business overview

### The problem

Citizens today report infrastructure problems (if at all) through phone calls, in-person visits to municipal offices, or informal social media posts — none of which are tracked, routed to the right department, or followed up on. Municipalities have no structured, geolocated view of what's broken across their territory, no SLA accountability, and no way to measure resolution performance. Sahali replaces that with a single structured pipeline: **report → route → assign → resolve → close the loop with the citizen**.

### Who uses it

| User type | How they use Sahali |
|---|---|
| **Citizens** | Submit a report from the mobile app in under a minute — pick a category, take a photo, drop a pin on the map, add a description. Track its status and get notified as it progresses. Can also report anonymously or as a registered account. |
| **Field agents** | Municipal staff assigned to reports; work through their assigned queue, update status, and file a resolution report (what was done, materials used) when a job is finished. |
| **Analysts** | Municipal staff who review incoming reports, verify/reclassify them, and monitor statistics without administrative rights. |
| **Supervisors** | Assign reports to one or more field agents, manage teams, oversee SLA compliance for their municipality. |
| **Admins** | Full platform control — municipalities, staff accounts, category/SLA configuration, cross-municipality visibility. |

### Core journeys

1. **Citizen reports an issue** — open the app, pick a category (7 top-level categories, each with sub-categories — see below), attach a photo, confirm the location on a map, optionally describe it, submit. The report gets a short tracking code (e.g. `CA1A2B3C`) so it can be checked without an account.
2. **Auto-routing** — the report's GPS point is reverse-geocoded (city + street, in French and Arabic) and matched to the **nearest municipality** by distance, so it lands in front of the right municipal team without anyone manually sorting it.
3. **Triage & assignment** — municipal staff see it appear on their dashboard (list + live map), can reassign its category, and assign it to one or more field agents.
4. **Resolution** — the field agent updates status (`received` → `under_review` → `in_progress` → `resolved`, or `rejected` with a reason at any point) and files a resolution report on completion.
5. **Citizen feedback loop** — the citizen gets a push/SMS/email notification on every status change and can see the full history on their own report.

### Category taxonomy & SLA targets

Each category carries a default SLA (target resolution time), used to flag overdue reports:

| Category | Target resolution |
|---|---|
| Safety & Security | 24 hours |
| Public Lighting (streetlights: 72h, exposed wiring: 24h) | 24–72 hours |
| Water & Sanitation | 48 hours |
| Infrastructure (potholes, sidewalks, signage) | 7 days |
| Cleanliness & Waste Management | 7 days |
| Transportation (bus stops, traffic signals) | 7 days |
| Environment (pollution, illegal tree cutting) | 14 days |

SLA hours are configurable per category from the dashboard (Settings → SLA thresholds), not hardcoded.

### Multi-municipality model

Municipalities are first-class tenants: each has a `subscription_tier` (none/basic/standard/pro/premium) and its own staff accounts, and reports auto-route to whichever municipality is geographically closest. **Current limitation**: staff visibility isn't yet scoped by municipality — every staff account currently sees every report platform-wide (effectively "super-admin" for everyone). Restricting non-admin staff to their own municipality's reports is planned but not yet built (see Roadmap).

### Trilingual by design

The mobile app is French / Arabic / English, with full RTL support for Arabic. The dashboard (used by Tunisian municipal staff) is French / Arabic only. Geocoded addresses are stored and displayed in both French and Arabic independently, since OpenStreetMap data for the same point is often only tagged in one language.

### Target KPIs (design goals, not yet instrumented)

| Indicator | Target |
|---|---|
| Initial response time | < 24 hours |
| Average resolution time | < 7 days |
| Resolution rate | ≥ 90% |
| Duplicate report detection accuracy | ≥ 80% |
| AI classification accuracy | ≥ 85% |

---

## Part 2 — Technical overview

### Project structure

```
sahali/
├── mobile/      # Flutter app (iOS & Android) — trilingual FR / AR / EN
├── backend/     # FastAPI REST API — Python 3.12, PostgreSQL + PostGIS, Redis
└── dashboard/   # React + TypeScript admin dashboard — French / Arabic
```

### Architecture

```
┌─────────────────────────┐     ┌──────────────────────────────┐
│   Mobile app (Flutter)  │     │  Admin dashboard (React/TS)  │
│   citizens, FR/AR/EN     │     │  municipal staff, FR/AR       │
└────────────┬─────────────┘     └───────────────┬──────────────┘
             │ REST (JWT Bearer)                 │ REST + SSE (JWT Bearer)
             └────────────────┬───────────────────┘
                              ▼
                  ┌───────────────────────┐
                  │   FastAPI backend     │
                  │   (Python 3.12)       │
                  └───┬───────┬───────┬───┘
                      │       │       │
        ┌─────────────┘       │       └─────────────────┐
        ▼                     ▼                         ▼
┌───────────────┐   ┌──────────────────┐      ┌───────────────────┐
│ PostgreSQL 15 │   │  Redis           │      │ Supabase Storage /│
│ + PostGIS     │   │  OTP codes,      │      │ MinIO (S3-compat) │
│ (Supabase in  │   │  pub/sub for     │      │ report photos     │
│  prod)        │   │  live SSE events │      └───────────────────┘
└───────────────┘   └──────────────────┘
                              │
              ┌───────────────┼───────────────┬──────────────────┐
              ▼               ▼               ▼                  ▼
        Firebase FCM       Twilio          SendGrid      OpenStreetMap
        (push)             (SMS OTP)       (email)       Nominatim
                                                          (reverse/forward
                                                           geocoding, FR+AR)
```

- Mobile and dashboard both talk to the **same** FastAPI backend over plain REST, authenticated with a JWT bearer token.
- The dashboard additionally holds a **Server-Sent-Events** connection (`GET /v1/events/reports`) for live report updates, backed by Redis pub/sub — no polling.
- There is no message queue/worker in production despite `celery` being a listed dependency — background work (notifications, AI analysis call, geocoding, municipality routing) runs as FastAPI `BackgroundTasks` in-process, not a separate Celery worker.

### Tech stack

| Layer | Technology |
|---|---|
| **Mobile** | Flutter (SDK ^3.11.5), Dart, GoRouter (navigation), Provider (state/MVVM), Dio (HTTP), flutter_secure_storage + sqflite (offline/session storage), flutter_map + latlong2 (OpenStreetMap, no Maps API key), geolocator, image_picker, flutter_local_notifications, google_fonts, flutter_animate |
| **Backend** | FastAPI 0.111, Uvicorn, SQLAlchemy 2.0, Alembic (11 migrations), Pydantic v2 + pydantic-settings, PostgreSQL 15 + PostGIS (GeoAlchemy2/Shapely), Redis, python-jose (RS256 JWT), passlib/bcrypt, httpx, slowapi (rate limiting), structlog, Sentry SDK |
| **Dashboard** | React 19, TypeScript, Vite, react-router-dom v7, Tailwind CSS v4, Recharts (charts), Leaflet (map) |
| **External services** | Firebase Cloud Messaging (push), Twilio (SMS OTP), SendGrid (email), Supabase Storage REST (production file storage) / MinIO (local dev), OpenStreetMap Nominatim (free reverse/forward geocoding, no API key) |
| **Infra** | Docker Compose for local dev (PostGIS, Redis, MinIO); Vercel (dashboard hosting); Render (backend hosting); Supabase (production Postgres + Storage) |

### Data model

| Table | Purpose |
|---|---|
| `users` | Citizens and staff. `role` enum: `citizen`, `field_agent`, `analyst`, `supervisor`, `admin`. Staff carry a `municipality_id`. |
| `municipalities` | Tenants. `subscription_tier`, a `boundary` polygon (unused so far) and a `location` centroid point (used for nearest-municipality routing). |
| `departments` | Sub-units of a municipality that categories route to. |
| `categories` | Self-referential tree (root + sub-categories), trilingual labels, `sla_hours`, `is_active`. |
| `reports` | The core entity: tracking code, citizen, category, PostGIS `location` point, geocoded `address`/`city` (+ `_ar` variants), `municipality_id` (nearest-match), status, priority, AI classification fields, photos (JSONB array). |
| `report_status_history` | Full audit trail of every status transition. |
| `assignments` | Many-to-many report↔agent assignment (supports multiple agents per report). |
| `resolution_reports` | Field agent's closing report (comment, materials used, photo) — one per resolved report. |
| `notifications` | In-app notification feed for both citizens and staff. |

### Key subsystems

- **Auth**: RS256-signed JWT (asymmetric key pair, not HMAC), access token (60 min) + refresh token (30 days). Login by phone+OTP or email+password. Passwords hashed with bcrypt.
- **Geocoding** (`app/services/geocoding.py`): reverse-geocodes report coordinates via OpenStreetMap Nominatim in both French and Arabic (two sequential requests, rate-limited to Nominatim's 1 req/sec policy). Only a genuinely named road is shown as a street address — OSM's neighbourhood/suburb polygons for Tunisia are often inaccurate, so a missing street is left blank rather than guessed.
- **Municipality routing** (`app/services/municipality_matching.py`): a PostGIS K-nearest-neighbour query (`<->` operator) finds the closest municipality centroid to a report's coordinates, run synchronously at submission time (no network call, pure DB).
- **Notifications**: push (FCM), SMS (Twilio), email (SendGrid) — dispatched as background tasks with retry-with-backoff (`app/utils/retry.py`), never blocking the API response.
- **Live updates**: an SSE endpoint (`/v1/events/reports`) streams report lifecycle events to connected dashboard clients via Redis pub/sub, restricted to staff roles.
- **Storage**: production uses Supabase's Storage REST API for report photos; local dev uses a MinIO container (S3-compatible), selected via `STORAGE_BACKEND`.
- **One-off data-repair jobs** (`app/services/backfill.py`): geocode municipality coordinates, backfill missing report addresses/municipality links. Exposed both as standalone scripts (`backend/scripts/`) and as admin-only HTTP endpoints (`POST /v1/admin/backfill/*`), the latter for hosting plans without shell access.

### API surface (all under `/v1`)

| Router | Handles |
|---|---|
| `auth` | Register, login, phone/email OTP, forgot/reset password, token refresh |
| `users` | Own profile (`/me`), change password |
| `reports` | Submit (auth'd or anonymous), list/filter/paginate, nearby search, public tracking-code lookup, status transitions, multi-agent assignment, resolution reports, status history |
| `categories` | List active categories (public), full list + toggle/edit (staff) |
| `notifications` | List own notifications, mark as read |
| `admin` | Stats, CSV export, staff CRUD, municipality CRUD, broadcast notifications, backfill triggers |
| `events` | SSE stream of live report events (staff only) |

### Deployment

| Component | Host | Notes |
|---|---|---|
| Dashboard | **Vercel** | Static SPA build (`vercel.json` is just an SPA rewrite rule); backend CORS explicitly allows `*.vercel.app` |
| Backend | **Render** | Docker deploy (`backend/Dockerfile` runs `alembic upgrade head` then `uvicorn`); JWT keys passed as base64 env vars, not files, in production |
| Database + Storage | **Supabase** | Managed Postgres (with PostGIS) + Storage REST API |
| Local dev | **Docker Compose** | `backend/docker-compose.yml` spins up Postgres+PostGIS, Redis, and MinIO (+ a one-shot bucket-creation job) |

There is no `render.yaml`/IaC — the Render service is configured through Render's dashboard directly. There's currently no CI/CD pipeline (no GitHub Actions).

### Known gaps / roadmap

- **AI microservice**: referenced throughout the code (`AI_SERVICE_URL`, `ai_category_id`/`ai_confidence`/`is_duplicate` fields, a `Makefile` target) for automatic classification, duplicate detection, and priority scoring — **not implemented yet**, no `ai/` directory exists.
- **Municipality-scoped staff visibility**: `reports.municipality_id` now auto-populates (nearest-match), but staff roles other than admin still see every report platform-wide rather than only their own municipality's. This is the next planned change.
- **No automated tests**: `pyproject.toml` declares `pytest`/`pytest-asyncio`/`pytest-cov` and a `testpaths = ["tests"]` config, but no `backend/tests/` directory exists yet.
- **No CI/CD**: no GitHub Actions or other pipeline configured.

### Security notes

- JWT uses RS256 (asymmetric), so only the backend holding the private key can mint tokens; the public key alone (used for verification) is safe to distribute.
- ⚠️ **Action needed**: the RS256 **private** key (`private.pem`, repo root) is currently tracked in git history. Treat it as compromised — rotate the key pair, update Render's `JWT_PRIVATE_KEY_B64` env var, and remove the file from tracking. This invalidates all existing sessions (expected).
- Rate limiting via `slowapi` on sensitive endpoints; input sanitization via `bleach`.
- Report photo uploads go through the backend (presigned URL / proxy pattern), not directly exposing storage credentials to clients.

---

## Part 3 — Local development

### Prerequisites

- [uv](https://github.com/astral-sh/uv) — Python package manager
- [Docker](https://www.docker.com/) — for PostgreSQL, Redis, MinIO
- [Flutter](https://docs.flutter.dev/get-started/install) SDK
- `make` — Windows: `scoop install make` or `choco install make`

### First-time setup

```bash
make setup
```

This generates the RS256 JWT key pair, installs backend dependencies, starts Docker containers, and runs all Alembic migrations.

### Start the development environment

```bash
make dev
```

| Service | URL |
|---|---|
| Backend API | http://localhost:8000 |
| Swagger UI | http://localhost:8000/docs |
| MinIO console | http://localhost:9001 |

### Run the mobile app

```bash
make mobile-install
make mobile-dev
```

### Run the dashboard

```bash
cd dashboard
npm install
npm run dev
```

---

## Common commands

```bash
make help                          # List all available commands

# Backend
make backend-dev                   # Start API with hot-reload
make backend-test                  # Run test suite
make backend-lint                  # Lint with ruff
make migrate                       # Apply pending DB migrations
make migration name="add_column"   # Create a new migration

# Database
make db-reset                      # Drop and recreate DB (destroys data)
make shell-db                      # Open a psql shell

# Docker
make docker-up                     # Start infrastructure containers
make docker-down                   # Stop containers
make docker-clean                  # Stop + delete volumes (destroys data)

# Mobile
make mobile-build-apk               # Build Android APK (release)
make mobile-build-ios               # Build iOS — requires macOS
```

---

## Environment

Copy the example file and fill in the required values:

```bash
cp backend/.env.example backend/.env
```

`make setup` does this automatically on first run.

> `backend/private.pem` and `backend/.env` are git-ignored and must never be committed. (Note: the root-level `private.pem` currently *is* tracked — see Security notes above.)
