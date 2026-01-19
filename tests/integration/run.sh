#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
REPO_ROOT=$(cd "$ROOT_DIR/.." && pwd)
TEST_DIR="$ROOT_DIR/integration"

cd "$REPO_ROOT"

# Load environment (for other configs, not DATABASE_URL)
if [[ -f .env ]]; then
  set -a
  source ./.env
  set +a
fi

BASE_URL=${BASE_URL:-http://localhost:4335}
USE_TESTCONTAINERS=${USE_TESTCONTAINERS:-1}

# Check prerequisites
if ! command -v hurl &> /dev/null; then
  echo "Error: hurl is not installed" >&2
  echo "Install it with:" >&2
  echo "  macOS:   brew install hurl" >&2
  echo "  Linux:   See https://hurl.dev/docs/installation.html" >&2
  exit 1
fi

# Parse arguments
TEST_PATTERN="${1:-*.hurl}"
VERBOSE="${VERBOSE:-0}"

# Generate unique test credentials
UNIQUE=$(uuidgen 2>/dev/null | tr '[:upper:]' '[:lower:]' | tr -d '-' || date +%s)
EMAIL="test_${UNIQUE}@example.com"
USERNAME="test_${UNIQUE}"
PASSWORD="Str0ngP@ssw0rd!${RANDOM}"

# Container management
CONTAINER_SETUP_PID=""
CONTAINER_ID=""

cleanup() {
  if [[ -n "$CONTAINER_SETUP_PID" ]]; then
    kill $CONTAINER_SETUP_PID 2>/dev/null || true
    wait $CONTAINER_SETUP_PID 2>/dev/null || true
  fi

  if [[ -n "$CONTAINER_ID" ]]; then
    printf "\nStopping test container...\n"
    docker stop "$CONTAINER_ID" >/dev/null 2>&1 || true
    docker rm "$CONTAINER_ID" >/dev/null 2>&1 || true
  fi
}

trap cleanup EXIT

# Setup test database
if [[ "$USE_TESTCONTAINERS" == "1" ]]; then
  if ! command -v docker &> /dev/null; then
    echo "Error: Docker is required for testcontainers but not found" >&2
    echo "Either install Docker or set USE_TESTCONTAINERS=0 to use existing DATABASE_URL" >&2
    exit 1
  fi

  printf "Setting up test database with testcontainers...\n"
  printf "This may take a few seconds...\n\n"

  # Run the setup script with KEEP_CONTAINER=1 in background
  KEEP_CONTAINER=1 npx tsx tests/integration/setup-test-db.ts > /tmp/testcontainer-setup-$$.log 2>&1 &
  CONTAINER_SETUP_PID=$!

  # Wait for the READY marker to appear in the log
  printf "Waiting for container to start"
  for i in {1..60}; do
    if grep -q "^READY$" /tmp/testcontainer-setup-$$.log 2>/dev/null; then
      printf " done\n"
      break
    fi
    if ! kill -0 $CONTAINER_SETUP_PID 2>/dev/null; then
      printf " failed\n"
      echo "Container setup process died unexpectedly:" >&2
      cat /tmp/testcontainer-setup-$$.log >&2
      exit 1
    fi
    printf "."
    sleep 1
    if [[ $i -eq 60 ]]; then
      printf " timeout\n"
      echo "Container failed to start within 60 seconds" >&2
      cat /tmp/testcontainer-setup-$$.log >&2
      exit 1
    fi
  done

  # Extract connection string and container ID
  export DATABASE_URL=$(grep "^CONNECTION_STRING=" /tmp/testcontainer-setup-$$.log | cut -d= -f2-)
  CONTAINER_ID=$(docker ps --filter ancestor=postgres:17-alpine --format "{{.ID}}" | head -1)

  if [[ -z "$DATABASE_URL" ]]; then
    echo "Failed to extract DATABASE_URL from test setup" >&2
    cat /tmp/testcontainer-setup-$$.log >&2
    exit 1
  fi

  printf "✓ Test database ready\n"
  [[ "$VERBOSE" == "1" ]] && printf "  Container ID: %s\n  Database URL: %s\n" "$CONTAINER_ID" "$DATABASE_URL"

  rm -f /tmp/testcontainer-setup-$$.log
else
  # Use existing DATABASE_URL from environment
  : "${DATABASE_URL:?DATABASE_URL must be set when USE_TESTCONTAINERS=0}"
  printf "Using existing database\n"
  [[ "$VERBOSE" == "1" ]] && printf "  Database URL: %s\n" "$DATABASE_URL"
fi

# Check if server is running
if ! curl -s "$BASE_URL" > /dev/null 2>&1; then
  echo "Error: Application server is not running at $BASE_URL" >&2
  echo "Please start the server first:" >&2
  echo "  npm run dev" >&2
  echo "" >&2
  echo "Or set BASE_URL to point to a running server" >&2
  exit 1
fi
printf "✓ Application server is running\n"

# Run test file with Hurl
run_hurl_test() {
  local test_file="$1"
  local test_name=$(basename "$test_file" .hurl)

  printf "\n═══════════════════════════════════════════════════════════\n"
  printf "Running test: %s\n" "$test_name"
  printf "═══════════════════════════════════════════════════════════\n\n"

  # Generate unique credentials for this specific test
  local test_unique=$(uuidgen 2>/dev/null | tr '[:upper:]' '[:lower:]' | tr -d '-' || echo "${UNIQUE}_$(date +%N)")
  local test_email="test_${test_unique}@example.com"
  local test_username="test_${test_unique}"
  local test_password="Str0ngP@ssw0rd!${RANDOM}"

  local hurl_args=(
    --variable base_url="$BASE_URL"
    --variable email="$test_email"
    --variable username="$test_username"
    --variable password="$test_password"
    --variable unique="$test_unique"
  )

  if [[ "$VERBOSE" == "1" ]]; then
    hurl_args+=(--verbose)
  fi

  if ! hurl "${hurl_args[@]}" "$test_file"; then
    printf "\n✗ Test '%s' failed\n" "$test_name"
    return 1
  fi

  printf "\n✓ Test '%s' completed successfully\n" "$test_name"
}

# Find and run tests
printf "\nIntegration Test Runner\n"
printf "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
printf "Base URL: %s\n" "$BASE_URL"
printf "Test Pattern: %s\n" "$TEST_PATTERN"
printf "Testcontainers: %s\n" "$USE_TESTCONTAINERS"
printf "Unique ID: %s\n" "$UNIQUE"
printf "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"

TEST_FILES=()
while IFS= read -r -d '' file; do
  TEST_FILES+=("$file")
done < <(find "$TEST_DIR" -name "$TEST_PATTERN" -type f -print0 | sort -z)

if [[ ${#TEST_FILES[@]} -eq 0 ]]; then
  echo "No test files found matching pattern: $TEST_PATTERN" >&2
  exit 1
fi

FAILED_TESTS=()
for test_file in "${TEST_FILES[@]}"; do
  if ! run_hurl_test "$test_file"; then
    FAILED_TESTS+=("$(basename "$test_file")")
  fi
done

printf "\n═══════════════════════════════════════════════════════════\n"
printf "Test Summary\n"
printf "═══════════════════════════════════════════════════════════\n"
printf "Total tests: %d\n" "${#TEST_FILES[@]}"
printf "Passed: %d\n" "$((${#TEST_FILES[@]} - ${#FAILED_TESTS[@]}))"
printf "Failed: %d\n" "${#FAILED_TESTS[@]}"

if [[ ${#FAILED_TESTS[@]} -gt 0 ]]; then
  printf "\nFailed tests:\n"
  for test in "${FAILED_TESTS[@]}"; do
    printf "  - %s\n" "$test"
  done
  exit 1
fi

printf "\n✓ All tests passed!\n"
