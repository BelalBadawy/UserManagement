# UMS Project Conventions

**Type:** Rule  
**Applies To:** All  
**When to Use:** Apply during version control commits, adding features, modifying public APIs, integrating audit logging, or optimizing queries.

---

## 1. Git and Branching Conventions

- **Conventional Commits:** Commit messages must strictly follow the Conventional Commits specifications:
  - `feat:` for introducing new features or capabilities.
  - `fix:` for code bug fixes.
  - `chore:` for updating build configurations, dependencies, or metadata.
  - `refactor:` for code restructuring that doesn't alter logic.
  - `test:` for introducing or correcting tests.
  - `docs:` for updating project documentation files.
- **Pull Requests:** Commits directly to the `main` or `master` branches are forbidden. All modifications must be submitted via Pull Requests.
- **Reference Issues:** Pull request titles or descriptions must explicitly reference their tracking issue (e.g. `fixes #123`).

---

## 2. API Versioning

- **Version Routes:** Minimal API endpoints must be mapped using the version path variable convention:
  `api/v{version:apiVersion}/[endpoint-name]`
- **Declaring Versions:** Group mappings must configure api version sets using `.WithApiVersionSet(...)` or map to specific default version endpoints.
- **Breaking Changes:** Breaking modifications (e.g., property removals, path changes, type changes) require mapping a new API version (e.g., from `/v1/` to `/v2/`) to ensure backward compatibility.

---

## 3. OpenAPI Documentation (Scalar)

- **Metadata Annotations:** Every public endpoint must specify metadata options for OpenAPI generation:
  - `.WithName("EndpointName")`
  - `.Produces<IResponseWrapper<T>>()` (explicitly declare all return schemas).
  - Explicit summaries and parameter details must be mapped for complex endpoints.
- **Scalar Integration:** Ensure that any newly created routes show up properly and can be tested on the Scalar API reference interface (`/scalar/v1`) in the local development environment.

---

## 4. Audit Trail Requirements

- **Log Mutations:** All database insert, update, or delete mutations affecting users, roles, and categories must write record entries to the audit logs using the audit service.
- **Selective Logging:** Never write audit log entries for read-only query operations (e.g. GET).
- **Outbox Pattern:** Enforce the outbox pattern to save events (e.g., `CategoryCreatedEvent`) in the same transaction as the database operation, ensuring eventual consistency.

---

## 5. Code Performance Conventions

- **No N+1 Queries:** Database operations must use EF Core query projections `.Select(x => new Dto(...))` to load related records in a single database transaction. Avoid calling `.Include` followed by loops.
- **Required Pagination:** All list endpoints (e.g. `/users`, `/categories/paged`) must accept paging filters (`pageNumber`, `pageSize`) and return wrapped records matching the `PagedResult<T>` structure.
- **Standard Exports:** All paged list endpoints must have a corresponding `/export` endpoint that accepts the same filter parameters (ignoring pagination limits) and returns a binary file via `Results.File()`.
- **Asynchronous Stack:** All execution paths must run asynchronously (e.g., utilizing `ValueTask` or `Task`) to prevent blocking execution threads on I/O.
- **Reference Data Caching:** Use `ICacheService` to cache and retrieve read-heavy, low-frequency data (such as product categories or roles lookup catalogs). Caches must be updated or invalidated on mutations.
