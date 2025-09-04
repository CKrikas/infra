#!/usr/bin/env bash
set -euo pipefail

# === Config (adjust if you changed compose ports) ===
CITIZEN_PORT=${CITIZEN_PORT:-5173}
ADMIN_PORT=${ADMIN_PORT:-5174}
API_URL=${API_URL:-http://localhost:8000/health}

echo "==> Using CITIZEN_PORT=$CITIZEN_PORT ADMIN_PORT=$ADMIN_PORT"

# 1) Stop previous stack (keeps DB volume)
echo "==> Stopping previous stack..."
docker compose down || true

# (Optional) ensure key ports are free; uncomment to auto-kill
# for p in "$CITIZEN_PORT" "$ADMIN_PORT" 8000 8080 8025 1025; do
#   pid=$(lsof -ti :$p 2>/dev/null || true)
#   if [ -n "$pid" ]; then echo "Killing PID $pid on port $p"; kill -9 "$pid" || true; fi
# done

# 2) Build & start everything
echo "==> Building images and starting containers..."
docker compose up -d --build

echo "==> Current status:"
docker compose ps

# 3) Wait for API health
echo "==> Waiting for API at $API_URL ..."
for i in {1..60}; do
  if curl -fsS "$API_URL" | grep -q '"ok"'; then
    echo "API is healthy ✅"
    break
  fi
  sleep 2
  if [ $i -eq 60 ]; then
    echo "API failed to become healthy. Recent logs:"
    docker compose logs --no-color --tail=100 api || true
    exit 1
  fi
done

echo
echo "Open these:"
echo "  Citizen portal: http://localhost:${CITIZEN_PORT}"
echo "  Admin portal:   http://localhost:${ADMIN_PORT}"
echo "  API health:     ${API_URL}"
echo "  Keycloak:       http://localhost:8080/auth"
echo "  MailHog UI:     http://localhost:8025"
