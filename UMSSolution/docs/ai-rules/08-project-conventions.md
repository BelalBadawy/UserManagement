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
- **Deprecation Policy:** When a new API version (e.g., v2) is introduced, the previous version (v1) must be maintained for at least 6 months or 2 release cycles, and marked as deprecated in OpenAPI metadata via `.WithOpenApi()`.

---

## 3. OpenAPI Documentation (Scalar)

- **Metadata Annotations:** Every public endpoint must specify metadata options for OpenAPI generation:
  - `.WithName("EndpointName")`
  - `.Produces<IResponseWrapper<T>>()` (explicitly declare all return schemas).
  - Explicit summaries and parameter details must be mapped for complex endpoints.
- **Scalar Integration:** Ensure that any newly created routes show up properly and can be tested on the Scalar API reference interface (`/scalar/v1`) in the local development environment.

---

## 4. Audit Trail Requirements

- **Selective Logging:** Never write audit log entries for read-only query operations (e.g. GET).
- **Outbox Pattern & Two-Phase Saves:** Enforce the outbox pattern to save events in the same transaction as the database operation, ensuring eventual consistency. Follow the Transaction-Wrapped Two-Phase Save pattern defined in [01-backend-architecture.md](01-backend-architecture.md#5-domain-events-and-the-outbox-pattern) §5.
- **RULE: DbContext Auditing Interceptors:** Database mutations must be intercepted automatically inside `ApplicationDbContext.SaveChangesAsync`:
  - **Auditable Fields:** For entities implementing `IAuditable`, automatically set audit properties (`CreatedAt`, `CreatedBy`, `LastModifiedAt`, `LastModifiedBy`) using injected `ICurrentUserService` and `IDateTimeService`.
  - **Soft Delete Conversion:** For entities implementing `ISoftDelete`, intercept `EntityState.Deleted` states, switch them to `EntityState.Modified`, and set soft-delete flags (`SoftDeleted = true`, `DeletedAt`, `DeletedBy`).
  - **Configuration Guard:** Auditing must check the configuration setting `"EnableAuditLog"`. If false, bypass audit logging and execute saving immediately.
  - **Two-Phase Saving for Database-Generated Keys:** To capture database-generated primary keys for new entities:
    1. During `OnBeforeSaveChanges`, extract modified entity states and capture primary keys or non-temporary properties. Determine the audit type: `Create` for added, `Delete` for hard-deleted or soft-deleted (when `SoftDeleted` transitions from `false` to `true`), and `Update` for modified.
    2. Write audit records without temporary properties directly to `AuditTrails`. Return entries containing temporary properties.
    3. Save changes first to generate database identity keys.
    4. During `OnAfterSaveChanges`, update keys and values for temporary properties, write the remaining audit records to `AuditTrails`, and save changes again.

---

## 5. Code Performance Conventions

- **RULE: Split N+1 Queries Strategy:**
  - **Read Queries (CQRS Query Handlers):** MUST use LINQ projections `.Select(x => new Dto(...))` to shape data at the database level. NEVER use `.Include()` followed by in-memory mapping in query handlers — this causes N+1 queries and loads unnecessary data.
  - **Write Operations (CQRS Command Handlers):** MAY use `.Include()` to load aggregate roots with their children when the write logic needs to inspect or mutate child collections. After loading, perform mutations on the tracked graph and call `SaveChangesAsync()`. NEVER load navigation properties you don't need just to "be safe."
- **Required Pagination:** All list endpoints (e.g. `/users`, `/categories/paged`) must accept paging filters (`pageNumber`, `pageSize`) and return wrapped records matching the `PagedResult<T>` structure.
- **Export Endpoints:** All user-facing administrative list endpoints (e.g., Users, Categories, Audit Trails) SHOULD include a corresponding /export endpoint accepting the same filter parameters (ignoring pagination). Exports exceeding 10,000 records must be processed asynchronously via a background job, returning a download link upon completion. Small exports may use synchronous `Results.File()`. Internal or configuration entities may omit export endpoints with documented justification.
- **Asynchronous Stack:** All execution paths must run asynchronously (e.g., utilizing `ValueTask` or `Task`) to prevent blocking execution threads on I/O.
- **Reference Data Caching:** Use `ICacheService` to cache and retrieve read-heavy, low-frequency data (such as product categories or roles lookup catalogs). Caches must be updated or invalidated on mutations.

---

## 6. Observability & Health Checks

- The API must expose `/health` and `/health/ready` endpoints using `builder.Services.AddHealthChecks()`.
- Register health checks for critical dependencies (SQL Server, Redis/Cache).
