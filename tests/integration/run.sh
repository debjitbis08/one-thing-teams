#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
REPO_ROOT=$(cd "$ROOT_DIR/.." && pwd)

cd "$REPO_ROOT"

if [[ -f .env ]]; then
  set -a
  source ./.env
  set +a
fi

: "${DATABASE_URL:?DATABASE_URL must be set (export or define in .env)}"

BASE_URL=${BASE_URL:-http://localhost:4335}
UNIQUE=$(uuidgen 2>/dev/null | tr '[:upper:]' '[:lower:]' | tr -d '-' || date +%s)
EMAIL="integration_${UNIQUE}@example.com"
USERNAME="integration_${UNIQUE}"
PASSWORD="Str0ngP@ssw0rd!${RANDOM}"

USER_ID=""

cleanup() {
  if [[ -n "$USER_ID" ]]; then
    psql "$DATABASE_URL" -v ON_ERROR_STOP=1 <<SQL
DELETE FROM identity_sessions WHERE user_id = '$USER_ID'::uuid;
DELETE FROM events WHERE aggregate_type = 'identity.user' AND aggregate_id = '$USER_ID'::uuid;
SQL
  fi
}
trap cleanup EXIT

printf "Running register/login flow via Hurl...\n"
hurl \
  --variable base_url="$BASE_URL" \
  --variable email="$EMAIL" \
  --variable username="$USERNAME" \
  --variable password="$PASSWORD" \
  --variable unique="$UNIQUE" \
  tests/integration/register-login.hurl

printf "Verifying user registration in event store...\n"
USER_ID=$(psql "$DATABASE_URL" -Atv ON_ERROR_STOP=1 -c "SELECT aggregate_id::text FROM events WHERE aggregate_type = 'identity.user' AND data->'user'->>'email' = '$EMAIL' ORDER BY created_at DESC LIMIT 1;")
if [[ -z "$USER_ID" ]]; then
  echo "Failed to find registered user event for $EMAIL" >&2
  exit 1
fi
printf "  Found user id %s\n" "$USER_ID"

printf "Verifying session created after login...\n"
SESSION_COUNT=$(psql "$DATABASE_URL" -Atv ON_ERROR_STOP=1 -c "SELECT count(*) FROM identity_sessions WHERE user_id = '$USER_ID'::uuid;")
if [[ "$SESSION_COUNT" != "1" ]]; then
  echo "Expected 1 session for $USER_ID, found $SESSION_COUNT" >&2
  exit 1
fi
printf "  Session count OK (%s)\n" "$SESSION_COUNT"

printf "Integration test completed successfully.\n"
