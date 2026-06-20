# Skill: Code Review

**Type:** Skill  
**Applies To:** All  
**When to Use:** Use this checklist when performing code reviews (both for AI self-reviews and human developer code reviews) prior to merging PRs.

---

## Related Rules
- [00-INDEX.md](docs/ai-rules/00-INDEX.md) (Master index of all conventions and architectural rules)

---

## Procedural Workflow

### Step 1: Understand the Context
1. Read the Pull Request description, associated tickets, and spec updates.
2. Confirm you understand the functional goals, user flows, and affected subsystems before reviewing any file changes.

### Step 2: Verify Backend Clean Architecture (Rule 01)
Verify references and folder layouts follow [01-backend-architecture.md](docs/ai-rules/01-backend-architecture.md):
- **Layer References Check:** Ensure `Domain` and `Application` projects contain no references to concrete layers (such as `Infrastructure` or `API`).
- **Framework Ban:** Confirm no direct MediatR dependencies (`MediatR` namespace reference) or `ControllerBase` inheritances were introduced. Verify Martinothamar's `Mediator` is used instead.
- **CQRS Layout:** Ensure features are organized under `Features/{FeatureName}s/Commands/` or `Features/{FeatureName}s/Queries/` directories.

### Step 3: Verify C# Backend Coding Standards (Rule 02)
Verify implementation logic follows [02-backend-coding-standards.md](docs/ai-rules/02-backend-coding-standards.md):
- **Naming Conventions:** Verify PascalCase for classes/methods and async suffixes are used correctly.
- **Endpoint Definitions:** Ensure no `[Route]` or `[Authorize]` attributes exist. Check that routing uses Minimal API extension maps and response wrapper bridges (.ToApiResult()).
- **Validation Pipeline:** Check that commands and queries requiring validation implement `IValidateMe`, and validation logic is encapsulated in FluentValidation validator classes (no validation in handlers).
- **Response Wrapper:** Verify that all routes return wrapped payload envelopes (`ResponseWrapper<T>` / `IResponseWrapper<T>`). Check that handlers return `ValueTask<IResponseWrapper<T>>`.

### Step 4: Verify Database, Migrations & Infrastructure (Rule 03)
Verify database mappings match [03-backend-data-and-infrastructure.md](docs/ai-rules/03-backend-data-and-infrastructure.md):
- **EF Configurations:** Ensure entity mappings are defined in separate configuration classes. Concurrency tokens (`RowVersion`) must be mapped to type `rowversion` in SQL Server, and unique indexes must use the `UX_` prefix.
- **Context Access:** Confirm handlers use `IApplicationDbContext` for database queries (not direct `ApplicationDbContext` injections).
- **Two-Phase Transactions**: Validate that write handlers manage transactional blocks safely using `StartTransaction`, `CommitTransaction`, and `RollbackTransaction`, returning failed wrappers instead of throwing unhandled exceptions.
- **Auditing Backing Fields**: Verify `IFullEntity` implements backing properties concretely inside the entity class.

### Step 5: Verify Backend Security & Claims (Rule 04)
Verify access guards match [04-backend-security.md](docs/ai-rules/04-backend-security.md):
- **Endpoint Authorization**: Confirm routes require authorization policies (`.RequireAuthorization(AppPermission.NameFor(...))`).
- **Constants Mapping**: Check that permissions use constants defined inside [UMS.Application/Authorization/AppPermissions.cs](UMS.Application/Authorization/AppPermissions.cs).
- **Safe Storage:** Ensure uploaded files are validated and stored using `IFileStorageService`.

### Step 6: Verify React Client Architecture & Routing (Rule 05)
Verify React client components follow [05-frontend-architecture.md](docs/ai-rules/05-frontend-architecture.md):
- **State Separation:** Ensure server state uses TanStack Query, grid rendering uses TanStack Table, and local view state uses `useState`.
- **API client layering:** Confirm components NEVER invoke the base client (`api-client.ts`) directly. They must use custom hooks wrapping feature API modules.
- **Radix UI Accessibility:** Verify components use Radix primitives and provide descriptive ARIA tags.

### Step 7: Verify Frontend Coding Standards & ESLint (Rule 06)
Verify components follow [06-frontend-coding-standards.md](docs/ai-rules/06-frontend-coding-standards.md):
- **Conventions & Lints**: Check that the ESLint rules in `eslint.config.js` cover Rule 06 guidelines.
- **DatePicker & Forms**: Verify native date inputs are not used. Dates sent to APIs must be formatted as ISO `yyyy-MM-dd`.
- **Validation timing**: Form validation must run on `onBlur` or form submission, never on `onChange` keystroke.
- **Auto-slugification fallbacks**: Confirm slugs generate automatically with non-ASCII random UUID fallbacks.
- **Navigation Guard**: Ensure warnings prevent data losses on dirty forms.

### Step 8: Verify Testing Standards & Mocking (Rule 07)
Verify test coverage matches [07-testing-standards.md](docs/ai-rules/07-testing-standards.md):
- **Test Scope Isolation**: Confirm handler unit tests use dedicated SQLite test scopes and integration tests run against SQL Server test instances via `ApiTestDatabaseInitializer.cs`.
- **Co-locating Page Tests**: Page unit tests must be co-located with their target pages (e.g. `src/pages/CategoriesManagement.test.tsx` next to `CategoriesManagement.tsx`).
- **Assertions**: Assert that OutboxMessages are enqueued inside write handler tests, and verify concurrency conflict handling maps correctly.

### Step 9: Verify Project Conventions & Logging (Rule 08)
Verify styling and version sets follow [08-project-conventions.md](docs/ai-rules/08-project-conventions.md):
- **Git Commit Convention**: Check that commits are structured properly using conventional labels (e.g. `feat:`, `fix:`).
- **Api Version Sets**: Verify endpoints are mapped inside group maps using `.WithApiVersionSet(...)` or configured group prefixes.
- **Audit Logging**: Verify modifications trigger audit logging and that PII fields are sanitized.

### General Code Quality & Best Practices Checklist
- [ ] **No exception details leaked to client:** Check `catch` blocks. Do not use `Fail(ex.Message)` or return stack traces to the client.
- [ ] **No magic numbers for HTTP status codes:** Use `StatusCodes.Status400BadRequest` instead of `400`.
- [ ] **`AsNoTracking()` on read queries:** All CQRS Query handlers must use `.AsNoTracking()` to prevent EF Core change tracking overhead.
- [ ] **`CancellationToken` forwarded:** `CancellationToken` parameters must be forwarded to all async database, network, or I/O calls.
- [ ] **No `.Result` / `.Wait()` / `.GetAwaiter().GetResult()`:** Blocking on async code is strictly forbidden.
- [ ] **`using var` / `await using var`:** Ensure disposables (DbContext, streams, connections) are properly disposed using the correct `using` syntax.
- [ ] **No `Console.WriteLine` in production code:** Use `ILogger<T>` for all logging.
- [ ] **No commented-out code blocks:** Dead code should be deleted, not commented out.
- [ ] **No `// TODO` without a linked issue:** All TODO comments must reference a GitHub issue (e.g., `// TODO #123: Fix this`).
- [ ] **Nullable annotations on all public APIs:** Enable `<Nullable>enable</Nullable>` and ensure public DTOs, methods, and properties have proper `?` or null-forgiving annotations.
- [ ] **`sealed` on internal handlers/classes:** Apply `sealed` to handler classes and internal services where inheritance is not intended to improve runtime performance.
- [ ] **`const` vs `static readonly` used correctly:** Use `const` for compile-time constants (strings, numbers) and `static readonly` for runtime evaluated constants.
- [ ] **No `async void` (except event handlers):** Use `async Task` instead.
- [ ] **No `Task.Run` in async methods:** Do not use `Task.Run` to wrap synchronous code in server-side ASP.NET Core handlers; use `ValueTask` or offload properly if strictly required.
- [ ] **EF Core: no `.Include()` in query handlers:** Read handlers must use LINQ projections (`.Select(...)`). `.Include()` is banned in Query handlers.
- [ ] **EF Core: no `AsQueryable()` over in-memory collections:** Do not mix in-memory LINQ with EF Core queryables.
- [ ] **Validation: `IValidateMe` on commands/queries needing validation:** Ensure the marker interface is present so the pipeline behavior executes.
- [ ] **Permissions: `.RequireAuthorization(...)` on all mutating endpoints:** Ensure all Create/Update/Delete endpoints have authorization policies applied.
- [ ] **Audit: mutation triggers audit interceptor:** Do not write manual audit logs in handlers; rely on the `SaveChangesAsync` interceptor.
- [ ] **Outbox: `AddOutboxMessage` called for all mutations:** Ensure domain events are enqueued in the outbox table within the same transaction.
- [ ] **Cache: invalidation in command handler:** Cache invalidation (`_cacheService.Remove`) must happen in the Command Handler, NOT in the notification event handler.
- [ ] **Transaction: two-phase save when outbox needs generated ID:** Ensure `StartTransaction` -> `SaveChanges` (get ID) -> `AddOutboxMessage` -> `SaveChanges` -> `CommitTransaction` sequence is followed.
- [ ] **Concurrency: `SetOriginalRowVersion` before update:** Ensure this is called before saving updates, and `DbUpdateConcurrencyException` is caught and mapped to 409.
- [ ] **Response: `.ToApiResult()` on all endpoints:** Verify all Minimal API endpoints bridge the wrapper using `.ToApiResult()`.
- [ ] **OpenAPI: `.WithName()` + `.Produces<IResponseWrapper<T>>()` on all endpoints:** Ensure endpoints have metadata for Swagger/Scalar generation.

---

## Expected Outcome (Definition of Done)
- Pull Request audited against steps 2 to 9 checklists.
- Feedback generated detailing rule violations.
- Code conforms to all guidelines.

---

## Troubleshooting & Resolution
- **If violations are identified:** Do not bypass constraints. Flag the specific lines and detail the corresponding rules.
- **Re-Review Process:** After updates are committed, run through the verification checks again to ensure no regressions are introduced.
