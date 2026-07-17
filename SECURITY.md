# Security Hardening — Summary

Status: complete on branch `security/phase1-critical`, **not merged into `main`** (production is under client testing — merge only once that's cleared).

## Critical

- Rotated the RS256 JWT key pair (old one was retrievable from git history at commit `21589fd`). Verified live via `/health/db`.
- `admin@sahali.tn` production password rotated (the old hardcoded one is considered burned).
- `POST /reports/photo` now requires auth, has a 25MB size cap and a content-type whitelist.
- `GET /health/db` and `GET /admin/storage/test` now require super-admin auth; no longer leak raw exceptions or confirm specific accounts.
- Removed hardcoded admin credentials from `scripts/create_admin.py` — generates a random password at runtime instead.
- Android release builds now sign with a real keystore (`android/key.properties`, gitignored) instead of the shared debug key.
- Added `POST /auth/logout` + a Redis-backed `jti` denylist so refresh/access tokens can actually be revoked.

## High

- CORS: `CORS_VERCEL_ORIGIN_REGEX` is now a setting instead of hardcoded; added a startup warning if `CORS_ORIGINS` is still `*` in production. **Still open**: regex is still the broad `*.vercel.app` pattern — needs the exact dashboard domain to tighten further.
- Added security headers (backend middleware + dashboard `vercel.json`: CSP, HSTS, X-Frame-Options, etc.).
- Added per-route rate limits: login (10/min), OTP/email-send (3/min), OTP/email-verify (10/min), reset-password (5/min), report submission (10/min).
- OTP verification now uses constant-time comparison (`hmac.compare_digest`) plus a 5-attempt lockout per code.
- Storage filenames are sanitized before being used in the object key.
- Added `NSMicrophoneUsageDescription` to iOS `Info.plist` (voice-note feature).
- Replaced the SSE token-in-URL with a 60-second single-use ticket (`POST /events/ticket`) — real access tokens no longer sit in server logs/browser history.

## Medium

- Reconciled the `Pillow` version mismatch between `pyproject.toml` and `requirements.txt` (both now `11.2.1`).
- Removed two dead settings (`SECRET_KEY`, `USER_RATE_LIMIT_PER_MINUTE`) — never read anywhere in the codebase.
- Added CI (`.github/workflows/ci.yml`): ruff + pip-audit (backend), type-check + build + npm audit (dashboard), flutter analyze (mobile).
- Added Dependabot (`.github/dependabot.yml`) for pip, npm, pub, and GitHub Actions.
- Gated the mobile `debug_code` UI hint behind `kDebugMode` — defense in depth, independent of the backend's own `DEBUG` flag.
- `pip-audit` still can't run locally (machine-specific TLS issue) — now runs for real in CI instead.

## Low

- Dev-only MinIO credentials in `docker-compose.yml`/`.env.example` — not a real issue, confirmed intentional.
- Removed a non-functional LAN cleartext-traffic entry (`192.168.0.0`) from Android's network security config — Android has no IP-range syntax, so it never actually matched anything; physical-device testing already goes through ngrok (HTTPS).

## Still open (need your input, not more code)

1. **CORS domain** — give the exact Vercel domain to tighten the regex.
2. **Git history purge** — `git filter-repo` to remove the old leaked key blob permanently. Lower urgency now (repo is private, key is rotated and dead) — your call on timing.

## Before merging to `main`

Remove `SECRET_KEY` and `USER_RATE_LIMIT_PER_MINUTE` from the `sahali-1` Render service's environment variables first — the app now rejects unrecognized settings at startup and will fail to boot otherwise.
