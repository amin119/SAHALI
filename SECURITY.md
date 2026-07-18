# Security Hardening — Summary

Status: two branches, neither merged into `main` yet (production is under client testing — merge only once that's cleared):
- `security/phase1-critical` — Phases 1-3 below.
- `cicd/pipeline` — branched from the above (contains all of it, plus everything from "CI/CD pipeline" onward). Merge order: `security/phase1-critical` into `main` first, then `cicd/pipeline` — git only brings in what's actually new the second time.

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

- Reconciled the `Pillow` version mismatch between `pyproject.toml` and `requirements.txt` (superseded — see dependency remediation below, both now `12.3.0`).
- Removed two dead settings (`SECRET_KEY`, `USER_RATE_LIMIT_PER_MINUTE`) — never read anywhere in the codebase.
- Added CI (`.github/workflows/ci.yml`): ruff + pip-audit (backend), type-check + build + npm audit (dashboard), flutter analyze (mobile).
- Added Dependabot (`.github/dependabot.yml`) for pip, npm, pub, and GitHub Actions.
- Gated the mobile `debug_code` UI hint behind `kDebugMode` — defense in depth, independent of the backend's own `DEBUG` flag.
- `pip-audit` still can't run locally (machine-specific TLS issue) — now runs for real in CI instead.

## Low

- Dev-only MinIO credentials in `docker-compose.yml`/`.env.example` — not a real issue, confirmed intentional.
- Removed a non-functional LAN cleartext-traffic entry (`192.168.0.0`) from Android's network security config — Android has no IP-range syntax, so it never actually matched anything; physical-device testing already goes through ngrok (HTTPS).

## CI/CD pipeline (branch: `cicd/pipeline`)

- Real backend test suite (`backend/tests/`, 9 tests): OTP lockout, refresh-token single-use rotation, logout revocation, rate limiting, SSE ticket issuance/single-use/concurrency — runs against real Postgres+Redis service containers in CI.
- Docker build check (`backend-docker-build` job) — catches a broken `Dockerfile` before Render does.
- Mobile release workflow (`.github/workflows/mobile-release.yml`) — builds a signed APK+AAB on a version tag and attaches it to a GitHub Release; keystore/passwords come from repo secrets, never committed. All actions pinned to commit SHAs (not mutable tags), since this workflow holds `contents: write` + signing secrets.
- Fixed a real, pre-existing bug found along the way: the mobile smoke test (`test/widget_test.dart`) was silently broken (missing providers) and had never actually been passing.
- **`.claude/settings.local.json` was tracked in git** (since the same commit that leaked the JWT key) and contained a plaintext password embedded in a permission rule. Untracked it and added it, `.env`/`.env.*`, and `firebase-credentials.json` to `.gitignore`. If `Demo1234!` is still a live password anywhere, rotate it.

## Dependency vulnerability remediation

`pip-audit` (only runs in CI — blocked locally by a machine-specific TLS issue) found real CVEs across the backend's dependency tree. Fixed by bumping: `fastapi` 0.111.0→0.139.2 (needed to unlock a patched `starlette`, →1.3.1), `pydantic` 2.7.4→2.13.4 (pulled in by the fastapi bump), `python-jose` →3.5.0 (also fixes a transitive `pyasn1` CVE), `python-multipart` →0.0.32, `Pillow` →12.3.0, `bleach` →6.4.0, `python-dotenv` →1.2.2, `sentry-sdk` →2.66.0. Added `email-validator` as an explicit dependency (was only ever present incidentally in local dev venvs, never actually declared — real prod gap). All validated: full test suite passed against a from-scratch clean install of `requirements.txt` alone (not just an already-populated venv), plus a live registration smoke test. One exception: `ecdsa`'s timing side-channel (`PYSEC-2026-1325`) has no upstream fix — explicitly ignored in CI, since it's a transitive dep of `python-jose` for ECDSA algorithms this app never uses (JWTs are RS256-only).

## Additional hardening from code review

- Refresh-token rotation is now a genuinely atomic Redis `SET...NX` claim (`consume_once`), not a check-then-revoke — closes a race where two concurrent refreshes of the same token could both succeed.
- Same atomicity fix applied to SSE ticket consumption (`GETDEL` instead of GET-then-DELETE), with a `threading.Barrier`-synchronized test that actually forces the race rather than hoping two threads happen to overlap.
- Fixed a TTL-truncation bug in the token denylist (`int()` → `math.ceil()`) that could let a claim expire ~1s before the token itself did.
- CORS wildcard in production now hard-fails at startup (`RuntimeError`) instead of just logging a warning.
- Fixed a real bug in `storage.py`'s presigned-upload URL construction (was duplicating the bucket name for plain AWS S3, and ignoring `AWS_S3_PUBLIC_URL` for custom endpoints).
- `events.py`'s SSE route was `async def` doing synchronous Redis/DB calls, blocking the event loop; changed to sync `def` (FastAPI runs those in a thread pool) while the actual streaming stays async.
- Android's keystore-missing check (added in Phase 1) was breaking *all* Gradle builds, not just release ones, and even release builds hit Android's own less-clear error before it fired. Rewrote it to run only immediately before the actual signing step — tested all three paths for real (no keystore + debug task succeeds, no keystore + release task fails with the clear message, real keystore + release task produces a real signed APK).

## Still open (need your input, not more code)

1. **CORS domain** — give the exact Vercel domain to tighten the regex.
2. **Git history purge** — `git filter-repo` to remove the old leaked key blob permanently. Lower urgency now (repo is private, key is rotated and dead) — your call on timing.

## Before merging to `main`

Remove `SECRET_KEY` and `USER_RATE_LIMIT_PER_MINUTE` from the `sahali-1` Render service's environment variables first — the app now rejects unrecognized settings at startup and will fail to boot otherwise.
