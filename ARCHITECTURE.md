# Sahali — System Architecture

```mermaid
flowchart TB
    subgraph MOBILE["📱 Mobile App — Flutter / Dart"]
        M_CORE["Core\nGoRouter · AppLocalizations EN/FR/AR · AppTheme"]
        M_UI["UI Screens\nAuth: Splash · Onboarding · Language · Login\nMain: Home · Emergency · Profile\nReport Wizard: Category → Photo → Location → Description → Review → Confirmation\nCitizen: My Reports · Report Detail · Notifications"]
        M_STATE["State — Provider Pattern\nLanguageProvider · AuthProvider\nReportFormProvider · ReportsProvider · NotificationsProvider"]
        M_SVC["Services\nAuthService · ReportService · CategoryService · NotificationService"]
        M_NET["ApiClient — Dio + JWT Bearer\nAuthInterceptor · Token Refresh"]
        M_UI --> M_STATE
        M_STATE --> M_SVC
        M_SVC --> M_NET
    end

    subgraph DASH["🖥️ Dashboard — React 19 / TypeScript"]
        D_UI["Pages\nLogin · Dashboard Stats · Reports List · Map/GIS\nInterventions · Teams · Categories · Municipalities · Statistics · Calendar · Settings"]
        D_CTX["AuthContext — JWT in localStorage"]
        D_API["api.ts — Fetch wrapper + Token Refresh\nBaseURL: /v1"]
        D_UI --> D_CTX
        D_CTX --> D_API
    end

    subgraph BACKEND["⚙️ Backend — FastAPI / Python 3.12"]
        B_API["REST API  /v1\n/auth  — register · login · OTP · refresh\n/reports  — CRUD · nearby · status · assign · tracking\n/categories  — hierarchical list\n/notifications  — get · mark-read\n/users  — profile · preferences\n/admin  — stats · staff management"]
        B_SEC["Security\nJWT RS256 · Bcrypt\nDependency Injection · RBAC Roles"]
        B_SVC["Services\nStorageService — MinIO presigned URLs\nNotificationService — FCM · SMS · Email\nOTPService — Twilio OTP\nAIClient — async category analysis"]
        B_CEL["Celery Workers\nAsync: AI analysis · notification dispatch"]
        B_ORM["SQLAlchemy ORM + Alembic\nUser · Report + StatusHistory\nCategory · Municipality · Department · Notification"]
        B_API --> B_SEC
        B_API --> B_SVC
        B_API --> B_ORM
        B_CEL --> B_SVC
    end

    subgraph INFRA["🐳 Docker — Infrastructure"]
        DB[("PostgreSQL 15\n+ PostGIS\nGeospatial reports DB")]
        REDIS[("Redis\nCache · Celery broker")]
        MINIO[("MinIO\nS3-compatible\nPhoto storage")]
    end

    subgraph EXT["☁️ External Services"]
        FCM["Firebase FCM\nPush Notifications"]
        TWILIO["Twilio\nSMS · OTP"]
        SENDGRID["SendGrid\nEmail Alerts"]
    end

    M_NET  -->|"HTTPS REST"| B_API
    D_API  -->|"HTTPS REST"| B_API
    B_ORM  --> DB
    B_SVC  --> MINIO
    B_CEL  --> REDIS
    B_SVC  --> FCM
    B_SVC  --> TWILIO
    B_SVC  --> SENDGRID
```

## Quick Reference

| Layer | Tech | Purpose |
|---|---|---|
| Mobile | Flutter 3.11 · GoRouter · Provider | Citizen-facing reporting app (portrait, tri-lingual) |
| Dashboard | React 19 · TypeScript · Tailwind · Recharts | Admin/supervisor web portal |
| Backend | FastAPI · SQLAlchemy · Celery | REST API + async workers |
| Database | PostgreSQL 15 + PostGIS | Geospatial report storage |
| Cache/Queue | Redis | Celery broker + API caching |
| Storage | MinIO (S3) | Report photos |
| Auth | JWT RS256 · Bcrypt | RS256 key-pair in `private.pem` / `public.pem` |
| Push | Firebase FCM | Mobile push notifications |
| SMS | Twilio | OTP verification + SMS alerts |
| Email | SendGrid | Status update emails |
