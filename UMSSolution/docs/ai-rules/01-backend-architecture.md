# UMS Backend Architecture

**Type:** Rule  
**Applies To:** Backend (C# / .NET)  
**When to Use:** Apply whenever structuring project references, organizing feature directories, mapping endpoints, or defining core types.

---

## 1. Project Dependency Direction

The solution follows Clean Architecture V-Shape dependency flow:

```
+-----------------------------+
|           UMS.API           |
+--------------+--------------+
               |
               v
+-----------------------------+
|       UMS.Application       |
+--------------+--------------+
               |
               v
+-----------------------------+
|          UMS.Domain         |
+-----------------------------+
               ^
               | (implements Domain interfaces)
+-----------------------------+
|      UMS.Infrastructure     |
+-----------------------------+
               ^
               | (registered in API)
+-----------------------------+
|           UMS.API           |
+-----------------------------+
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

### UMS.Domain (Core Business Model & Abstractions)
- **What belongs here:** Entities, Value Objects, Domain Events, Enums, Custom Exceptions, and core infrastructure interfaces (such as repository or DB context interfaces).
- **Rules:** Must remain completely isolated. Domain entities and logic must be pure C# and not reference framework-specific packages (such as `Microsoft.EntityFrameworkCore`).

### UMS.Infrastructure (External Concerns)
- **What belongs here:** Entity Framework DB context, migrations, database configurations, ASP.NET Core Identity store implementations, JWT generation, file storage, email providers, and caching implementations.
- **Rules:** Details of connection strings, external APIs, and infrastructure wiring are encapsulated here and exposed to the Application layer via interfaces defined in Domain or Application.

---

## 3. Strict Framework Banishments

### Ban MediatR — Require Martinothamar's Mediator (V3 Source Generator)
- **MediatR is strictly forbidden.** Do not use `IRequest<T>`, `IRequestHandler<TRequest, TResponse>`, or `services.AddMediatR(...)`.
- **Mediator is required.** The project uses Martinothamar's `Mediator` which relies on source generators.
- **Command and Query definition rules:**
  - Every Query must implement `IQuery<IResponseWrapper<T>>` or `IQuery<IResponseWrapper>`.
  - Every Command must implement `ICommand<IResponseWrapper<T>>` or `ICommand<IResponseWrapper>`.
  - Handlers must implement `IQueryHandler<TQuery, TResponse>` or `ICommandHandler<TCommand, TResponse>`.
- **Registration rule:** Because behaviors and handlers are resolved via source-generated types at compile time, there is no runtime reflection assembly scanning. Register behaviors using `MediatorOptions` in the service setup.

### Ban Controllers — Require Minimal APIs
- **Controller classes are strictly forbidden.** Do not use `[ApiController]`, `[Route]`, `[HttpGet]`, `[Authorize]`, or base class `ControllerBase` inheritance.
- **Enforce Minimal API Endpoint Mapping:** Define endpoints using static extensions of `IEndpointRouteBuilder` (e.g. `MapCategoryEndpoints`).
- Use Minimal API fluent configurations for metadata, security, and versioning (e.g., `.WithOpenApi()`, `.RequireAuthorization()`, `.WithApiVersionSet()`).

---

## 4. CQRS File Organization & Naming Conventions

### File Layout
Feature logic must be organized under `UMS.Application/Features/{FeatureName}/` using separate subfolders for Commands and Queries:
- **`Features/{FeatureName}/Commands/{CommandName}/`**
  - Contains `{CommandName}Command.cs` (contains command record, DTO input mapping class, and the command handler class).
  - Contains `{CommandName}CommandValidator.cs` (holds the validation logic).
- **`Features/{FeatureName}/Queries/{QueryName}/`**
  - Contains `{QueryName}Query.cs` (contains query record and the query handler class).
  - Contains any query-specific lookup DTOs or projections.

### Naming Conventions
- Commands: `{Verb}{Noun}Command` (e.g., `CreateCategoryCommand`, `DeleteUserCommand`).
- Queries: `{Verb}{Noun}Query` (e.g., `GetCategoryByIdQuery`, `GetUsersPagedQuery`).
- Handlers: `{CommandOrQueryName}Handler` (e.g., `CreateCategoryCommandHandler`, `GetUsersPagedQueryHandler`).
