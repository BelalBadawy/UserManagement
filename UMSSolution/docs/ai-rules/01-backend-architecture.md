# UMS Backend Architecture

**Type:** Rule  
**Applies To:** Backend (C# / .NET)  
**When to Use:** Apply whenever structuring project references, organizing feature directories, mapping endpoints, or defining core types.

---

## 1. Project Dependency Direction

The solution follows Clean Architecture dependency flow:

```
     +-----------------+
     |     UMS.API     |
     +---+---------+---+
         |         |
         |         v
         |   +--------------------+
         |   | UMS.Infrastructure |
         |   +---+---------+------+
         |       |         |
         v       v         |
     +-----------+-----+   |
     | UMS.Application |   |
     +-----------+-----+   |
                 |         |
                 v         v
             +---+---------+---+
             |    UMS.Domain   |
             +-----------------+
```
- **UMS.API** references `UMS.Application` and `UMS.Infrastructure`.
- **UMS.Infrastructure** references `UMS.Application` and `UMS.Domain`.
- **UMS.Application** references `UMS.Domain` (never references `UMS.Infrastructure` or `UMS.API`).
- **UMS.Domain** has NO references to any other project in the solution and has no reference to third-party database frameworks like EF Core.

**Forbidden Reference Paths:**
- `UMS.Domain` must never reference `UMS.Application`, `UMS.Infrastructure`, or `UMS.API`.
- `UMS.Application` must never reference `UMS.Infrastructure` or `UMS.API`.
- No layer may reference `UMS.API`.

---

## 2. Layer Boundaries

### UMS.API (Presentation Layer)
- **What belongs here:** Minimal API endpoint maps, HTTP startup pipeline configurations (`Program.cs`), custom middlewares, filters, and Scalar/OpenAPI setup.
- **Rules:** No business logic or database queries. All requests must be dispatched to the Application layer using the Mediator publisher/sender.

### UMS.Application (Core Application Logic)
- **What belongs here:** CQRS commands, queries, command/query handlers, validation rules, input DTOs, response models, mapping profiles, and Mediator pipeline behaviors.
- **Rules:** Must depend only on Domain abstractions. Must not reference concrete infrastructure implementations (such as database context classes, email dispatch configurations, or filesystem writers).
  - *Note: `IApplicationDbContext` is defined in `UMS.Application.Interfaces.Common`, not Domain, because it represents an application-level persistence contract. Domain entities remain completely persistence-ignorant.*

### UMS.Domain (Core Business Model & Abstractions)
- **What belongs here:** Entities, Value Objects, Domain Events, Enums, Custom Exceptions, and core infrastructure interfaces (such as repository or DB context interfaces).
- **Rules:** Must remain completely isolated. Domain entities and logic must be pure C# and not reference framework-specific packages (such as `Microsoft.EntityFrameworkCore`).
  - *Note: `IApplicationDbContext` is defined in `UMS.Application.Interfaces.Common`, not Domain, because it represents an application-level persistence contract. Domain entities remain completely persistence-ignorant.*

### UMS.Infrastructure (External Concerns)
- **What belongs here:** Entity Framework DB context, migrations, database configurations, ASP.NET Core Identity store implementations, JWT generation, file storage, email providers, and caching implementations.
- **Rules:** Details of connection strings, external APIs, and infrastructure wiring are encapsulated here and exposed to the Application layer via interfaces defined in Domain or Application.

---

## 3. Strict Framework Banishments

### Ban MediatR — Require Martinothamar's Mediator (V3 Source Generator)
- **MediatR is strictly forbidden.** Do not register or use MediatR assemblies or namespaces.
- **Mediator is required.** The project uses Martinothamar's `Mediator` which relies on source generators.
- **Command and Query definition rules:**
  - Every Query or Command must implement `IRequest<IResponseWrapper<T>>` or `IRequest<IResponseWrapper>`.
  - Every Handler must implement `IRequestHandler<TRequest, TResponse>`, where the `Handle` method signature MUST return `ValueTask<TResponse>` (NOT `Task<TResponse>`).
- **`IValidateMe` Pipeline Rule:**
  - Every Query or Command that requires validation must also implement the `IValidateMe` marker interface (defined in `UMS.Application.Interfaces.Common`).
  - This interface acts as a generic constraint for the source-generated `ValidationPipelineBehavior<TRequest, TResponse> : IPipelineBehavior<TRequest, TResponse> where TRequest : IRequest<TResponse>, IValidateMe`, allowing the validation pipeline to automatically intercept, validate via the corresponding `AbstractValidator<T>`, and return a 400 Bad Request error wrapped in `ResponseWrapper` without running the handler.
- **Registration rule:** Because behaviors and handlers are resolved via source-generated types at compile time, register the mediator and behaviors explicitly in the dependency injection configuration (e.g. `Microsoft.Extensions.DependencyInjection.MediatorDependencyInjectionExtensions.AddMediator` with scoped lifetime).

### Ban Controllers — Require Minimal APIs
- **Controller classes are strictly forbidden.** Do not use `[ApiController]`, `[Route]`, or base class `ControllerBase` inheritance.
- **Enforce Minimal API Endpoint Mapping & Organization:**
  - Define all endpoints in static classes in the `UMS.API.Endpoints` namespace (e.g., `public static class CategoryEndpoints`).
  - Expose a static extension method: `public static IEndpointRouteBuilder Map{FeatureName}Endpoints(this IEndpointRouteBuilder app)`.
  - Call this extension method explicitly in the presentation layer startup file (`Program.cs`) on the `WebApplication` instance (e.g. `app.MapCategoryEndpoints()`).
  - Use versioned groups for routes within the extension method:
    `var group = app.MapGroup("api/v{version:apiVersion}/categories").WithTags("Categories");`
  - Group mappings must use Minimal API fluent configurations for metadata, security, and versioning (e.g., `.Produces<IResponseWrapper<T>>()`, `.WithName("EndpointName")`, `.RequireAuthorization(...)`, `.AllowAnonymous()`).

---

## 4. CQRS File Organization & Naming Conventions

### File Layout
Feature logic must be organized under `UMS.Application/Features/{FeatureName}/` using separate subfolders for Commands, Queries, and Events:
- **`Features/{FeatureName}/Commands/{CommandName}/`**
  - Contains `{CommandName}Command.cs` (contains request DTO if any, the command record implementing `IRequest<TResponse>`, and the command handler class implementing `IRequestHandler<TRequest, TResponse>`).
  - Contains `{CommandName}CommandValidator.cs` (holds FluentValidation rules inheriting from `AbstractValidator<{CommandName}Command>`).
- **`Features/{FeatureName}/Queries/{QueryName}/`**
  - Contains `{QueryName}Query.cs` (contains query record implementing `IRequest<TResponse>` and the query handler class).
  - Contains `{QueryName}QueryValidator.cs` if the query implements `IValidateMe`.
  - Contains query-specific lookup DTOs or projections.
- **`Features/{FeatureName}/Events/`**
  - Contains feature-related events (e.g., `CategoryCreatedEvent.cs`, `CategoryUpdatedEvent.cs`).
- **`Features/{FeatureName}/`**
  - Contains feature service interface `I{FeatureName}Service.cs` (e.g., `ICategoryService.cs` defining paged listing, lookup listing, and report exports), helper classes (e.g. `CategoryWriteGuards.cs` for unique verification, `CategoryCacheKeys.cs` for cache management).

### Naming Conventions
- Commands: `{Verb}{Noun}Command` (e.g., `CreateCategoryCommand`, `DeleteCategoryCommand`).
- Queries: `{Verb}{Noun}Query` (e.g., `GetCategoryByIdQuery`, `GetCategoriesPagedQuery`).
- Handlers: `{CommandOrQueryName}Handler` (e.g., `CreateCategoryCommandHandler`, `GetCategoriesPagedQueryHandler`).

---

## 5. Domain Events and the Outbox Pattern

- **Mutation Notifications:** Database mutations (insert, update, delete) must dispatch domain events via the Outbox pattern to ensure transactional consistency.
- **Outbox Message Queueing:**
  - Inside command handlers, after making database changes, call `_applicationDbContext.AddOutboxMessage(new {FeatureName}{Mutation}Event(...))`.
  - **RULE: Transaction-Wrapped Two-Phase Saves:** For new entities requiring their generated primary key ID in the outbox event payload, developers must explicitly wrap the operations in a database transaction block using `BeginTransactionAsync` / `CommitAsync` to guarantee atomicity:
    ```csharp
    await using var transaction = await _applicationDbContext.Database.BeginTransactionAsync(ct);

    // Phase 1: Save entity to generate ID
    await _applicationDbContext.SaveChangesAsync(ct);

    // Phase 2: Add outbox message using generated ID
    _applicationDbContext.AddOutboxMessage(new CategoryCreatedEvent(category.Id));
    await _applicationDbContext.SaveChangesAsync(ct);

    await transaction.CommitAsync(ct);
    ```
  - Explicit transaction wrapping is mandatory for any multi-phase save to guarantee transactional consistency and prevent partial failures.
