# Architecture & Code Structure Notes

## Cross-cutting Principles
- **Bounded contexts** live under `src/contexts/<name>` and follow Domain-Driven Design. Each context owns its domain types, application workflows (ports), infrastructure adapters, and web controllers/resources.
- Modules must have unique file names (e.g. `IdDomain.res`, `PmDomain.res`) to avoid duplicate generated JavaScript modules. When sharing the name `Domain` between contexts, rename files and update open/alias statements.
- Favour pure domain modules for types and business logic. Keep side-effecting concerns (hashing, persistence, IO) in application or infrastructure layers.

## Layering Pattern (Ports & Adapters)
- **Domain layer (`domain/`)** holds only types and pure functions. Example: `IdDomain.res` defines identity aggregates, and `Register.res` implements pure registration logic without infrastructure dependencies.
- **Application layer (`application/`)** exposes use-case workflows. These modules accept explicit dependencies (e.g. hashing) and coordinate domain functions. They often return `Promise` when infrastructure dependencies are async (`RegisterWithPassword.res`).
- **Web layer (`web/`)** adapts HTTP requests/responses to application commands. Controllers parse/validate JSON, call application workflows, and encode responses (`RegisterUserController.res`). Resources define request/response DTOs & encoders.
- **Infrastructure layer (`infrastructure/`)** provides concrete implementations for external services (e.g. Argon2 password hashing in `PasswordHasher.res`). Application-layer dependencies import these modules when wiring controllers.

## Dependency Injection Guidelines
- Inject dependencies only for operations that touch infrastructure or external systems (hashing, persistence, clocks when deterministic behaviour is required). Pure value creation stays inside domain services.
- Prefer clarity to over-injection: domain services can call `RescriptCore.Date.now()` or `UUIDv7.gen()` directly when no deterministic testing requirements exist.

## Async Workflow Conventions
- When an injected dependency returns a `Promise` (e.g. Argon2 hashing), application workflows lift their return type to `Promise.t<result<_,_>>`. Controllers use `Promise.thenResolve` and `Promise.catch` for flow control.

## JSON Handling & Validation
- Controllers use `RescriptCore.Dict` + `RescriptCore.JSON.Decode` to parse bodies. Keep validation helpers separate (e.g. `UserResource.sanitizeRegistrationRequest`) to reuse across controllers/tests.
- Surface domain/application errors as user-facing messages via resource encoders.

## Naming Conventions
- Use noun-based resource modules (`UserResource`) instead of verb-based ones. Controllers are named after the action (`RegisterUserController`), and export both ReScript and `@genType` JS bindings (`postJs`, `defaultDependenciesJs`).
- Maintain alignment between module aliases (e.g. `module D = IdDomain`) and renamed files to keep references clear after refactors.
