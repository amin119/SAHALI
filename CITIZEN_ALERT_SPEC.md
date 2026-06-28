# Citizen Alert — Technical Specification

**Version:** 1.0  
**Date:** June 2026  
**Status:** Draft

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Goals and Success Criteria](#2-goals-and-success-criteria)
3. [System Architecture](#3-system-architecture)
4. [Mobile Application](#4-mobile-application)
5. [Admin Dashboard](#5-admin-dashboard)
6. [Backend API](#6-backend-api)
7. [Database Schema](#7-database-schema)
8. [GIS and Mapping](#8-gis-and-mapping)
9. [Notification System](#9-notification-system)
10. [AI Module](#10-ai-module)
11. [Security and Privacy](#11-security-and-privacy)
12. [Localization](#12-localization)
13. [KPIs and Monitoring](#13-kpis-and-monitoring)
14. [Development Phases](#14-development-phases)
15. [Budget Estimate](#15-budget-estimate)
16. [Appendix — Report Categories](#16-appendix--report-categories)

---

## 1. Project Overview

**Citizen Alert** is a civic technology platform that enables citizens to report public infrastructure issues and track their resolution in real time. The platform consists of:

- A cross-platform mobile application (iOS + Android) for citizens
- A web-based administration dashboard for municipal authorities
- A REST API backend serving both clients
- An AI module for automated classification, deduplication, and prioritization
- A GIS/mapping layer for spatial visualization and analysis

### Target Users

| User Type | Description |
|-----------|-------------|
| Citizens | General public submitting and tracking reports |
| Municipal supervisors | Municipal staff triaging and assigning reports |
| Field teams | On-the-ground crews updating report status |
| Platform administrators | System-level configuration and user management |
| Data analysts | Reporting, KPI monitoring, trend analysis |

---

## 2. Goals and Success Criteria

### Functional Goals

- Citizens can submit a report in under 2 minutes
- Reports are automatically routed to the correct municipal department
- Citizens receive real-time status updates via push/SMS/email
- Authorities have a live dashboard with GIS-based report visualization
- The platform supports Arabic, French, and English

### Key Performance Indicators

| Indicator | Target |
|-----------|--------|
| Initial response time | < 24 hours |
| Average resolution time | < 7 days |
| Resolution rate | ≥ 90% |
| Citizen satisfaction score | ≥ 85% |
| Duplicate report detection accuracy | ≥ 80% |
| AI classification accuracy | ≥ 85% |

---

## 3. System Architecture

### High-Level Components

```
┌─────────────────────────────────────────────────────────┐
│                    Client Layer                         │
│   Mobile App (iOS/Android)   │   Web Admin Dashboard   │
└───────────────┬──────────────┴──────────────┬──────────┘
                │                             │
                ▼                             ▼
┌─────────────────────────────────────────────────────────┐
│                    API Gateway                          │
│         REST API (Node.js / Express or NestJS)         │
└────┬──────────────┬───────────────┬───────────────┬────┘
     │              │               │               │
     ▼              ▼               ▼               ▼
┌─────────┐  ┌──────────┐  ┌──────────────┐  ┌──────────┐
│Postgres │  │ Redis    │  │ File Storage │  │  AI/ML   │
│Database │  │ Cache +  │  │  (S3/Minio)  │  │ Service  │
│+ PostGIS│  │ Queues   │  │  Photos,docs │  │          │
└─────────┘  └──────────┘  └──────────────┘  └──────────┘
                  │
                  ▼
         ┌────────────────┐
         │ Notification   │
         │ Service        │
         │ Push/SMS/Email │
         └────────────────┘
```

### Technology Stack

| Layer | Technology |
|-------|------------|
| Mobile (iOS) | Flutter |
| Mobile (Android) | Flutter |
| Web Admin | React + TypeScript |
| API Backend | FastAPI |
| Database | PostgreSQL 15 + PostGIS |
| Cache / Queue | Redis |
| File Storage | AWS S3 or MinIO (self-hosted) |
| GIS / Maps | Mapbox GL JS + OpenStreetMap |
| AI / ML | Python FastAPI microservice |
| Push Notifications | Firebase Cloud Messaging (FCM) |
| SMS | Twilio or local Tunisian SMS gateway |
| Email | SendGrid or SMTP |
| Hosting | AWS / DigitalOcean / OVHcloud |
| CI/CD | GitHub Actions |
| Monitoring | Sentry (errors) + Grafana (metrics) |

---

## 4. Mobile Application

### Screens

#### Citizen-Facing Screens

| Screen | Description |
|--------|-------------|
| Onboarding | Language selection, brief intro, permissions request (camera, location) |
| Registration / Login | Phone number + OTP or email/password |
| Home | Map view of nearby reports + submit button |
| Submit Report | 6-step wizard (see below) |
| My Reports | List of submitted reports with status badges |
| Report Detail | Full report view, status timeline, comment thread |
| Notifications | In-app notification feed |
| Settings | Language, notification preferences, account |

#### Report Submission Flow (6 Steps)

```
Step 1: Camera / Gallery
        ↓
Step 2: Category selection (tree picker)
        ↓
Step 3: Location confirmation (GPS auto-fill + manual drag)
        ↓
Step 4: Description (optional free text, 500 chars max)
        ↓
Step 5: Review summary
        ↓
Step 6: Confirmation + tracking number issued
```

### Permissions Required

| Permission | Purpose |
|------------|---------|
| Camera | Capture report photo |
| Photo Library | Upload existing photo |
| Location (foreground) | Auto-fill GPS coordinates |
| Push Notifications | Status update alerts |

### Offline Support

- Reports drafted offline are queued locally (SQLite)
- Uploaded automatically when connectivity is restored
- App displays cached map tiles for the user's city

### Platform Requirements

| Platform | Minimum Version |
|----------|----------------|
| iOS | 14.0+ |
| Android | 8.0 (API 26)+ |
| Flutter | latest|

---

## 5. Admin Dashboard

### Modules

#### 1. Overview Dashboard

- Total reports (today / week / month)
- Reports by status (donut chart)
- Average response and resolution times
- Resolution rate trend (line chart)
- Active reports heatmap (GIS)

#### 2. Report Management

- Full-text search and filters (category, status, date, city, ward)
- Bulk assignment to field team
- Status update with internal notes
- Photo viewer
- Citizen communication log

#### 3. GIS Map View

- All open reports plotted on interactive map
- Cluster view at low zoom, individual pins at high zoom
- Filter by category/status/date
- Draw polygon to select reports in an area
- Export visible reports to CSV

#### 4. Team Management

- Add/edit municipal staff accounts
- Assign roles: supervisor, field agent, analyst
- View each agent's active caseload

#### 5. Analytics and Reporting

- Configurable date range reports
- Report volume by category
- Performance ranking by department/municipality
- Export to PDF or Excel
- Scheduled email reports

#### 6. Settings

- Municipality profile (name, logo, service area polygon)
- Department configuration (which categories route to which dept)
- Notification templates (SMS / email body text per status change)
- SLA thresholds (trigger alerts if resolution time exceeded)

### Role Permissions Matrix

| Feature | Admin | Supervisor | Field Agent | Analyst |
|---------|-------|-----------|-------------|---------|
| View reports | ✓ | ✓ | Own only | ✓ |
| Update status | ✓ | ✓ | Own only | — |
| Assign reports | ✓ | ✓ | — | — |
| View analytics | ✓ | ✓ | — | ✓ |
| Export data | ✓ | ✓ | — | ✓ |
| Manage users | ✓ | — | — | — |
| System settings | ✓ | — | — | — |

---

## 6. Backend API

### Base URL Structure

```
https://api.citizenalert.tn/v1/
```

### Authentication

- JWT Bearer tokens (access token: 1h TTL, refresh token: 30d TTL)
- OTP via SMS for citizen registration
- Role-based access control on all endpoints

### Core Endpoints

#### Reports

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/reports` | Submit a new report |
| GET | `/reports` | List reports (paginated, filterable) |
| GET | `/reports/:id` | Get report detail |
| PATCH | `/reports/:id/status` | Update report status |
| POST | `/reports/:id/comments` | Add internal or public comment |
| GET | `/reports/nearby` | Reports within radius (lat, lng, radius) |
| GET | `/reports/tracking/:code` | Public tracking by code (no auth) |

#### Users

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/auth/register` | Citizen registration |
| POST | `/auth/login` | Login (email or phone) |
| POST | `/auth/otp/request` | Request OTP |
| POST | `/auth/otp/verify` | Verify OTP |
| GET | `/users/me` | Get own profile |
| PATCH | `/users/me` | Update profile |

#### Admin

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/admin/stats` | Dashboard KPI summary |
| GET | `/admin/reports/export` | Export reports (CSV/Excel) |
| GET | `/admin/users` | List staff users |
| POST | `/admin/users` | Create staff user |
| PATCH | `/admin/users/:id` | Update staff user |

#### Notifications

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/notifications` | Citizen notification feed |
| PATCH | `/notifications/:id/read` | Mark as read |
| POST | `/admin/notifications/broadcast` | Broadcast message to area |

### Report Status State Machine

```
SUBMITTED → RECEIVED → UNDER_REVIEW → SCHEDULED → IN_PROGRESS → RESOLVED → CLOSED
                                                                      ↓
                                                                  REJECTED
```

Status transitions are validated server-side. Backwards transitions are blocked except by admins.

### File Upload

- Photos uploaded directly to S3/MinIO via pre-signed URL
- Max file size: 10 MB
- Accepted formats: JPEG, PNG, HEIC
- Server generates thumbnail (400×400) on upload
- Original and thumbnail URLs stored in report record

---

## 7. Database Schema

### Core Tables

#### `reports`

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | Primary key |
| tracking_code | VARCHAR(10) | Human-readable, unique |
| citizen_id | UUID | FK → users |
| category_id | INT | FK → categories |
| status | ENUM | See state machine above |
| title | VARCHAR(200) | Auto-generated or citizen-provided |
| description | TEXT | Optional, 500 chars |
| photo_url | TEXT | S3 URL |
| thumbnail_url | TEXT | S3 URL |
| location | GEOMETRY(Point, 4326) | PostGIS point |
| address | TEXT | Reverse geocoded |
| city | VARCHAR(100) | |
| ward | VARCHAR(100) | Administrative subdivision |
| assigned_to | UUID | FK → users (staff) |
| department_id | INT | FK → departments |
| ai_category_id | INT | AI-suggested category |
| ai_confidence | FLOAT | 0–1 |
| is_duplicate | BOOLEAN | Default false |
| duplicate_of | UUID | FK → reports |
| priority | ENUM | low / medium / high / critical |
| resolved_at | TIMESTAMP | |
| created_at | TIMESTAMP | |
| updated_at | TIMESTAMP | |

#### `report_status_history`

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | |
| report_id | UUID | FK → reports |
| from_status | ENUM | |
| to_status | ENUM | |
| changed_by | UUID | FK → users |
| note | TEXT | Internal note |
| created_at | TIMESTAMP | |

#### `users`

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | |
| role | ENUM | citizen / supervisor / field_agent / analyst / admin |
| full_name | VARCHAR(200) | |
| phone | VARCHAR(20) | Unique |
| email | VARCHAR(200) | Unique |
| password_hash | TEXT | bcrypt |
| municipality_id | INT | FK → municipalities (staff only) |
| fcm_token | TEXT | Push notification token |
| preferred_language | CHAR(2) | ar / fr / en |
| is_active | BOOLEAN | |
| created_at | TIMESTAMP | |

#### `categories`

| Column | Type | Notes |
|--------|------|-------|
| id | INT | |
| parent_id | INT | Self-referential (subcategories) |
| slug | VARCHAR(100) | e.g. `road.pothole` |
| label_ar | VARCHAR(200) | Arabic label |
| label_fr | VARCHAR(200) | French label |
| label_en | VARCHAR(200) | English label |
| default_department_id | INT | FK → departments |
| icon | VARCHAR(50) | Icon identifier |
| sla_hours | INT | Target resolution time |

#### `municipalities`

| Column | Type | Notes |
|--------|------|-------|
| id | INT | |
| name | VARCHAR(200) | |
| boundary | GEOMETRY(Polygon, 4326) | Service area |
| logo_url | TEXT | |
| subscription_tier | VARCHAR(50) | |
| subscription_expires | DATE | |

---

## 8. GIS and Mapping

### Map Provider

**Mapbox GL JS** for the web admin dashboard, with OpenStreetMap tiles as fallback. Mobile uses `react-native-mapbox-gl`.

### Spatial Features

| Feature | Implementation |
|---------|---------------|
| Report pin display | Mapbox point layer with category icons |
| Clustering | Mapbox built-in cluster layer |
| Heatmap | Mapbox heatmap layer for density view |
| Service area | Municipality boundary polygon layer |
| Polygon selection | Mapbox Draw for admin area selection |
| Reverse geocoding | Nominatim (OpenStreetMap) or Mapbox Geocoding API |
| Proximity search | PostGIS `ST_DWithin` for nearby reports |
| Duplicate detection | PostGIS `ST_Distance` — flag reports within 50m of same category |

### PostGIS Queries Used

```sql
-- Reports within 500m of a point
SELECT * FROM reports
WHERE ST_DWithin(
  location::geography,
  ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)::geography,
  500
);

-- Potential duplicates (same category, within 50m, last 48h)
SELECT r2.id FROM reports r1
JOIN reports r2
  ON r1.category_id = r2.category_id
  AND r1.id != r2.id
  AND ST_DWithin(r1.location::geography, r2.location::geography, 50)
  AND r2.created_at > NOW() - INTERVAL '48 hours'
WHERE r1.id = :report_id;
```

---

## 9. Notification System

### Channels

| Channel | Provider | Trigger |
|---------|----------|---------|
| Push | Firebase Cloud Messaging | Every status change |
| SMS | Twilio / local gateway | Submission confirmation + resolution |
| Email | SendGrid | Registration, resolution |
| In-app | API feed | All events |

### Notification Events

| Event | Push | SMS | Email |
|-------|------|-----|-------|
| Report submitted | ✓ | ✓ | — |
| Report received by authority | ✓ | — | — |
| Report under review | ✓ | — | — |
| Intervention scheduled | ✓ | ✓ | — |
| Work in progress | ✓ | — | — |
| Report resolved | ✓ | ✓ | ✓ |
| Report closed | ✓ | — | ✓ |
| SLA breach (staff) | ✓ | — | ✓ |

### Message Templates

Templates are stored per municipality, per language (AR/FR/EN), per event type. Example:

```
[RESOLVED - EN]
Subject: Your report #{tracking_code} has been resolved
Body: Great news! The issue you reported at {address} on {date}
has been resolved by {municipality_name}. Thank you for helping
improve your city.
```

---

## 10. AI Module

The AI module is a separate **Python FastAPI** microservice called asynchronously after each report submission.

### Functions

#### 1. Category Classification

- Model: fine-tuned multilingual BERT (Arabic/French/English)
- Input: report description text + optional photo embedding
- Output: predicted `category_id` + confidence score
- Threshold: if confidence < 0.6, flag for manual review

#### 2. Duplicate Detection

- Combines: spatial proximity (PostGIS) + semantic similarity (text embedding cosine distance)
- Window: reports in the last 48 hours, within 50m, same top-level category
- Output: `is_duplicate: true/false`, `duplicate_of: report_id`

#### 3. Image Analysis

- Model: Vision model (e.g., CLIP or ResNet fine-tuned on urban infrastructure)
- Input: uploaded photo
- Output: detected issue tags (e.g., `pothole`, `broken_sign`, `flooding`)
- Used to cross-validate citizen-selected category

#### 4. Priority Scoring

Scores reports 1–10 based on:

| Factor | Weight |
|--------|--------|
| Category severity baseline | 30% |
| Citizen-reported urgency flag | 20% |
| Number of duplicate reports on same issue | 25% |
| Proximity to sensitive zones (schools, hospitals) | 15% |
| Age of issue (time since first report) | 10% |

#### 5. Automated Performance Reports

- Weekly cron job generates municipality-level PDF reports
- Metrics: volume, resolution rate, avg response time, top 5 unresolved categories
- Delivered via email to municipality supervisors

### API Contract (Internal)

```
POST /ai/analyze
{
  "report_id": "uuid",
  "text": "string",
  "photo_url": "string",
  "location": { "lat": 36.8, "lng": 10.18 },
  "language": "ar" | "fr" | "en"
}

Response:
{
  "category_id": 12,
  "ai_confidence": 0.87,
  "is_duplicate": false,
  "duplicate_of": null,
  "priority": "high",
  "image_tags": ["pothole", "road_damage"]
}
```

---

## 11. Security and Privacy

### Authentication and Authorization

- All API endpoints require JWT except `/auth/*` and `/reports/tracking/:code`
- Tokens signed with RS256 (asymmetric)
- Refresh token rotation on every use
- Rate limiting: 100 req/min per IP, 20 req/min per user

### Data Privacy

- Citizen phone numbers and emails are never exposed via public API
- Report tracking page shows category, status, and location only — no PII
- Photos are stored with randomized UUIDs (not user-identifiable paths)
- GDPR-aligned: citizens can request account deletion and data export
- Tunisia Data Protection Law (Law 63-2004) compliance required

### Infrastructure Security

- All traffic over HTTPS (TLS 1.2+)
- Database accessible only from private network (no public endpoint)
- S3 bucket with private ACL; access via pre-signed URLs only
- Secrets managed via environment variables / AWS Secrets Manager
- Penetration test required before production launch

### Input Validation

- All inputs validated and sanitized server-side (class-validator + sanitize-html)
- File type validation by magic bytes (not just extension)
- Max payload size: 15 MB per request

---

## 12. Localization

### Supported Languages

| Code | Language | Direction |
|------|----------|-----------|
| `ar` | Arabic | RTL |
| `fr` | French | LTR |
| `en` | English | LTR |

### Implementation

- Mobile: `react-i18next` with language JSON files per locale
- RTL layout: React Native built-in `I18nManager.forceRTL(true)` for Arabic
- Web admin: `react-i18next` + CSS logical properties for RTL support
- Database: category labels stored per language (`label_ar`, `label_fr`, `label_en`)
- Notification templates: one row per language per event type

### Date and Number Formatting

- Dates rendered using `Intl.DateTimeFormat` with user locale
- Arabic numerals (`٠١٢٣...`) used in Arabic mode
- Hijri calendar display option for Arabic users

---

## 13. KPIs and Monitoring

### Application Monitoring

| Tool | Purpose |
|------|---------|
| Sentry | Error tracking (mobile + API) |
| Grafana + Prometheus | Infrastructure metrics |
| Datadog (optional) | APM and log management |
| Uptime Robot | Uptime alerts |

### Business KPI Dashboard (Admin)

Metrics tracked in real time:

- Total reports submitted (daily/weekly/monthly)
- Reports by status breakdown
- Average time to first response
- Average time to resolution
- Resolution rate (% closed within SLA)
- Citizen satisfaction score (post-resolution survey)
- Top 5 most-reported categories
- Performance ranking by municipality / department

### Alerts

| Alert | Threshold | Channel |
|-------|-----------|---------|
| Report SLA breach | > 7 days unresolved | Email to supervisor |
| API error rate spike | > 5% errors in 5 min | Slack + email |
| Uptime drop | < 99.5% | SMS to admin |
| Disk usage | > 80% | Email to admin |

---

## 14. Development Phases

### Phase 1 — Discovery and Planning (Weeks 1–4)

- Stakeholder interviews with 2–3 pilot municipalities
- Define report categories and routing rules
- Finalize tech stack and hosting provider
- Privacy/legal review (Tunisia data protection law)
- Produce final requirements document and sign-off

### Phase 2 — Design and Prototyping (Weeks 5–8)

- UI/UX wireframes for all citizen screens
- Admin dashboard mockups
- Brand identity (logo, colors, typography)
- Clickable prototype for user testing
- Multilingual layout review (RTL Arabic)
- Municipality sign-off on designs

### Phase 3 — Core Development (Weeks 9–20)

**Sprint 1–2 (Weeks 9–12):** Backend foundation
- Database setup (PostgreSQL + PostGIS)
- Authentication service (JWT + OTP)
- Core report CRUD API
- File upload pipeline (S3 + thumbnails)

**Sprint 3–4 (Weeks 13–16):** Mobile app
- Report submission flow (camera, GPS, categories)
- My Reports screen and status tracking
- Push notification integration
- Offline queuing

**Sprint 5–6 (Weeks 17–20):** Admin dashboard
- Report management (list, filter, assign, update)
- GIS map view with clustering
- Team management
- Basic analytics charts

### Phase 4 — AI Integration (Weeks 21–26)

- Train/fine-tune classification model on sample reports
- Build duplicate detection service
- Integrate AI responses into report submission pipeline
- Image analysis endpoint
- Automated weekly report generation

### Phase 5 — Testing and QA (Weeks 27–30)

- Functional and regression test suite
- UAT with pilot municipality staff and citizens
- Performance and load testing (target: 500 concurrent users)
- Security audit and penetration test
- Accessibility review (WCAG 2.1 AA)
- Bug fix sprint

### Phase 6 — Launch and Growth (Weeks 31–40+)

- Staged rollout to 1–2 pilot municipalities
- Citizen onboarding campaign (social media, municipality comms)
- Live KPI monitoring and weekly reviews
- Feedback collection and prioritized fixes
- Onboard additional municipalities from Week 36

---

## 15. Budget Estimate

| Item | Estimated Cost (EUR) |
|------|---------------------|
| Mobile app development (iOS + Android) | 40,000 – 70,000 |
| Admin dashboard development | 20,000 – 40,000 |
| Backend API development | Included above |
| GIS and mapping integration | 5,000 – 15,000 |
| AI module development | 15,000 – 30,000 |
| Hosting and DevOps setup | 5,000 – 10,000 |
| Security audit | 3,000 – 6,000 |
| Marketing and training | 10,000 – 20,000 |
| **Total** | **€95,000 – €185,000** |

### Ongoing Annual Costs (Post-Launch)

| Item | Estimated Annual Cost (EUR) |
|------|-----------------------------|
| Cloud hosting (API + DB + storage) | 6,000 – 18,000 |
| SMS gateway | 2,000 – 5,000 |
| Push + email services | 500 – 2,000 |
| Maintenance and support | 12,000 – 24,000 |
| **Total recurring** | **€20,500 – €49,000** |

---

## 16. Appendix — Report Categories

### Category Tree

```
Infrastructure
├── Road potholes
├── Damaged sidewalks
├── Missing road signs
└── Damaged road signs

Public Lighting
├── Faulty streetlights
└── Exposed electrical wires

Cleanliness and Waste Management
├── Illegal dumping
├── Accumulated garbage
└── Overflowing waste containers

Environment
├── Water pollution
├── Air pollution
└── Illegal tree cutting

Water and Sanitation
├── Water leaks
└── Blocked sewage systems

Transportation
├── Damaged bus stops
└── Traffic signal malfunctions

Safety and Security
├── Unsafe or collapsing buildings
└── Public safety hazards
```

### Default SLA by Category

| Category | Target Resolution |
|----------|------------------|
| Safety and Security (critical) | 24 hours |
| Water and Sanitation | 48 hours |
| Public Lighting | 72 hours |
| Infrastructure | 7 days |
| Cleanliness and Waste | 7 days |
| Environment | 14 days |
| Transportation | 7 days |

---

*Citizen Alert — Technical Specification v1.0*  
*For questions or contributions, contact the project team.*
