#!/bin/bash
set -e

echo "=== Citizen Alert — Dev Setup ==="

# 1. Generate JWT keys if not present
if [ ! -f private.pem ]; then
  echo "Generating JWT keys..."
  bash scripts/generate_keys.sh
fi

# 2. Copy env file if not present
if [ ! -f .env ]; then
  cp .env.example .env
  echo ".env created from .env.example — edit as needed"
fi

# 3. Start infrastructure
echo "Starting Docker services (Postgres + PostGIS, Redis, MinIO)..."
docker-compose up -d db redis minio createbuckets

echo "Waiting for DB to be ready..."
sleep 5

# 4. Run migrations
echo "Running Alembic migrations..."
alembic upgrade head

echo ""
echo "=== Setup complete ==="
echo "Start the API: uvicorn app.main:app --reload"
echo "Swagger docs:  http://localhost:8000/docs"
echo "MinIO console: http://localhost:9001  (minioadmin / minioadmin)"
