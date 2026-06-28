# سهلي — Sahali

A civic reporting mobile app for Tunisian citizens. Report public infrastructure issues directly to your municipality — potholes, broken streetlights, waste overflow, water leaks, and more.

## What it does

- Report an issue in under 2 minutes (photo → location → description → submit)
- Track your report's status in real time through the full resolution cycle
- Get notified at every update until the issue is resolved
- Access emergency numbers for Tunisia (police, SAMU, pompiers, etc.)

## Tech stack

- **Flutter** 3.11.5 — iOS & Android
- **GoRouter** — declarative navigation
- **Provider** — state management
- **FastAPI** backend (see `../backend/`)
- **PostgreSQL** + Alembic migrations
- **OpenStreetMap** (flutter_map) — no Google Maps dependency

## Localization

Fully trilingual: **French**, **Arabic**, **English**. Language is persisted per user and switching is instant app-wide. Arabic enables RTL automatically via Flutter's Directionality system.

## Project structure

```
lib/
├── core/
│   ├── l10n/          # AppLocalizations — manual delegate, no codegen
│   ├── providers/     # LanguageProvider
│   ├── router/        # GoRouter config
│   └── theme/         # Colors, theme
├── features/
│   ├── auth/          # Login (OTP + email/password)
│   ├── home/          # Dashboard
│   ├── report/        # Report wizard (6-step flow)
│   ├── my_reports/    # Report list + detail + status timeline
│   ├── notifications/ # Push notifications
│   ├── emergency/     # Tunisia emergency numbers
│   ├── onboarding/    # First-launch flow
│   └── profile/       # Settings, language switcher
└── shared/
    └── widgets/       # SahaliLogo, StatusBadge, SaButton, StepBar
```

## Getting started

```bash
flutter pub get
flutter run
```

The app connects to the FastAPI backend. Copy `../backend/.env.example` to `../backend/.env` and fill in the required values before running the backend.
