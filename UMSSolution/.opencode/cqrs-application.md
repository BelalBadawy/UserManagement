# CQRS & Application Layer

## CQRS Pattern (Mediator.SourceGenerator)
- Commands: Mutate state. Format: [Action][Entity]Command (e.g., CreateUserCommand)
- Queries: Read state. Format: Get[Entity]Query (e.g., GetUserByIdQuery)
- Use Mediator.SourceGenerator for zero-allocation, high-performance dispatching

## Result Pattern
- Exceptions NOT used for business logic failures
- Every Command/Query MUST return Result<T> or Result

## IValidateMe & Validation Pipeline
- Use FluentValidation for input validation
- Command/Query implements IValidateMe marker interface
- ValidationBehavior<TRequest, TResponse> (IPipelineBehavior) catches validation errors automatically
- If validation fails, returns failed Result with validation messages

## Domain Events & Outbox Pattern
- Command Handlers NOT execute external side effects directly
- Entities call methods that raise IDomainEvents
- Outbox Pattern: EF Core SaveChanges Interceptor reads IDomainEvents, serializes, saves to OutboxMessages table in same transaction
- Hangfire background job polls and dispatches messages

## Key Interfaces
- IRequest<TResponse> - for commands/queries
- IRequestHandler<TRequest, TResponse> - for handling
- IPipelineBehavior<TRequest, TResponse> - for cross-cutting concerns