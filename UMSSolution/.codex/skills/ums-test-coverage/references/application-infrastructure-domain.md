# Application, Infrastructure, and Domain Rules

Use these rules for `UMS.Application.Tests`, `UMS.Infrastructure.Tests`, and `UMS.Domain.Tests`.

## Application Handlers

- Keep one test class per handler.
- For pass-through handlers, verify dependency invocation and returned-object passthrough only.
- Do not duplicate service behavior assertions for true pass-through handlers.
- For logical handlers, cover meaningful internal branches, state changes, and error paths.

## Validators

- Use explicit validator tests to prove rule behavior.
- Use pipeline tests to prove validation filters execute.
- Assert failing property or rule rather than exact message text unless the message is a strict contract.
- Treat `PropertyName` as a frontend-facing contract, but avoid brittle collection index assertions.

## Infrastructure Services

- Aim for strict branch coverage.
- Cover guard clauses, dependency result mapping, and realistic exception handling branches.
- Use representative mapping tests unless production code branches on specific external error codes.
- Throw realistic dependency exception types in mocks, not generic `Exception`.
- For `TokenService`, decode generated JWTs and assert `NameIdentifier`, role or permission claims, and expiration windows.
- For `UserService.ForgotPasswordAsync` and similar flows, verify the generated security token reaches the email sender instead of asserting exact URL composition.
- For `RoleService.UpdateRolePermissionsAsync`, verify add or remove decisions and success or failure wrappers rather than pretending to test real transactions.

## Domain

- Skip tests for anemic entities with no meaningful behavior.
- Do not add tests that only assert auto-properties on `AuditTrail`, `RefreshToken`, `LogUserActivity`, or `OutboxMessage`.
- Add domain tests only when behavior or invariants are introduced.

## Verification

- Run the owning test project after each completed task group.
- Update `docs/test_coverage_implementation_plan.md` to reflect completed work and blockers.
