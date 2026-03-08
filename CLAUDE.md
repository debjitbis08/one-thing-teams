# CLAUDE.md

## Before You Start

Read the `docs/` folder before making changes:
- `docs/OneThing_for_Teams_Playbook.pdf` — product vision, methodology, and domain language
- `docs/architecture-learnings.md` — architecture patterns, layering, and conventions
- `docs/OneThing for Teams ER Diagram.png` — entity relationships

## Project Overview

OneThing for Teams is an event-sourced product management tool built with ReScript (domain/application/web layers) and TypeScript (infrastructure/API routes), served by Astro.

## Tech Stack

- **Domain logic**: ReScript (`.res` files) — types, validation, business rules
- **Infrastructure**: TypeScript — event store, aggregate loaders, bridges, DB access
- **Framework**: Astro (SSR) with API routes under `src/pages/api/`
- **Database**: PostgreSQL with event sourcing (events + snapshots tables via Drizzle ORM)
- **Testing**: Node.js built-in test runner (unit), Hurl (integration)

## Project Structure

```
src/
  contexts/
    common/domain/        # Shared value objects (Email, FibonacciScale, ShortCode, etc.)
    foundation/domain/    # ValueObject base, GlobalUniqueId
    id/                   # Identity context (auth, orgs, invitations)
      domain/model/       # IdDomain types
      application/        # Use cases (Register, Login, RenameOrg, etc.)
      web/                # HTTP controllers
      infrastructure/     # Event stores, aggregate loaders, bridges
    pm/                   # Product Management context
      domain/model/       # PmDomain types, Initiative, Product, InitiativeScore
      application/        # Use cases (CreateInitiative, CreateProduct, ScoreInitiative)
      web/                # HTTP controllers
      infrastructure/     # Event stores, aggregate loaders, bridges
  infrastructure/db/      # EventRepository, schema, DB client
  pages/api/              # Astro API routes
tests/
  unit/                   # ReScript unit tests (*.res -> *.bs.mjs)
  integration/            # Hurl integration tests (*.hurl)
```

## Architecture Patterns

### Event Sourcing Flow
Every write follows: **Controller** (.res) -> **Application** (.res) -> **EventStore** (.ts)

- Controllers parse HTTP requests, build commands, call application `execute()`
- Application layers validate, load aggregates, append events with optimistic concurrency
- Bridges (`.ts`) wire concrete dependencies (event stores, aggregate loaders, clocks)
- Event stores persist to the `events` table via `EventRepository`

### Naming
- Event types follow: `{context}.{aggregate}.{action}` (e.g., `pm.initiative.scored`)
- Aggregate types: `pm.initiative`, `pm.product`, `identity.organization`
- Controllers export a `@genType` function (e.g., `putJs`, `postJs`, `patchJs`)

### ReScript Conventions
- File names must be globally unique (ReScript flat module namespace)
- Domain types live in `PmDomain.res` / `IdDomain.res`
- Use `@genType` on types and functions that cross the ReScript/TypeScript boundary
- Pure domain logic; side effects only in application/infrastructure layers

## Commands

```sh
pnpm res:build          # Build ReScript
pnpm res:watch          # Watch mode for ReScript
pnpm dev                # Dev server (ReScript watch + Astro dev on port 4335)
pnpm build              # Production build
pnpm test:unit          # Run unit tests
pnpm test:int           # Run integration tests (requires Docker for testcontainers)
pnpm test:int -- <pattern>.hurl  # Run a specific integration test
```

## Guidelines

- Always run `pnpm res:build` after changing `.res` files to verify compilation
- Run `pnpm test:unit` after domain/application changes
- Run `pnpm test:int` after adding or modifying API endpoints
- Keep domain logic pure — no IO, no side effects in `domain/` modules
- Inject dependencies for infrastructure concerns (persistence, hashing, clocks)
- Use optimistic concurrency (`expectedVersion`) for all update events
