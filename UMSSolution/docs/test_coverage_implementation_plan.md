# UMS Test Coverage Implementation Plan

## Goal

Close the active, high-value test coverage gaps across the maintained solution surface only:

- `UMS.API` -> `UMS.API.Tests`
- `UMS.Application` -> `UMS.Application.Tests`
- `UMS.Infrastructure` -> `UMS.Infrastructure.Tests`
- `UMS.Domain` -> `UMS.Domain.Tests`

This plan is derived from `COVERAGE_AUDIT.md`. The audit file is a historical snapshot and must not be edited to track progress. Progress is tracked here through task status checkboxes.

## Global Rules

- [ ] Use `xUnit` for all new tests.
- [ ] Use `FluentAssertions` for all assertions.
- [ ] Use `Moq` only in `UMS.Application.Tests` and `UMS.Infrastructure.Tests`.
- [ ] Keep each test in strict Arrange / Act / Assert structure.
- [ ] Name tests using `MethodName_Scenario_ExpectedResult`.
- [ ] Do not add placeholder assertions or empty test bodies.
- [ ] Do not add tests to deprecated or removed projects such as legacy `UMS.Tests` or `UMS.IntegrationTests`.
- [ ] Preserve `COVERAGE_AUDIT.md` as the original gap snapshot. Do not remove completed items from it.
- [ ] Track blockers in this plan only.
- [ ] Run the owning test project after each completed task group.

## API Integration Rules

- [ ] Use `WebApplicationFactory<Program>` with environment name `Testing`.
- [ ] Commit `UMS.API/appsettings.Testing.json` to the repo as a tracked file.
- [ ] Add `ConnectionStrings:TestConnection` with `Server=localhost;Database=UMSDbTest;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True;`.
- [ ] Explicitly set `DbProvider` to `SqlServer` in `appsettings.Testing.json`.
- [ ] Explicitly set `EnableAuditLog` to `false` in `appsettings.Testing.json`.
- [ ] Explicitly disable side effects in `appsettings.Testing.json`.
- [ ] Use a real SQL Server test database.
- [ ] Recreate the test database, apply migrations, and apply a minimal dedicated baseline seed once per process before the API test run starts.
- [ ] Delete the test database at the start of the next test run, not at the end of the current run.
- [ ] Attach the one-time database setup to `CustomWebApplicationFactory` with a static once-per-process guard.
- [ ] Fail fast with a clear custom setup message if SQL Server is unavailable, explicitly mentioning `TestConnection` and `appsettings.Testing.json`.
- [ ] The dedicated baseline seed must create `Admin` and `Basic` roles.
- [ ] The dedicated baseline seed must create role-claim links for all permissions in `AppPermissions.AllPermissions`.
- [ ] Do not run the application's normal seeders in API tests.
- [ ] Protected endpoint coverage must use a single `[Theory]` per endpoint after the endpoint is unblocked.
- [ ] Each protected endpoint theory must cover exactly these three rows:
- [ ] `Anonymous -> 401 Unauthorized`
- [ ] `AuthenticatedWithUnrelatedPermission -> 403 Forbidden`
- [ ] `AuthenticatedWithExactRequiredPermission -> exact expected success status`
- [ ] Never assert a generic `2xx` success outcome for protected endpoint theories; assert the exact expected success status per endpoint.
- [ ] Fake auth must bypass the real authentication handler while allowing the real authorization policies to execute.
- [ ] Provide separate reusable API test helpers/clients for anonymous, low-privilege, and privileged requests.
- [ ] The fake privileged principal must include `NameIdentifier`, `Email`, `Name`, `Role`, and the exact required permission claim.
- [ ] The fake low-privilege principal must include a real-but-wrong application permission chosen dynamically from production permissions, and must fail fast if no wrong permission exists.
- [ ] Reuse one shared wrong-permission selection strategy across the suite instead of inventing ad hoc wrong permissions per test.
- [ ] Derive required permission strings on demand from production `AppPermission.NameFor(...)` calls through a shared helper in `UMS.API.Tests/Support`.
- [ ] Seed endpoint-specific data directly through `ApplicationDbContext` in Arrange.
- [ ] Keep baseline constraint setup in helpers, but override test-specific properties inline in Arrange.
- [ ] Apply the `Shape + State` rule for API integration tests: assert response shape and seeded persisted state first, then add empty-state coverage as a secondary edge-case where useful.
- [ ] Do not accept an API integration test that only asserts `200 OK` and an empty array.
- [ ] Prefer a follow-up GET endpoint to verify persisted mutations when that endpoint exposes the needed data.
- [ ] Fall back to direct DB verification when no GET endpoint exists or when the GET projection hides the exact mutated fields.
- [ ] Use a dedicated verification helper abstraction under `UMS.API.Tests/Support`.
- [ ] Verification helpers must be higher-level methods such as `GetCategoryByIdAsync`, `GetRoleByIdAsync`, etc.
- [ ] Verification helpers may expose test seeding helpers if reuse emerges.
- [ ] Verification helpers should focus on business fields by default and expose concurrency reload only when a specific test needs it.
- [ ] Keep local per-file arrange helpers near the endpoint tests until repetition clearly emerges, then move them into a small sibling helper file in the same folder.

## Application Test Rules

- [ ] For pass-through handlers, add one test class per handler and verify dependency invocation plus returned-object passthrough only.
- [ ] Do not duplicate service behavior assertions for true pass-through handlers.
- [ ] For logical handlers, cover meaningful internal branches, state changes, and error paths.
- [ ] Use pipeline tests to prove validation filters execute.
- [ ] Use explicit validator tests to prove rule behavior.
- [ ] In validator unit tests, assert failing property/rule rather than exact message text unless the message is a strict contract.
- [ ] Treat `PropertyName` as a frontend-facing contract, but do not hardcode brittle collection indexes.

## Infrastructure Test Rules

- [ ] Achieve strict branch coverage for infrastructure services.
- [ ] Cover guard clauses, external dependency result mapping, and realistic exception handling branches.
- [ ] Use representative tests per mapping pattern unless the production code branches on specific external error codes.
- [ ] Use realistic concrete exception types from the dependency being wrapped. Do not throw generic `Exception` in mocks.
- [ ] For `TokenService`, decode generated JWTs and assert at minimum `NameIdentifier`, permission/role claims, and expiration window.
- [ ] For `UserService.ForgotPasswordAsync` and similar flows, verify that the generated security token reaches the email sender rather than asserting exact URL composition in infrastructure unit tests.
- [ ] For `RoleService.UpdateRolePermissionsAsync`, unit tests only need to verify logical claim add/remove decisions and success/failure wrappers, not real transaction semantics.

## Domain Test Rules

- [ ] Skip tests for anemic data-bag entities with no behavior for now.
- [ ] Do not write tests that only validate auto-properties on `AuditTrail`, `RefreshToken`, `LogUserActivity`, or `OutboxMessage`.
- [ ] Add domain tests only when entities encapsulate behavior or invariants worth asserting.

## Phase 0: Blockers

### Task B.1: Fix category paged endpoint `500` behavior

Status: - [x]
Description: Fix the production bug that currently causes `GET /api/v1/categories/paged` to return `500` so real integration coverage can assert the correct success behavior.
File(s): `UMS.API/Endpoints/CategoryEndpoints.cs`, relevant Application/Infrastructure query stack
Acceptance Criteria:

- [x] `GET /api/v1/categories/paged` no longer returns `500` for a valid request.
- [x] The root cause is fixed in production code, not hidden in the test suite.
- [x] Must be completed before `API.3` can start.

### Task B.2: Add skipped placeholder test for blocked category paged scenario

Status: - [x]
Description: Add a skipped placeholder `[Fact]` in the same endpoint test class as the final test will live in. The skip message must include the linked task id and a short bug summary.
File(s): `UMS.API.Tests/Endpoints/CategoryEndpointsTests.cs`
Acceptance Criteria:

- [x] The placeholder test uses skip metadata similar to `Blocker B.1: Category paged endpoint returns 500`.
- [x] The placeholder body contains a short comment describing the expected final scenario once fixed.
- [x] Must be completed before `API.3` can start.

## Phase 1: Test Platform Prerequisites

### Task T0.1: Add testing configuration files and connection wiring

Status: - [x]
Description: Add and wire `appsettings.Testing.json` so the API host can use a dedicated SQL Server test database in `Testing` environment.
File(s): `UMS.API/appsettings.json`, `UMS.API/appsettings.Testing.json`, API test host configuration files
Implementation checklist:

- [x] Add `ConnectionStrings:TestConnection` to tracked config.
- [x] Ensure the `Testing` environment loads `appsettings.Testing.json`.
- [x] Set `DbProvider` to `SqlServer` in `appsettings.Testing.json`.
- [x] Set `EnableAuditLog` to `false` in `appsettings.Testing.json`.
- [x] Explicitly disable any other needed side effects in `appsettings.Testing.json` instead of relying on implicit defaults.

Acceptance criteria:

- [x] API tests can boot the app in `Testing` environment without using the in-memory provider.
- [x] `TestConnection` is the source of truth for the API test database.

### Task T0.2: Build one-time SQL Server test database initializer

Status: - [x]
Description: Create one-time startup logic in `CustomWebApplicationFactory` that deletes the old test database, recreates it, applies migrations, and applies only the dedicated baseline seed.
File(s): `UMS.API.Tests/Fixtures/CustomWebApplicationFactory.cs`, new support files under `UMS.API.Tests/Support`
Implementation checklist:

- [x] Add a static once-per-process initialization guard in the factory.
- [x] Delete the previous `UMSDbTest` database at the start of the test run.
- [x] Recreate the database and apply migrations once.
- [x] Seed only `Admin`, `Basic`, and all permission role-claims.
- [x] Fail fast with a custom actionable message when SQL Server is unavailable.

Acceptance criteria:

- [x] API tests share one migrated test database per process.
- [x] Baseline roles and permissions exist without running full app seeders.
- [x] Must be completed before `API.1`, `API.2`, `API.3`, `API.4`, `INF.2`, `INF.3`, and `INF.4` can start.

### Task T0.3: Build reusable API auth/seeding/verification support

Status: - [x]
Description: Add shared API test support for fake auth clients, permission derivation, test-local seeding, and persisted-state verification.
File(s): `UMS.API.Tests/Support`, `UMS.API.Tests/Fixtures`
Implementation checklist:

- [x] Add anonymous, low-privilege, and privileged client helpers.
- [x] Bypass real authentication while keeping real authorization policy evaluation.
- [x] Add permission derivation helper using production `AppPermission.NameFor(...)`.
- [x] Add dynamic wrong-permission helper using a real-but-wrong production permission.
- [x] Add higher-level verification helpers such as `GetCategoryByIdAsync` and `GetRoleByIdAsync`.
- [x] Keep support helpers non-injectable from the factory scope.

Acceptance criteria:

- [x] Protected endpoint theories can reuse the same auth model across the suite.
- [x] Endpoint tests can verify persisted state without duplicating raw DB access logic.
- [x] Must be completed before `API.1`, `API.2`, `API.3`, and `API.4` can start.

## Phase 2: API Endpoint Coverage

### Task API.1: Complete `AccountEndpoints` integration coverage

Status: - [x]
Description: Extend `UMS.API.Tests/Endpoints/AccountEndpointsTests.cs` so every mapped account endpoint has integration coverage using the real SQL Server test host.
Implementation checklist:

- [x] Add coverage for `POST /api/v1/account/refresh-token`.
- [x] Add coverage for invalid refresh-token payloads.
- [x] Add coverage for `POST /api/v1/account/reset-password`.
- [x] Keep login and forgot-password tests aligned with current production behavior.
- [x] Use test-local Arrange seeding for any persisted data the scenario needs.

Acceptance criteria:

- [x] `AccountEndpoints` has at least one integration test per mapped endpoint.
- [x] Status code, wrapper shape, and meaningful response state are asserted.
- [x] `T0.2` and `T0.3` are completed before this task starts.

### Task API.2: Complete `CategoryEndpoints` read coverage

Status: - [x]
Description: Finish the category read and authorization coverage that is not blocked by the paged endpoint defect.
Implementation checklist:

- [x] Add coverage for `GET /api/v1/categories`.
- [x] Add coverage for `GET /api/v1/categories/for-list` using seeded category state.
- [x] Add coverage for `GET /api/v1/categories/{categoryId}` using seeded category state.
- [x] Add the protected endpoint theory for `POST /api/v1/categories`.
- [x] Verify exact persisted state or projected state as appropriate.
- [x] Assert the exact expected success status for the protected `POST` route, not a generic `2xx`.

Acceptance criteria:

- [x] Anonymous and protected category read/write routes are covered where not blocked.
- [x] Protected `POST` route uses the `401 / 403 / exact-success-status` theory format.
- [x] `T0.2` and `T0.3` are completed before this task starts.

### Task API.3: Complete blocked `CategoryEndpoints` mutation and paged coverage

Status: - [x]
Description: Add the remaining category endpoint coverage once the paged endpoint production bug is fixed.
Implementation checklist:

- [x] Replace the skipped paged placeholder with the final test.
- [x] Add coverage for `GET /api/v1/categories/paged`.
- [x] Add the protected endpoint theory for `PUT /api/v1/categories`.
- [x] Add the protected endpoint theory for `DELETE /api/v1/categories/{categoryId}`.
- [x] Verify exact mutated fields through DB verification when GET projections are insufficient.
- [x] Assert the exact expected success status for both protected mutation routes.

Acceptance criteria:

- [x] Every mapped category endpoint has at least one integration test.
- [x] Protected category mutation endpoints use the exact three-row theory pattern.
- [x] `B.1`, `B.2`, `T0.2`, and `T0.3` are completed before this task starts.

### Task API.4: Complete `RoleEndpoints` integration coverage

Status: - [x]
Description: Finish route coverage for `UMS.API/Endpoints/RoleEndpoints.cs`.
Implementation checklist:

- [x] Keep existing list/create/get-by-id coverage.
- [x] Add the protected endpoint theory for `PUT /api/v1/roles`.
- [x] Add the protected endpoint theory for `DELETE /api/v1/roles/{roleId}`.
- [x] Add the protected endpoint theory for `GET /api/v1/roles/permissions/{roleId}`.
- [x] Add the protected endpoint theory for `PUT /api/v1/roles/update-permissions`.
- [x] Verify persisted role/claim state using follow-up GET or DB verification helpers.
- [x] Assert the exact expected success status for each protected role route.

Acceptance criteria:

- [x] Every mapped role endpoint has at least one integration test.
- [x] Every protected role endpoint uses the exact three-row theory pattern.
- [x] `T0.2` and `T0.3` are completed before this task starts.

### Task API.5: Complete `UserEndpoints` integration coverage

Status: - [x]
Description: Finish route coverage for `UMS.API/Endpoints/UserEndpoints.cs`.
Implementation checklist:

- [x] Add the protected endpoint theory for `POST /api/v1/users/register`.
- [x] Add the protected endpoint theory for `GET /api/v1/users/paged-list`.
- [x] Add the protected endpoint theory for `PUT /api/v1/users/update`.
- [x] Add the protected endpoint theory for `PUT /api/v1/users/change-password`.
- [x] Add the protected endpoint theory for `PUT /api/v1/users/change-status`.
- [x] Add the protected endpoint theory for `PUT /api/v1/users/user-roles`.
- [x] Add the protected endpoint theory for `GET /api/v1/users/roles/{userId}`.
- [x] Keep existing get-all and get-by-id coverage.
- [x] Seed users test-locally in Arrange for every scenario that needs persisted users.
- [x] Assert the exact expected success status for each protected user route.

Acceptance criteria:

- [x] Every mapped user endpoint has at least one integration test.
- [x] Every protected user endpoint uses the exact three-row theory pattern.
- [x] `T0.2` and `T0.3` are completed before this task starts.

## Phase 3: Application Handler Coverage

### Task APP.1: Token and account-related handlers

Status: - [x]
Description: Add direct unit tests for account- and token-related Application handlers.
Implementation checklist:

- [x] Add `GetTokenQueryHandlerTests`.
- [x] Add `GetRefreshTokenQueryHandlerTests`.
- [x] Add `ForgotPasswordCommandHandlerTests`.
- [x] Add `ResetPasswordCommandHandlerTests`.
- [x] Keep one test class per handler.
- [x] For pass-through handlers, verify dependency invocation and returned-object passthrough only.

Acceptance criteria:

- [x] Each handler has a dedicated test class.
- [x] Pass-through handlers are not over-tested with duplicated service behavior.

### Task APP.2: User handlers

Status: - [x]
Description: Complete remaining user command/query handler tests.
Implementation checklist:

- [x] Add `ChangeUserPasswordCommandHandlerTests`.
- [x] Add `ChangeUserStatusCommandHandlerTests`.
- [x] Add `UpdateUserCommandHandlerTests`.
- [x] Add `UpdateUserRolesCommandHandlerTests`.
- [x] Add `GetAllUsersQueryHandlerTests`.
- [x] Add `GetUsersPagedQueryHandlerTests`.
- [x] Add `GetUserRolesQueryHandlerTests`.

Acceptance criteria:

- [x] Every user handler has a corresponding unit test class.
- [x] Logical handlers cover meaningful branches; pass-through handlers verify service delegation only.

### Task APP.3: Category handlers

Status: - [x]
Description: Add the remaining category command/query handler tests.
Implementation checklist:

- [x] Add `GetAllCategoriesQueryHandlerTests`.
- [x] Add `GetCategoriesPagedQueryHandlerTests`.
- [x] Add `GetAllCategoriesForListQueryHandlerTests`.
- [x] Add `GetCategoryByIdQueryHandlerTests`.
- [x] Add `GetCategoryByIdAdminQueryHandlerTests`.
- [x] Add `GetAllCategoriesAdminQueryHandlerTests`.
- [x] Add `GetCategoriesPagedAdminQueryHandlerTests`.
- [x] Add `CreateCategoryCommandHandlerTests`.
- [x] Add `UpdateCategoryCommandHandlerTests`.
- [x] Add `DeleteCategoryCommandHandlerTests`.
- [x] Cover cache invalidation, uniqueness, not-found, and concurrency branches where present.

Acceptance criteria:

- [x] All public category handlers have unit coverage for meaningful branches.

### Task APP.4: Role handlers

Status: - [x]
Description: Add remaining role command/query handler tests.
Implementation checklist:

- [x] Add `GetRolesQueryHandlerTests`.
- [x] Add `GetRoleByIdQueryHandlerTests`.
- [x] Add `GetPermissionsQueryHandlerTests`.
- [x] Add `CreateRoleCommandHandlerTests`.
- [x] Add `UpdateRoleCommandHandlerTests`.
- [x] Add `DeleteRoleCommandHandlerTests`.
- [x] Add `UpdateRolePermissionsCommandHandlerTests`.

Acceptance criteria:

- [x] Every public role handler has unit coverage.

## Phase 4: Application Validator Coverage

### Task APP.5: Shared and token validators

Status: - [x]
Description: Add explicit validator coverage for shared/token validation.
Implementation checklist:

- [x] Add `PagedFilterValidatorTests`.
- [x] Add `GetTokenQueryValidatorTests`.
- [x] Add direct `GetRefreshTokenQueryValidatorTests`.
- [x] Keep pipeline tests to prove filter execution separately.

Acceptance criteria:

- [x] Validator tests assert rule/property failures rather than brittle message text.
- [x] Pipeline tests and direct validator tests both exist where required.

### Task APP.6: User validators

Status: - [x]
Description: Add direct validator tests for uncovered user validators.
Implementation checklist:

- [x] Add `ForgotPasswordCommandValidatorTests`.
- [x] Add `ResetPasswordCommandValidatorTests`.
- [x] Add `ChangeUserPasswordValidatorTests`.
- [x] Add `ChangeUserStatusValidatorTests`.
- [x] Add `UpdateUserCommandValidatorTests`.
- [x] Add direct `UpdateUserRolesCommandValidatorTests`.
- [x] Add `GetUsersPagedQueryValidatorTests`.
- [x] Add `GetUserRolesQueryValidatorTests`.

Acceptance criteria:

- [x] Each user validator has direct rule coverage for valid and invalid cases.

### Task APP.7: Category validators

Status: - [x]
Description: Add direct validator tests for uncovered category validators.
Implementation checklist:

- [x] Add `CreateCategoryCommandValidatorTests`.
- [x] Add `UpdateCategoryCommandValidatorTests`.
- [x] Add `DeleteCategoryCommandValidatorTests`.
- [x] Add `GetCategoriesPagedQueryValidatorTests`.
- [x] Add `GetCategoryByIdQueryValidatorTests`.
- [x] Add `GetCategoriesPagedAdminQueryValidatorTests`.
- [x] Add `GetCategoryByIdAdminQueryValidatorTests`.

Acceptance criteria:

- [x] Every category validator has direct rule coverage.

### Task APP.8: Role validators

Status: - [x]
Description: Add direct validator tests for uncovered role validators.
Implementation checklist:

- [x] Add `CreateRoleCommandValidatorTests`.
- [x] Add `UpdateRoleCommandValidatorTests`.
- [x] Add `UpdateRolePermissionsCommandValidatorTests`.
- [x] Add `GetPermissionsQueryValidatorTests`.
- [x] Add `GetRoleByIdQueryValidatorTests`.

Acceptance criteria:

- [x] Every role validator has direct rule coverage.

## Phase 5: Infrastructure Service Coverage

### Task INF.1: Common infrastructure services

Status: - [x]
Description: Add coverage for shared infrastructure services.
Implementation checklist:

- [x] Add `DistributedCacheServiceTests` for `TryGet`, `Set`, and `Remove`.
- [x] Add `CurrentUserServiceTests` for user identity/claim access and explicit principal override.
- [x] Add `DateTimeServiceTests` for `NowUtc`.
- [x] Add `InMemorySessionWrapperTests` for `GetFromSession`, `SetInSession`, and `RemoveFromSession`.

Acceptance criteria:

- [x] Every public method on these shared services has meaningful coverage.

### Task INF.2: `UserService`

Status: - [x]
Description: Add strict branch coverage for all public `UserService` behaviors.
Implementation checklist:

- [x] Cover `RegisterUserAsync`.
- [x] Cover `UpdateUserAsync`.
- [x] Cover `GetUserByIdAsync`.
- [x] Cover `GetAllUsersAsync`.
- [x] Cover `GetUsersPagedQueryAsync`.
- [x] Cover `ChangeUserPasswordAsync`.
- [x] Cover `ChangeUserStatusAsync`.
- [x] Cover `GetUserRolesAsync`.
- [x] Cover `UpdateUserRolesAsync`.
- [x] Cover `ForgotPasswordAsync`.
- [x] Cover `ResetPasswordAsync`.
- [x] Use realistic ASP.NET Identity results and realistic concrete exceptions where possible.

Acceptance criteria:

- [x] Meaningful branches, error mapping, and exception handling are covered.
- [x] `T0.2` is completed before this task starts if DB-backed test infrastructure is reused here.

### Task INF.3: `TokenService`

Status: - [x]
Description: Add strict branch coverage for `TokenService`.
Implementation checklist:

- [x] Cover invalid credentials, inactive user, unconfirmed email, locked user, and successful login.
- [x] Cover invalid refresh token, expired refresh token, missing user, and successful refresh.
- [x] Decode returned JWTs.
- [x] Assert `NameIdentifier`, permission/role claims, and expiration window.
- [x] Assert refresh-token rotation behavior.

Acceptance criteria:

- [x] Both public methods have meaningful branch coverage.
- [x] Security-sensitive token contents are asserted explicitly.
- [x] `T0.2` is completed before this task starts if DB-backed test infrastructure is reused here.

### Task INF.4: `RoleService`

Status: - [x]
Description: Add strict branch coverage for `RoleService`.
Implementation checklist:

- [x] Cover `CreateRoleAsync`.
- [x] Cover `DeleteRoleAsync`.
- [x] Cover `GetPermissionsAsync`.
- [x] Cover `GetRoleByIdAsync`.
- [x] Cover `GetRolesAsync`.
- [x] Cover `UpdateRoleAsync`.
- [x] Cover `UpdateRolePermissionsAsync`.
- [x] Cover admin-role guard rails, no-op updates, missing role flows, and add/remove claim flows.

Acceptance criteria:

- [x] Every public method has meaningful branch coverage.
- [x] Claim add/remove logic and wrapper outcomes are asserted without pretending to unit-test real transactions.
- [x] `T0.2` is completed before this task starts if DB-backed test infrastructure is reused here.

## Phase 6: Domain Coverage Policy

### Task DOM.1: Defer anemic entity tests

Status: - [x]
Description: Do not spend time writing low-value tests for anemic domain entities that only expose public setters and no behavior.
File(s): `UMS.Domain/Entities/AuditTrail.cs`, `UMS.Domain/Entities/RefreshToken.cs`, `UMS.Domain/Entities/LogUserActivity.cs`, `UMS.Domain/Entities/OutboxMessage.cs`
Acceptance Criteria:

- [x] No tests are added that only assert auto-property storage for these entities.
- [x] Future domain tests are added only when behavior or invariants are introduced.

## Phase 7: Verification and Maintenance

### Task QA.1: Keep docs and blockers in sync

Status: - [x]
Description: Keep this implementation plan current as work progresses.
Implementation checklist:

- [x] Mark completed tasks in this plan as `[x]`.
- [x] Keep blocker tasks visible in the main flow, not in an appendix.
- [x] Keep `docs/test_coverage_audit.md` aligned with active project roles and test counts.

Acceptance criteria:

- [x] The plan, blockers, and actual test suite reflect the same current state.

### Task QA.2: Final verification sweep

Status: - [x]
Description: Run the maintained test projects together once all relevant tasks are complete.
Implementation checklist:

- [x] Run `dotnet test UMS.Domain.Tests/UMS.Domain.Tests.csproj`. (3 passed)
- [x] Run `dotnet test UMS.Application.Tests/UMS.Application.Tests.csproj`. (138 passed)
- [x] Run `dotnet test UMS.Infrastructure.Tests/UMS.Infrastructure.Tests.csproj`. (103 passed)
- [x] Run `dotnet test UMS.API.Tests/UMS.API.Tests.csproj`. (60 passed)
- [x] Run `dotnet test UMSSolution.slnx`. (304 total, 0 failed)
- [x] Review failures and close or re-open tasks as needed.

Acceptance criteria:

- [x] All maintained test projects pass.
- [x] No remaining unchecked task is left without an explicit reason.
