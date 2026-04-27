---
name: ums-test-coverage
description: Add or extend automated tests for features in the UMS solution. Use when Codex needs to create, update, or verify tests in `UMS.API.Tests`, `UMS.Application.Tests`, `UMS.Infrastructure.Tests`, or `UMS.Domain.Tests`, especially when the work must follow `docs/test_coverage_implementation_plan.md`, the repo's xUnit and FluentAssertions conventions, API integration test setup rules, and endpoint authorization theory patterns.
---

# UMS Test Coverage

Use this skill for repo-specific testing work in `D:\_MyApps\UserManagement\UMSSolution`.

## Workflow

1. Read `docs/test_coverage_implementation_plan.md` before writing tests.
2. Read the production feature files and the existing tests in the owning test project.
3. Map the feature to one surface: API, Application, Infrastructure, or Domain.
4. Add or update tests in the matching maintained test project only.
5. Run the owning test project after the task group is complete.
6. Update `docs/test_coverage_implementation_plan.md` checkboxes when progress is made.

## Non-Negotiable Rules

- Use `xUnit` for new tests.
- Use `FluentAssertions` for assertions.
- Use `Moq` only in `UMS.Application.Tests` and `UMS.Infrastructure.Tests`.
- Keep tests in strict Arrange / Act / Assert form.
- Name tests `MethodName_Scenario_ExpectedResult`.
- Do not add placeholder assertions or empty bodies.
- Do not add tests to deprecated projects such as legacy `UMS.Tests` or `UMS.IntegrationTests`.
- Preserve `COVERAGE_AUDIT.md` as a historical snapshot.

## Pick the Right Pattern

### API work

- Read `references/api-testing.md`.
- Use the shared API support infrastructure instead of inventing ad hoc auth or database setup.
- Assert exact success status codes for protected endpoints.
- Use one three-row authorization `[Theory]` per protected endpoint: anonymous `401`, wrong permission `403`, exact permission success.
- Prefer asserting response shape plus persisted state, not only `200 OK`.

### Application work

- Read `references/application-infrastructure-domain.md`.
- For pass-through handlers, verify dependency invocation and result passthrough only.
- For logical handlers, cover meaningful branches, state changes, and failure paths.
- Add direct validator tests for rule behavior and separate pipeline tests when validation execution itself matters.

### Infrastructure work

- Read `references/application-infrastructure-domain.md`.
- Aim for strict branch coverage.
- Use realistic dependency exceptions and result objects.
- Decode and assert JWT claims and expiration windows for token flows.

### Domain work

- Read `references/application-infrastructure-domain.md`.
- Skip data-bag entity tests unless the entity owns behavior or invariants worth asserting.

## Execution Notes

- Reuse existing helpers before creating new ones.
- Keep endpoint-specific helpers near the tests until repetition is real, then extract small support files.
- Prefer follow-up GET verification for API mutations; use direct DB checks when projections hide the changed fields.
- Keep verification at the business-field level unless concurrency behavior is the thing being tested.

## References

- Read `references/api-testing.md` for API host, auth, seeding, and verification rules.
- Read `references/application-infrastructure-domain.md` for handler, validator, infrastructure, and domain test rules.
- Read `D:\_MyApps\UserManagement\UMSSolution\docs\test_coverage_implementation_plan.md` for the current task list and blockers.
