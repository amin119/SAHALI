# =============================================================================
# Citizen Alert — Project Makefile
# Requires: uv, docker, make, openssl (via Git on Windows)
# Install uv (Windows PowerShell):
#   powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
# Install make (Windows): scoop install make  OR  choco install make
# =============================================================================

.DEFAULT_GOAL := help

# Force Git Bash as the shell on Windows so all recipes use POSIX syntax
ifeq ($(OS),Windows_NT)
    SHELL   := C:/Program Files/Git/usr/bin/sh.exe
    .SHELLFLAGS := -c
    OPENSSL := C:/Program Files/Git/usr/bin/openssl.exe
else
    OPENSSL := openssl
endif

# $(CURDIR) is a make built-in — no shell call, works everywhere
ROOT        := $(CURDIR)
BACKEND_DIR := $(ROOT)/backend
AI_DIR      := $(ROOT)/ai
DASH_DIR    := $(ROOT)/dashboard
MOBILE_DIR  := $(ROOT)/mobile

# ── Colors ───────────────────────────────────────────────────────────────────
CYAN  := \033[0;36m
GREEN := \033[0;32m
RESET := \033[0m

# =============================================================================
# HELP
# =============================================================================
.PHONY: help
help: ## Show this help
	@echo ""
	@echo "  $(CYAN)Citizen Alert — Command Reference$(RESET)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	  | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-28s$(RESET) %s\n", $$1, $$2}'
	@echo ""

# =============================================================================
# SETUP — run once to bootstrap the whole project
# =============================================================================
.PHONY: setup
setup: check-uv keys backend-install docker-up wait-db migrate ## Bootstrap the entire project (first-time setup)
	@echo ""
	@echo "  $(GREEN)✓ Setup complete$(RESET)"
	@echo "  Run 'make dev' to start the development environment"
	@echo ""

.PHONY: check-uv
check-uv: ## Verify uv is installed
	@uv --version >/dev/null 2>&1 || \
	  (echo "uv not found. Install (Windows PowerShell):" && \
	   echo "  powershell -ExecutionPolicy ByPass -c \"irm https://astral.sh/uv/install.ps1 | iex\"" && \
	   echo "Then restart your terminal." && exit 1)
	@echo "  $(GREEN)✓ uv $(shell uv --version) found$(RESET)"

# =============================================================================
# JWT KEYS
# =============================================================================
.PHONY: keys
keys: ## Generate RS256 JWT key pair (private.pem + public.pem)
	@if [ -f "$(BACKEND_DIR)/private.pem" ]; then \
	  echo "  Keys already exist — skipping"; \
	else \
	  "$(OPENSSL)" genrsa -out "$(BACKEND_DIR)/private.pem" 2048 2>/dev/null; \
	  "$(OPENSSL)" rsa -in "$(BACKEND_DIR)/private.pem" -pubout -out "$(BACKEND_DIR)/public.pem" 2>/dev/null; \
	  echo "  $(GREEN)✓ JWT keys generated$(RESET)"; \
	fi

# =============================================================================
# BACKEND  (all commands use `uv run` — no activation or path hacks needed)
# =============================================================================
.PHONY: backend-install
backend-install: ## Install backend dependencies via uv
	@echo "  Installing backend dependencies..."
	cd "$(BACKEND_DIR)" && uv venv --python 3.12
	cd "$(BACKEND_DIR)" && uv pip install -e ".[dev]"
	@if [ ! -f "$(BACKEND_DIR)/.env" ]; then \
	  cp "$(BACKEND_DIR)/.env.example" "$(BACKEND_DIR)/.env"; \
	  echo "  $(GREEN)✓ .env created — edit backend/.env as needed$(RESET)"; \
	fi
	@echo "  $(GREEN)✓ Backend ready$(RESET)"

.PHONY: backend-dev
backend-dev: ## Start the backend API in dev mode (hot-reload)
	cd "$(BACKEND_DIR)" && PYTHONUTF8=1 uv run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

.PHONY: backend-test
backend-test: ## Run backend test suite
	cd "$(BACKEND_DIR)" && uv run pytest -v

.PHONY: backend-lint
backend-lint: ## Lint backend with ruff
	cd "$(BACKEND_DIR)" && uv run ruff check app/

.PHONY: backend-fmt
backend-fmt: ## Format backend code with ruff
	cd "$(BACKEND_DIR)" && uv run ruff format app/

# =============================================================================
# DATABASE / MIGRATIONS  (uv run alembic — uses project venv automatically)
# =============================================================================
.PHONY: migrate
migrate: ## Apply all pending Alembic migrations
	cd "$(BACKEND_DIR)" && uv run alembic upgrade head
	@echo "  $(GREEN)✓ Migrations applied$(RESET)"

.PHONY: migration
migration: ## Create a new migration: make migration name="add_column_x"
	@[ "$(name)" ] || (echo "Usage: make migration name=\"describe the change\"" && exit 1)
	cd "$(BACKEND_DIR)" && uv run alembic revision --autogenerate -m "$(name)"

.PHONY: migrate-down
migrate-down: ## Roll back the last migration
	cd "$(BACKEND_DIR)" && uv run alembic downgrade -1

.PHONY: db-reset
db-reset: ## Drop and recreate the database (⚠ destroys all data)
	cd "$(BACKEND_DIR)" && uv run alembic downgrade base
	cd "$(BACKEND_DIR)" && uv run alembic upgrade head
	@echo "  $(GREEN)✓ Database reset$(RESET)"

# =============================================================================
# DOCKER  (Postgres+PostGIS, Redis, MinIO)
# =============================================================================
.PHONY: docker-up
docker-up: ## Start infrastructure containers
	docker compose -f "$(BACKEND_DIR)/docker-compose.yml" up -d db redis minio createbuckets
	@echo "  $(GREEN)✓ Infrastructure started$(RESET)"

.PHONY: docker-down
docker-down: ## Stop all infrastructure containers
	docker compose -f "$(BACKEND_DIR)/docker-compose.yml" down

.PHONY: docker-logs
docker-logs: ## Tail infrastructure container logs
	docker compose -f "$(BACKEND_DIR)/docker-compose.yml" logs -f

.PHONY: docker-clean
docker-clean: ## Stop containers and delete volumes (⚠ destroys data)
	docker compose -f "$(BACKEND_DIR)/docker-compose.yml" down -v

.PHONY: wait-db
wait-db: ## Wait until PostgreSQL is ready to accept connections
	@echo "  Waiting for database..."
	@until docker compose -f "$(BACKEND_DIR)/docker-compose.yml" exec -T db \
	  pg_isready -U citizen_alert -q; do sleep 1; done
	@echo "  $(GREEN)✓ Database ready$(RESET)"

# =============================================================================
# AI SERVICE  (Phase 4 — Python FastAPI microservice)
# =============================================================================
.PHONY: ai-install
ai-install: ## Install AI service dependencies via uv
	@[ -d "$(AI_DIR)" ] || (echo "ai/ directory not yet created" && exit 1)
	cd "$(AI_DIR)" && uv venv --python 3.12
	cd "$(AI_DIR)" && uv pip install -e ".[dev]"
	@echo "  $(GREEN)✓ AI service ready$(RESET)"

.PHONY: ai-dev
ai-dev: ## Start the AI microservice in dev mode (port 8001)
	@[ -d "$(AI_DIR)" ] || (echo "ai/ not yet implemented" && exit 1)
	cd "$(AI_DIR)" && uv run uvicorn app.main:app --reload --host 0.0.0.0 --port 8001

# =============================================================================
# DASHBOARD  (Phase 3 — React + TypeScript)
# =============================================================================
.PHONY: dash-install
dash-install: ## Install dashboard dependencies via pnpm
	@[ -d "$(DASH_DIR)" ] || (echo "dashboard/ not yet created" && exit 1)
	cd "$(DASH_DIR)" && pnpm install

.PHONY: dash-dev
dash-dev: ## Start the admin dashboard dev server
	@[ -d "$(DASH_DIR)" ] || (echo "dashboard/ not yet implemented" && exit 1)
	cd "$(DASH_DIR)" && pnpm dev

.PHONY: dash-build
dash-build: ## Build the admin dashboard for production
	@[ -d "$(DASH_DIR)" ] || (echo "dashboard/ not yet implemented" && exit 1)
	cd "$(DASH_DIR)" && pnpm build

# =============================================================================
# MOBILE  (Phase 3 — Flutter)
# =============================================================================
.PHONY: mobile-install
mobile-install: ## Get Flutter dependencies
	@[ -d "$(MOBILE_DIR)" ] || (echo "mobile/ not yet created" && exit 1)
	cd "$(MOBILE_DIR)" && flutter pub get

.PHONY: mobile-dev
mobile-dev: ## Run the Flutter app (choose device interactively)
	@[ -d "$(MOBILE_DIR)" ] || (echo "mobile/ not yet implemented" && exit 1)
	cd "$(MOBILE_DIR)" && flutter run

.PHONY: mobile-build-apk
mobile-build-apk: ## Build Android APK (release)
	@[ -d "$(MOBILE_DIR)" ] || (echo "mobile/ not yet implemented" && exit 1)
	cd "$(MOBILE_DIR)" && flutter build apk --release

.PHONY: mobile-build-ios
mobile-build-ios: ## Build iOS app — requires macOS
	@[ -d "$(MOBILE_DIR)" ] || (echo "mobile/ not yet implemented" && exit 1)
	cd "$(MOBILE_DIR)" && flutter build ios --release

# =============================================================================
# DEV — start everything
# =============================================================================
.PHONY: dev
dev: docker-up ## Start infrastructure + backend API
	@echo ""
	@echo "  Swagger UI → http://localhost:8000/docs"
	@echo "  MinIO UI   → http://localhost:9001  (minioadmin / minioadmin)"
	@echo ""
	$(MAKE) backend-dev

# =============================================================================
# UTILITIES
# =============================================================================
.PHONY: ps
ps: ## Show running Docker container status
	docker compose -f "$(BACKEND_DIR)/docker-compose.yml" ps

.PHONY: shell-db
shell-db: ## Open a psql shell in the database container
	docker compose -f "$(BACKEND_DIR)/docker-compose.yml" exec db \
	  psql -U citizen_alert -d citizen_alert_db

.PHONY: clean
clean: ## Remove venv directories and Python cache files
	rm -rf "$(BACKEND_DIR)/.venv" "$(AI_DIR)/.venv"
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name .pytest_cache -exec rm -rf {} + 2>/dev/null || true
	@echo "  $(GREEN)✓ Cleaned$(RESET)"
