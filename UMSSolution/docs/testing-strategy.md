# UMS Testing Strategy

## Goals

- Align test boundaries with Clean Architecture layers.
- Prefer behavior-focused tests over implementation-detail assertions.
- Maximize logical coverage of commands, queries, validators, domain rules, and HTTP contracts.
- Keep tests repeatable, isolated, and safe for parallel execution.

## Target test architecture

```text
UMS.Domain.Tests
|-- Builders
|-- Entities
|-- Support

UMS.Application.Tests
|-- Fixtures
|-- Handlers
|   |-- Users
|   |-- Roles
|   |-- Categories
|   |-- Token
|-- Validation
|   |-- Users
|   |-- Roles
|   |-- Categories
|-- Behaviors

UMS.Infrastructure.Tests
|-- Fixtures
|-- Persistence
|-- Services
|-- Identity

UMS.API.Tests
|-- Contracts
|-- Endpoints
|-- Fixtures
|-- Support
```

## Coverage map by layer

### Domain

- Test entity invariants, default values, state transitions, and business rules.
- Prefer builders to keep setup readable and avoid brittle object graphs.
- Focus on observable outcomes such as valid state, rejected transitions, and event creation.

### Application

- Test every command handler and query handler independently.
- Mock only external dependencies such as services, repositories, cache, email, or storage abstractions.
- Cover happy path, not found, conflict, authorization failure, validation failure, and exception propagation.
- Test every `FluentValidation` validator with valid input plus boundary and malformed input.
- Add tests for pipeline behaviors such as validation short-circuiting and response shaping.

### Infrastructure

- Test infrastructure adapters against their contracts, not against private implementation details.
- Prefer isolated temp directories for file/storage tests.
- Use `InMemoryDatabase` for fast EF integration checks and `Testcontainers` when relational behavior matters.
- Cover persistence concerns such as soft delete, auditing, seeding, and transaction handling.

### API

- Use `WebApplicationFactory<Program>` to run the full request pipeline.
- Cover route contracts, authentication/authorization, validation responses, and serialization.
- Keep endpoints independent by using isolated test databases and known seeded users.

## Example coverage checklist

### Commands and queries

- Every handler returns the expected response on success.
- Validation failures return consistent wrapper errors.
- Not found paths return the correct status and message.
- Conflicts and duplicate data return deterministic business messages.
- External service failures are surfaced intentionally.

### Validators

- Required-field validation.
- Boundary-length validation.
- Format validation such as email, slug, or phone number.
- Cross-field rules such as password confirmation.

### API contracts

- Anonymous endpoints allow unauthenticated access.
- Protected endpoints reject unauthenticated requests.
- Authorized requests succeed with expected payload shape.
- Invalid payloads return `400` with meaningful messages.

## Reusable patterns

### Naming conventions

- Class: `<SubjectUnderTest>Tests`
- Test method: `<Method_or_scenario>_should_<expected_behavior>`
- Builder: `<EntityName>Builder`
- Fixture: `<Capability>Fixture`

### Arrange-Act-Assert

- Keep all setup in `Arrange`.
- Call a single behavioral entry point in `Act`.
- Assert response shape, side effects, and collaborator usage in `Assert`.

### Builders and fixtures

- Builders own default valid data.
- Fixtures own heavyweight setup such as temp folders, factory bootstrapping, or seeded database clients.
- Prefer immutable request objects where possible to reduce accidental cross-test coupling.

## Parallel safety

- Domain and application unit tests should run fully in parallel.
- API tests are grouped into a non-parallel collection because the application bootstraps a shared in-memory host and seeded identity state.
- Infrastructure tests should isolate filesystem and database resources per test or per fixture.

## Best practices

- Assert business outcomes, not handler internals.
- Use one assertion block per behavior.
- Keep mock verification narrow and meaningful.
- Seed only the data required by the scenario.
- Prefer one public entry point per test.

## Anti-patterns to avoid

- Verifying every internal method call.
- Sharing mutable static test data.
- Coupling tests to EF tracking quirks or LINQ implementation details.
- Reusing a single database across unrelated integration tests without reset.
- Testing framework behavior instead of application behavior.

## Recommended next rollout

1. Port the remaining legacy `UMS.Tests` and `UMS.IntegrationTests` coverage into the new layer-specific projects.
2. Add application tests for all remaining handlers under `Roles`, `Categories`, `Token`, and `Users`.
3. Add infrastructure tests for `ApplicationDbContext` auditing, soft delete, and seeding behavior.
4. Add endpoint tests for `RoleEndpoints` and `UserEndpoints`, including permission checks.
5. Add CI coverage gates once package restore and execution are enabled in the environment.
