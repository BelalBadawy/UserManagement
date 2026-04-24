# UMS Test Coverage Audit

Audit date: 2026-04-24

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
- `UMS.Application.Tests`: 16 tests
- `UMS.Infrastructure.Tests`: 7 tests
- `UMS.API.Tests`: 15 tests

Total maintained tests: 41

## Areas covered now

### Domain

- Category entity behavior and helper support through the maintained domain builders and entity tests.

### Application

- User handler coverage for registration and lookup.
- User validator coverage for registration and lookup.
- Validation pipeline regression coverage, including mixed-pass/mixed-fail behavior.
- Validation-participation coverage for `UpdateUserRolesCommand` and `GetRefreshTokenQuery`.
- Direct validator coverage for `DeleteRoleCommandValidator`.

### Infrastructure

- Local file storage save and delete behavior.
- Cancellation-aware file-save behavior in both rooted and fallback paths.
- Mail sender SSL configuration behavior driven by `EnableSsl`.

### API

- Focused API host/contract tests in `UMS.API.Tests`.
- Endpoint smoke coverage for account, category, role, and user flows in `UMS.API.Tests/Endpoints`.

## Gaps still worth prioritizing

- Broader Application handler coverage for categories, roles, and token scenarios.
- Additional Infrastructure coverage for seeding, auditing, and persistence behavior.
- More authorization-path and negative-path API coverage.
- Deeper API smoke coverage for mutation endpoints once request contracts are stabilized.

## Quality notes

- Placeholder `UnitTest1.cs` files were removed from the maintained test projects.
- The legacy catch-all `UMS.Tests` project is no longer part of the active repo test structure.
- The former `UMS.IntegrationTests` coverage now lives in `UMS.API.Tests/Endpoints`, and `UMSSolution.slnx` no longer references a separate integration test project.
