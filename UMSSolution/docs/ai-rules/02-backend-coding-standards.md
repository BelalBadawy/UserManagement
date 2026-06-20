# UMS Backend Coding Standards

**Type:** Rule  
**Applies To:** Backend (C# / .NET)  
**When to Use:** Apply when writing C# classes, configuring endpoints, mapping data models, or handling errors and responses.

---

## 1. C# Coding and Naming Conventions

- **PascalCase:** Use for class names, methods, records, properties, interfaces (prefixed with `I`), and public members.
- **_camelCase:** Use for private fields, prefixed with an underscore (e.g., `_applicationDbContext`).
- **camelCase:** Use for local variables and method parameters.
- **Async Suffix:** All asynchronous methods must end with the `Async` suffix (e.g., `SaveChangesAsync`, `GetUserByIdAsync`).
- **Use Primary Constructors:** Utilize primary constructor syntax for dependency injection when defining handlers and service classes:
  ```csharp
  public class GetCategoryByIdQueryHandler(IApplicationDbContext applicationDbContext)
      : IRequestHandler<GetCategoryByIdQuery, IResponseWrapper<CategoryDto>>
  {
      private readonly IApplicationDbContext _applicationDbContext = applicationDbContext;

      public async ValueTask<IResponseWrapper<CategoryDto>> Handle(
          GetCategoryByIdQuery request,
          CancellationToken cancellationToken)
      {
          // Handler logic returning ValueTask
      }
  }
  ```

---

## 2. Minimal API Fluent Conventions

Do NOT use controller attributes like `[ProducesResponseType]`, `[Authorize]`, or `[Route]`. Instead, define endpoints using Minimal API fluent mapping options:
- **OpenAPI Documentation:** Use `.WithName("EndpointName")` and `.Produces<IResponseWrapper<T>>()` to document metadata and returns. Do not use `.WithOpenApi()` directly unless customizing properties.
- **Security Guarding:** Use `.RequireAuthorization("PolicyName")` or `.RequireAuthorization(AppPermission.NameFor(...))` to enforce access rules. Use `.AllowAnonymous()` where security is bypassed.
- **Api Versioning:** Set the endpoint's version parameters on the group router using `.WithApiVersionSet(...)` or path variable mapping (`api/v{version:apiVersion}`).
- **Mediator Injection:** Inject `ISender` (the verified interface alias from the source-generated `Mediator` namespace) into endpoint handlers via DI parameter binding. Do NOT use MediatR's `ISender` interface.

Example of compliant route definition:
```csharp
group.MapPost("/", async (ISender sender, CreateCategoryRequest request, CancellationToken ct) =>
{
    var command = new CreateCategoryCommand(request.Name, request.Slug, request.ParentId, request.IsActive, request.SortOrder);
    var response = await sender.Send(command, ct);
    return response.ToApiResult();
})
.Produces<IResponseWrapper<int>>()
.WithName("CreateCategory")
.RequireAuthorization(AppPermission.NameFor(AppService.Product, AppFeature.Categories, AppAction.Create));
```

---

## 3. Validation Pipeline Flow (`IValidateMe`)

The application intercepts validation requests and handles errors prior to handler execution.
- **Request Marker:** Any Query or Command requiring validation must implement the `IValidateMe` marker interface.
- **AbstractValidator:** Define a companion validator extending FluentValidation's `AbstractValidator<T>` in the same folder.
- **Validation interceptor:** The source-generated `ValidationPipelineBehavior<TRequest, TResponse>` intercepts queries/commands that implement `IValidateMe`.
  - It runs the registered validator(s) in parallel.
  - If validation fails, it short-circuits execution and returns a wrapped failure `ResponseWrapper` with status code 400 containing validation messages.
  - Handlers must NEVER run manual input format validation (handled by FluentValidation). However, business rule validation (e.g., verifying a category name is unique, checking hierarchical constraints) is permitted and expected inside handlers.

---

## 4. Mapping Guidelines (Writes vs Reads)

Mapping Strategy: Manual LINQ projections + explicit mapping only. `.Adapt()` or any third-party object mapping libraries are forbidden. For reads, use manual LINQ projections `.Select(x => new Dto(...))`. For writes, use explicit manual property assignments to ensure full control over input sanitization and normalization.

---

## 5. Response Envelope Contract (`ResponseWrapper<T>`)

Every API endpoint must return a standardized JSON response envelope. Direct entity instances or raw arrays must never be exposed.

### Envelope Structure
- **Success Wrapper:**
  ```json
  {
    "data": { ... },
    "isSuccessful": true,
    "messages": ["Operation completed successfully."],
    "statusCode": 200
  }
  ```
- **Failure Wrapper:**
  ```json
  {
    "data": null,
    "isSuccessful": false,
    "messages": ["Error message 1", "Error message 2"],
    "statusCode": 400
  }
  ```

### Key Rules
- API endpoints map mediator results using the `.ToApiResult()` extension method, which sets the appropriate HTTP status code based on `response.StatusCode`.
- Validation errors and exceptions are converted to this standard envelope pattern.

---

## 6. Error Handling

- **No Raw Exception Throwing:** Handlers must not throw raw exceptions for control flow. Return a failed wrapper instead (e.g. `ResponseWrapper<T>.Fail("Category not found.", 404)`).
- **Middleware Safety:** An unhandled runtime error (e.g. timeout, DB crash) is captured by `ErrorHandlingMiddleware`. It formats the exception info (omitting debug details in production environment) into `ResponseWrapper.Fail(message, 500)` and returns it with the correct HTTP status code.

---

## 7. Logging & Async Operations

- **Structured Logging:** Use `ILogger<T>` for logging. NEVER use `Console.WriteLine`. Log parameters must use named templates:
  ```csharp
  _logger.LogInformation("Category {CategoryId} deleted by user {UserId}", categoryId, userId);
  ```
- **Correlation Scopes:** For multi-step operations (such as outbox saves or complex command handlers), wrap the logic in a logging scope using `_logger.BeginScope("Feature: {FeatureName}, EntityId: {EntityId}", "Category", id)` to ensure all logs within the operation share contextual identifiers for log aggregation systems.
- **Async Execution:** All disk and network I/O operations must be fully async. NEVER call `.Result`, `.Wait()`, or `.GetAwaiter().GetResult()`. Use `ValueTask` or `Task` along with `await` and forward `CancellationToken` params down the line.

---

## 8. Concurrency Control Checks

- **Row Version Setting:** In update command handlers, always call `_applicationDbContext.SetOriginalRowVersion(entity, request.RowVersion)` before applying changes.
- **Concurrency Exception Handling:** Wrap database save operations (`SaveChangesAsync`) in a try-catch block catching `DbUpdateConcurrencyException`. If caught, return a failed response envelope with a 409 status code and a user-friendly concurrency error message:
  ```csharp
  try
  {
      _applicationDbContext.Categories.Update(category);
      await _applicationDbContext.SaveChangesAsync(ct);
  }
  catch (DbUpdateConcurrencyException)
  {
      return ResponseWrapper.Fail("Concurrency conflict: this record was modified by another user. Refresh and try again.", 409);
  }
  ```
