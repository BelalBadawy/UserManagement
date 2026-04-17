# Testing Strategy

## Unit Tests (Application & Domain)
- Frameworks: xUnit, NSubstitute/Moq, FluentAssertions
- Target: Application Layer (CQRS Handlers, Validators) + Domain Layer
- Mock ALL external dependencies (Repositories, External APIs, IMediator, Cache)
- Test both Success and Failure paths (Result.Failure, validation pipelines)

## Integration Tests
- Frameworks: xUnit, WebApplicationFactory, Testcontainers
- Use Testcontainers for SQL Server and Redis/Hangfire (NOT InMemory for accurate DB testing)
- Use IAsyncLifetime for Docker container lifecycle per test collection
- Exercise full middleware pipeline: Auth, Validation, Rate Limiting, Exception Handling

## Snapshot Testing (Verify)
- Use Verify library for complex outputs (generated Emails, JSON responses)
- Use await Verify(result); instead of manual string assertions

## Naming Conventions
- Follow: MethodName_StateUnderTest_ExpectedBehavior
- Example: CreateUserCommand_ValidInput_ReturnsSuccessResult
- Example: GetUserByIdQuery_UserNotFound_ReturnsFailureResult