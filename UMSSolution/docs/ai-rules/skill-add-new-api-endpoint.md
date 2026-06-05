# Skill: Add New API Endpoint

**Type:** Skill  
**Applies To:** Backend (C# / .NET)  
**When to Use:** Follow this process when implementing a new API route, query, or command transaction in the backend.

---

## Related Rules
- [01-backend-architecture.md](01-backend-architecture.md) (Clean architecture references, Mediator commands/queries boundaries)
- [02-backend-coding-standards.md](02-backend-coding-standards.md) (Minimal API extensions, ResponseWrapper, Validation behaviors)
- [04-backend-security.md](04-backend-security.md) (Endpoint security guards and AppPermission constants)

---

## Procedural Workflow

### Step 1: Define Request and DTO Classes
1. Navigate to the feature directory: `UMS.Application/Features/{FeatureName}/`.
2. Determine if the action is a **Command** (state mutation) or a **Query** (read-only data retrieval).
3. If it's a Command:
   - Under `/Commands/{ActionName}/`, create `{ActionName}Request.cs` to hold input bindings.
   - Create `{ActionName}Command.cs` declaring the command record:
     ```csharp
     public record CreateCategoryCommand(string Name, string Slug) : ICommand<IResponseWrapper<int>>, IValidateMe;
     ```
4. If it's a Query:
   - Under `/Queries/{ActionName}/`, create `{ActionName}Query.cs` declaring the query record:
     ```csharp
     public record GetCategoryByIdQuery(int Id) : IQuery<IResponseWrapper<CategoryDto>>;
     ```

### Step 2: Implement Fluent Validation
1. If the request implements `IValidateMe`, create a validator file `{ActionOrRequestName}Validator.cs` next to the Command/Query record.
2. Define a class implementing `AbstractValidator<TCommand>`:
   ```csharp
   public class CreateCategoryCommandValidator : AbstractValidator<CreateCategoryCommand>
   {
       public CreateCategoryCommandValidator()
       {
           RuleFor(x => x.Name).NotEmpty().MaximumLength(150);
       }
   }
   ```

### Step 3: Implement CQRS Handler
1. Inside the command or query file, create the handler class implementing `ICommandHandler` or `IQueryHandler`:
   ```csharp
   public class CreateCategoryCommandHandler(IApplicationDbContext applicationDbContext)
       : ICommandHandler<CreateCategoryCommand, IResponseWrapper<int>>
   {
       public async ValueTask<IResponseWrapper<int>> Handle(CreateCategoryCommand request, CancellationToken ct)
       {
           // Implementation logic...
           return ResponseWrapper<int>.Success(newCategoryId);
       }
   }
   ```
2. **For Commands (Mutations):**
   - Save database changes via `await _applicationDbContext.SaveChangesAsync(ct)`.
   - **Outbox Requirement:** If the mutation triggers a domain event or integration event, add it to the outbox in the same transaction: `_applicationDbContext.AddOutboxMessage(new EntityCreatedEvent(entity.Id));`
3. **For Queries:** Simply return the projected data wrapped in `ResponseWrapper<T>.Success(...)`.

### Step 4: Map the Minimal API Endpoint
1. Open the matching routing map class in `UMS.API/Endpoints/` (e.g. `CategoryEndpoints.cs`).
2. Add the route mapper using the version variables and API tags:
   ```csharp
   group.MapPost("/", async (ISender sender, CreateCategoryRequest request, CancellationToken ct) =>
   {
       var command = new CreateCategoryCommand(request.Name, request.Slug);
       var response = await sender.Send(command, ct);
       return response.ToApiResult();
   })
   .Produces<IResponseWrapper<int>>()
   .WithName("CreateCategory")
   .RequireAuthorization(AppPermission.NameFor(AppService.Product, AppFeature.Categories, AppAction.Create));
   ```
3. NEVER write controller files or use standard controller attribute mappings.

### Step 5: Implement Automated Tests
1. **Unit Test:** Under `UMS.Application.Tests/Handlers/{Feature}/`, create unit test scenarios using an in-memory db setup (`CategoryHandlerTestSupport`). Verify command output wrapper properties.
2. **Integration Test:** Under `UMS.API.Tests/Endpoints/`, add endpoint integration tests inheriting from `ApiTestBase`. Verify routing mappings, status returns, and authorization limits.

---

## Expected Outcome (Definition of Done)
- Command/Query request record and Handler class created in the feature directory.
- Validator class implementing `AbstractValidator` created and wired.
- API route successfully mapped to the Minimal API routing group.
- 1 handler unit test and 1 endpoint integration test written and passing.
- The route is visible and functional in the Scalar UI (`/scalar/v1`) in the development environment.

---

## Troubleshooting & Rollback

### If compilation fails due to missing references:
- Verify that `global using Mediator;` is available.
- Ensure the Command implements `ICommand<T>` and the handler class implements `ICommandHandler<TRequest, TResponse>` (not `IRequest`/`IRequestHandler`).
- Ensure the project builds. The Mediator source generator compiles routing types at build time.

### Rollback Strategy
To undo the endpoint changes:
1. Delete the files created in `UMS.Application/Features/{FeatureName}/`.
2. Remove the route definition from the Endpoint map configuration file under `UMS.API/Endpoints/`.
3. Delete the unit and integration test methods created for this endpoint.
