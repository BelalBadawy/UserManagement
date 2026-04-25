# API Testing Rules

Use these rules when working in `UMS.API.Tests`.

## Host and Database

- Use `WebApplicationFactory<Program>` with environment `Testing`.
- Keep `UMS.API/appsettings.Testing.json` committed and tracked.
- Use `ConnectionStrings:TestConnection` as the test database source of truth.
- Set `DbProvider` to `SqlServer`.
- Set `EnableAuditLog` to `false`.
- Explicitly disable other side effects in `appsettings.Testing.json`.
- Use a real SQL Server test database, not the in-memory provider.
- Recreate the test database, apply migrations, and apply only the dedicated baseline seed once per process.
- Delete the old test database at the start of the next run, not at the end of the current one.
- Attach one-time initialization to `CustomWebApplicationFactory` with a static guard.
- Fail fast with a clear setup message if SQL Server is unavailable. Mention `TestConnection` and `appsettings.Testing.json`.

## Baseline Seed

- Seed `Admin` and `Basic` roles only.
- Seed role-claim links for every permission in `AppPermissions.AllPermissions`.
- Do not run the application's normal seeders in API tests.

## Auth Model

- Reuse shared clients/helpers for anonymous, low-privilege, and privileged requests.
- Bypass real authentication while still executing real authorization policies.
- Derive required permissions from production `AppPermission.NameFor(...)` calls through a shared helper.
- Pick a wrong permission dynamically from real production permissions and fail fast if none exists.
- Reuse one wrong-permission selection strategy across the suite.
- Include `NameIdentifier`, `Email`, `Name`, `Role`, and the exact required permission claim in the privileged principal.

## Endpoint Assertions

- Use one `[Theory]` per protected endpoint after the endpoint is unblocked.
- Cover exactly these three rows:
- `Anonymous -> 401 Unauthorized`
- `AuthenticatedWithUnrelatedPermission -> 403 Forbidden`
- `AuthenticatedWithExactRequiredPermission -> exact expected success status`
- Never assert a generic `2xx` success for protected endpoint theories.
- Seed endpoint-specific data directly through `ApplicationDbContext` in Arrange.
- Keep baseline constraints in helpers and inline the test-specific values.
- Follow the `Shape + State` rule: assert response shape and persisted state first, then add empty-state coverage if useful.
- Do not accept tests that only assert `200 OK` and an empty array.

## Verification

- Prefer a follow-up GET endpoint when it exposes the data needed to verify a mutation.
- Use direct DB verification when no GET endpoint exists or the projection hides the exact changed fields.
- Keep reusable verification helpers under `UMS.API.Tests/Support`.
- Prefer higher-level helper methods such as `GetCategoryByIdAsync` or `GetRoleByIdAsync`.

## Current Prerequisites and Blockers

- Complete `T0.2` and `T0.3` before starting protected endpoint coverage that depends on shared API test infrastructure.
- Treat category paged endpoint work as blocked until `B.1` is fixed in production and `B.2` placeholder coverage exists.
