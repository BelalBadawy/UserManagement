# UMS Test Coverage Audit

Audit date: 2026-04-25

## Maintained test surface

The maintained test projects are:

- `UMS.Domain.Tests`
- `UMS.Application.Tests`
- `UMS.Infrastructure.Tests`
- `UMS.API.Tests`

`UMS.Tests` has been removed from the maintained repository surface and is no longer counted as active coverage.

## Current verified test counts

The latest successful `dotnet test UMSSolution.slnx` run executed:

- `UMS.Domain.Tests`: 3 tests
- `UMS.Application.Tests`: 170 tests
- `UMS.Infrastructure.Tests`: 126 tests
- `UMS.API.Tests`: 77 tests

Total maintained tests: 376

## Areas covered now

### Domain

- Category entity behavior and helper support through the maintained domain builders and entity tests.

### Application

- Full handler coverage for all user, role, category, and token command/query handlers.
- Validator coverage for all command and query validators across every feature area.
- Validation pipeline regression coverage, including mixed-pass/mixed-fail behavior.
- Validation-participation coverage for `UpdateUserRolesCommand` and `GetRefreshTokenQuery`.
- Handler tests for 7 new commands: `ConfirmEmail`, `ConfirmEmailChange`, `ResendConfirmationEmail`, `GenerateChangeEmailToken`, `GenerateNew2FARecoveryCodes`, `LockUser`, `UnlockUser`.
- Validator tests for 6 new validators covering all rule branches (zero ID, empty/invalid email, empty token).

### Infrastructure

- `CurrentUserService`: all public methods including `SetCurrentUser`, `HasRole`, `HasClaim`, role/claim enumeration.
- `DateTimeService`: `NowUtc` kind and accuracy.
- `DistributedCacheService`: get hit/miss paths, serialized set with sliding expiration, remove.
- `InMemorySessionWrapper`: get absent/present (deserialized), set null (skipped) / non-null (serialized), remove.
- `TokenService`: `GetTokenAsync` full branch coverage (not found, inactive, unconfirmed email, bad password, locked out, success with claim/role/expiry assertions, refresh token rotation); `GetRefreshTokenAsync` full branch coverage (not found, mismatch, expired, success with rotation).
- `UserService`: all 18 public methods including register (AutoConfirmEmail=true/false), confirm email (idempotent + invalid token + success), confirm email change, resend confirmation email, generate change email token, generate 2FA recovery codes, lock/unlock user, forgot/reset password, change password, change status, update roles, all user query methods.
- `RoleService`: create, delete, get-by-id, get all (paged), get permissions, update permissions (role-not-found, admin guard, no-op, add-claim, remove-claim).

### API

- Focused API host/contract tests in `UMS.API.Tests`.
- Endpoint smoke coverage for account, category, role, and user flows in `UMS.API.Tests/Endpoints`.
- Authentication handler and test data seeding infrastructure for integration tests.
- New account endpoints: `confirm-email` (unknown user, valid token flow), `confirm-email-change` (unknown user, invalid token), `resend-confirmation-email` (unknown/already-confirmed/unconfirmed).
- New user endpoints: `generate-change-email-token` (anonymous 401, auth error), `generate-2fa-recovery-codes` (anonymous 401, auth error), `lock-user` (auth matrix), `unlock-user` (auth matrix).

## Gaps still worth prioritizing

- Persistence interceptor and audit-log behavior (save-changes side effects).
- Seeder behavior (`ApplicationDbContextInitializer`).
- File storage service cancellation and error paths.
- Mail sender SSL configuration edge cases.

## Quality notes

- Placeholder `UnitTest1.cs` files were removed from the maintained test projects.
- The legacy catch-all `UMS.Tests` project is no longer part of the active repo test structure.
- The former `UMS.IntegrationTests` coverage now lives in `UMS.API.Tests/Endpoints`, and `UMSSolution.slnx` no longer references a separate integration test project.
- `RoleServiceTests` connects to the pre-existing `UMSDbTest` SQL Server database (no `Migrate()` call; assumes the schema is already applied).
- `ApiTestDatabaseInitializer` uses `EnsureDeletedAsync` + `MigrateAsync` — the test database is recreated from scratch on every test run.
