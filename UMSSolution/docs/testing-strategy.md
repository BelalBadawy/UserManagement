# UMS Testing Strategy

## Maintained test projects

```text
UMS.Domain.Tests
|-- Builders
|-- Entities
|-- Support

UMS.Application.Tests
|-- Behaviors
|-- Fixtures
|-- Handlers
|-- Validation

UMS.Infrastructure.Tests
|-- Fixtures
|-- Services

UMS.API.Tests
|-- Contracts
|-- Endpoints
|-- Fixtures
|-- Support
```

`UMS.Tests` is no longer part of the maintained test surface. Coverage now lives in the layer-specific projects above, with `UMS.API.Tests` owning both focused API checks and endpoint smoke coverage.

## Project roles

### `UMS.Domain.Tests`

- Covers entity behavior, invariants, and helper extensions.
- Uses builders to keep setup small and readable.

### `UMS.Application.Tests`

- Covers handlers, validators, and pipeline behaviors.
- Mocks external collaborators and focuses on business outcomes.
- Holds regression coverage for validation participation and wrapper behavior.

### `UMS.Infrastructure.Tests`

- Covers infrastructure adapters and service contracts.
- Uses temp directories and isolated setup for filesystem-oriented tests.
- Verifies configuration-driven behavior for file storage and email sending.

### `UMS.API.Tests`

- Covers focused HTTP contract and host-configuration behavior.
- Uses `WebApplicationFactory<Program>` fixtures for lightweight API checks.
- Also owns endpoint smoke coverage alongside the focused contract checks in `Endpoints`.

## Test design rules

- Prefer behavior-focused assertions over private implementation checks.
- Keep each test centered on one public entry point.
- Use deterministic seeded data or locally generated unique values.
- Keep validation tests direct and pipeline tests explicit about short-circuit behavior.
- Isolate filesystem and host state through fixtures or disposable setup.

## Parallel and isolation guidance

- Domain and Application tests should remain parallel-safe.
- Infrastructure tests must isolate temporary files and disposable resources.
- API-hosted tests should assume shared host state and keep setup explicit.

## Next coverage priorities

1. Expand Application handler coverage for categories, roles, and token flows.
2. Add Infrastructure tests for seeding, auditing, and persistence behavior.
3. Deepen API authorization and smoke coverage for protected endpoints.
4. Add CI reporting for maintained test projects only.
