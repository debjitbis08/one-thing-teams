# Integration Tests

These Hurl-based integration tests exercise the public HTTP API.

## Prerequisites

- The app server must be running locally (defaults to `http://127.0.0.1:8080`).
- `hurl`, `psql`, and `uuidgen` should be available on your `PATH`.
- Set `DATABASE_URL` (exported or in `.env`) and `SESSION_JWT_SECRET`.

## Running the register/login flow

```bash
./tests/integration/run.sh
```

The script will:

1. Generate unique credentials.
2. Call `tests/integration/register-login.hurl` (register → login).
3. Verify the user registration event and session rows in Postgres.
4. Clean up the created rows, even on failure.

Use `BASE_URL` to override the default target host when needed.
