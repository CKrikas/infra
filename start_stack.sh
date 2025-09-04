#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# 0) Ensure Docker is up
if ! docker info >/dev/null 2>&1; then
  echo "Docker daemon is not running. Start it (e.g., 'sudo systemctl start docker') and retry." >&2
  exit 1
fi

# 1) Start containers
echo "==> Starting containers..."
docker compose up -d

# 2) Read exposed ports from Compose
get_port() { docker compose port "$1" "$2" 2>/dev/null | tail -n1 | sed -E 's/.*:([0-9]+)$/\1/'; }
CITIZEN_PORT="${CITIZEN_PORT:-$(get_port citizen-portal 80 || true)}"
ADMIN_PORT="${ADMIN_PORT:-$(get_port admin-portal 80 || true)}"
API_PORT="${API_PORT:-$(get_port api 8000 || true)}"
KEYCLOAK_PORT="${KEYCLOAK_PORT:-$(get_port keycloak 8080 || true)}"
MAILHOG_PORT="${MAILHOG_PORT:-$(get_port mailhog 8025 || true)}"

API_URL="http://localhost:${API_PORT:-8000}/health"

# 3) Wait for API to be healthy
echo "==> Waiting for API at $API_URL ..."
for i in {1..60}; do
  if curl -fsS "$API_URL" | grep -q '"ok"'; then
    echo "API is healthy ✅"
    break
  fi
  sleep 2
  if [ $i -eq 60 ]; then
    echo "API failed to become healthy. Recent logs:" >&2
    docker compose logs --tail=100 api || true
    exit 1
  fi
done

# 4) Show URLs
echo
echo "Open these:"
[ -n "${CITIZEN_PORT:-}" ] && echo "  Citizen portal: http://localhost:${CITIZEN_PORT}"
[ -n "${ADMIN_PORT:-}" ] && echo "  Admin portal:   http://localhost:${ADMIN_PORT}"
[ -n "${API_PORT:-}" ] && echo "  API health:     http://localhost:${API_PORT}/health"
[ -n "${KEYCLOAK_PORT:-}" ] && echo "  Keycloak:       http://localhost:${KEYCLOAK_PORT}/auth"
[ -n "${MAILHOG_PORT:-}" ] && echo "  MailHog UI:     http://localhost:${MAILHOG_PORT}"
