# Integration Tests

These Hurl-based integration tests exercise the public HTTP API end-to-end with a **PostgreSQL test database** managed by Testcontainers.

## Philosophy

Integration tests verify the system's behavior **through the API only**. They do not:
- Query the database directly
- Make assumptions about internal implementation
- Test infrastructure concerns directly

All verification happens via API responses and assertions.

## Prerequisites

### Required
- **Docker** - Testcontainers will automatically start a PostgreSQL container
- **Node.js** and **pnpm** - For running the setup scripts
- **hurl** - HTTP testing tool (install via `brew install hurl` or see [hurl.dev](https://hurl.dev))

### Optional
- `uuidgen` - For generating unique test IDs (usually pre-installed on macOS/Linux)

## How It Works

The test runner automatically:
1. **Starts a PostgreSQL container** using Testcontainers (postgres:17-alpine)
2. **Runs migrations** to set up the test database schema
3. **Starts your app server** pointing to the test database
4. **Executes Hurl tests** against the running server
5. **Cleans up** the container and server when done

This means:
- ✅ No manual database setup required
- ✅ Tests run in complete isolation
- ✅ Exact PostgreSQL compatibility (not SQLite)
- ✅ Fast (~3-5 seconds for container startup)
- ✅ Clean state for every test run

## Running Tests

### Run All Tests (Default - with Testcontainers)

```bash
./tests/integration/run.sh
```

### Run Specific Test

```bash
./tests/integration/run.sh register-login.hurl
```

### Run Tests Matching Pattern

```bash
./tests/integration/run.sh "rename-*.hurl"
```

### Verbose Mode

```bash
VERBOSE=1 ./tests/integration/run.sh
```

### Use Existing Database (Skip Testcontainers)

If you prefer to use your existing PostgreSQL database:

```bash
USE_TESTCONTAINERS=0 DATABASE_URL="postgresql://..." ./tests/integration/run.sh
```

## Configuration

Environment variables:

- `USE_TESTCONTAINERS` - Use testcontainers for database (default: `1`)
- `BASE_URL` - Override the default target host (default: `http://localhost:4335`)
- `VERBOSE` - Enable verbose output (default: `0`)
- `DATABASE_URL` - Required only when `USE_TESTCONTAINERS=0`

Examples:

```bash
# Use custom base URL
BASE_URL=http://localhost:8080 ./tests/integration/run.sh

# Verbose mode with testcontainers
VERBOSE=1 ./tests/integration/run.sh

# Use existing database
USE_TESTCONTAINERS=0 DATABASE_URL="postgresql://localhost/testdb" ./tests/integration/run.sh
```

## Available Tests

### `register-login.hurl`

Tests user registration and login flow:
1. Register a new user with initial organization
2. Login with credentials
3. Verify session tokens and user data in response

### `rename-organization.hurl`

Tests organization rename functionality:
1. Register a new user with initial organization
2. Login to get session credentials
3. Rename the organization via PATCH endpoint
4. Verify rename by logging in again and checking organization name

## Writing New Tests

1. Create a new `.hurl` file in `tests/integration/`
2. Use Hurl's assertion syntax to verify API responses
3. The test runner will automatically discover and run it

Example:

```hurl
POST {{base_url}}/api/register
Content-Type: application/json

{
  "email": "{{email}}",
  "password": "{{password}}"
}

HTTP/1.1 201
[Asserts]
jsonpath "$.userId" exists
jsonpath "$.email" == "{{email}}"
```

Available variables:
- `{{base_url}}` - API base URL
- `{{email}}` - Unique test email
- `{{username}}` - Unique test username
- `{{password}}` - Generated secure password
- `{{unique}}` - Unique test identifier

## Troubleshooting

### Docker not found

```
Error: Docker is required for testcontainers but not found
```

**Solution:** Install Docker Desktop or Docker Engine, or use `USE_TESTCONTAINERS=0` with an existing database.

### Container startup timeout

```
Failed to start test database
```

**Solution:**
- Ensure Docker is running
- Check Docker has enough resources (2GB+ RAM recommended)
- Try pulling the image manually: `docker pull postgres:17-alpine`

### Port conflicts

If port 5432 is already in use, Testcontainers will automatically assign a random available port.

### Tests timing out

The server startup has a 30-second timeout. If tests still fail:
- Check if the server starts successfully with `npm run dev`
- Verify `SESSION_JWT_SECRET` is set in `.env`
- Check application logs for errors

## CI/CD Integration

For CI environments (GitHub Actions, GitLab CI, etc.):

```yaml
# GitHub Actions example
- name: Run integration tests
  run: ./tests/integration/run.sh
  env:
    SESSION_JWT_SECRET: ${{ secrets.SESSION_JWT_SECRET }}
```

Testcontainers works automatically in CI environments that have Docker available.
