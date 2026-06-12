# Skill: Add New API Endpoint

**Type:** Skill  
**Applies To:** Backend (C# / .NET)  
**When to Use:** Follow this process when implementing a new API route, query, or command transaction in the backend.

---

## Related Rules
- [01-backend-architecture.md](file:///d:/_MyFolder/MyWorkSpace/UserManagement/UMSSolution/docs/ai-rules/01-backend-architecture.md) (Clean architecture references, Mediator commands/queries boundaries)
- [02-backend-coding-standards.md](file:///d:/_MyFolder/MyWorkSpace/UserManagement/UMSSolution/docs/ai-rules/02-backend-coding-standards.md) (Minimal API extensions, ResponseWrapper, Validation behaviors)
- [04-backend-security.md](file:///d:/_MyFolder/MyWorkSpace/UserManagement/UMSSolution/docs/ai-rules/04-backend-security.md) (Endpoint security guards and AppPermission constants)

---

## Real Example Reference
- **API Endpoint Routing Map**: [CategoryEndpoints.cs](file:///d:/_MyFolder/MyWorkSpace/UserManagement/UMSSolution/UMS.API/Endpoints/CategoryEndpoints.cs)
- **Mediator Query Handler**: [GetCategoriesPagedQuery.cs](file:///d:/_MyFolder/MyWorkSpace/UserManagement/UMSSolution/UMS.Application/Features/Categories/Queries/GetCategoriesPaged/GetCategoriesPagedQuery.cs)
- **Mediator Export Query & Handler**: [ExportCategoriesQuery.cs](file:///d:/_MyFolder/MyWorkSpace/UserManagement/UMSSolution/UMS.Application/Features/Categories/Queries/ExportCategories/ExportCategoriesQuery.cs)
- **Pagination Result Envelope**: [PagedResult.cs](file:///d:/_MyFolder/MyWorkSpace/UserManagement/UMSSolution/UMS.Application/Dtos/Pagination/PagedResult.cs)

---

## Procedural Workflow

### Step 1: Define Request, Response, and DTO Classes
1. Navigate to the feature directory: `UMS.Application/Features/{FeatureName}s/`.
2. Determine if the action is a **Command** (state mutation) or a **Query** (read-only data retrieval).
3. If it's a Command:
   - Under `/Commands/{ActionName}/`, create `{ActionName}Request.cs` to hold input bindings (if different from the Command record).
   - Create `{ActionName}Command.cs` declaring the command record:
     ```csharp
     public record CreateCategoryCommand(
         string Name, 
         string Slug, 
         int? ParentId, 
         bool IsActive, 
         int SortOrder
     ) : ICommand<IResponseWrapper<int>>, IValidateMe;
     ```
4. If it's a Query:
   - Under `/Queries/{ActionName}/`, create `{ActionName}Query.cs` declaring the query record:
     ```csharp
     public record GetCategoryByIdQuery(int Id) : IQuery<IResponseWrapper<CategoryResponse>>;
     ```
5. **PagedResult<T> Data Structure**:
   When implementing a paginated query, the response wrapper should contain a `PagedResult<T>` object (located at [PagedResult.cs](file:///d:/_MyFolder/MyWorkSpace/UserManagement/UMSSolution/UMS.Application/Dtos/Pagination/PagedResult.cs)):
   - `List<T> Data`: The items contained in the current page.
   - `int CurrentPage`: 1-based current page number.
   - `int PageSize`: Number of items per page.
   - `int TotalCount`: Total database records matching the filter.
   - `int TotalPages`: Computed read-only property `(int)Math.Ceiling(TotalCount / (double)PageSize)`.
   - `bool HasPreviousPage`: Computed read-only property `CurrentPage > 1`.
   - `bool HasNextPage`: Computed read-only property `CurrentPage < TotalPages`.

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
1. Inside the command or query file, create the handler class implementing `ICommandHandler` or `IQueryHandler`.
2. Handlers must return `ValueTask<IResponseWrapper<T>>` to match Mediator requirements.
3. **For Commands (Mutations):** Inject `IApplicationDbContext` and execute transactional saves returning wrap failures on catch (see [Skill: Add New Entity](file:///d:/_MyFolder/MyWorkSpace/UserManagement/UMSSolution/docs/ai-rules/skill-add-new-entity.md)).
4. **For Queries:** Inject the feature service interface (e.g. `ICategoryService`) and delegate logic:
   ```csharp
   public class GetCategoriesPagedQueryHandler(ICategoryService categoryService)
       : IRequestHandler<GetCategoriesPagedQuery, IResponseWrapper<PagedResult<CategoryResponse>>>
   {
       private readonly ICategoryService _categoryService = categoryService;

       public async ValueTask<IResponseWrapper<PagedResult<CategoryResponse>>> Handle(
           GetCategoriesPagedQuery request, 
           CancellationToken ct)
       {
           return await _categoryService.GetCategoriesPagedQueryAsync(request.PagedFilterRequest, ct);
       }
   }
   ```

### Step 4: Implement Export Query Handler Pattern
To support spreadsheet (Excel) and report (PDF) generation:
1. Create `Export{EntityName}Query.cs` implementing `IQuery<IResponseWrapper<byte[]>>`.
2. Define fields for filtering and sorting parameters (`SearchTerm`, `IsActive`, `SortBy`, `SortDirection`, `ExportFormat`).
3. Inside the query handler, execute the shared query and build the binary byte array using ClosedXML or QuestPDF:
   ```csharp
   public class ExportCategoriesQueryHandler(ICategoryService categoryService)
       : IQueryHandler<ExportCategoriesQuery, IResponseWrapper<byte[]>>
   {
       private readonly ICategoryService _categoryService = categoryService;

       public async ValueTask<IResponseWrapper<byte[]>> Handle(ExportCategoriesQuery request, CancellationToken ct)
       {
           // 1. Fetch full unpaginated list using the same query building filters
           var listResponse = await _categoryService.GetCategoriesListAsync(
               request.SearchTerm,
               request.IsActive,
               request.SortBy,
               request.SortDirection,
               ct);

           if (!listResponse.IsSuccessful || listResponse.Data == null)
           {
               return ResponseWrapper<byte[]>.Fail(
                   listResponse.Messages ?? new List<string> { "Failed to retrieve data for export." },
                   listResponse.StatusCode);
           }

           // 2. Delegate binary generation to the feature service
           var fileBytes = await _categoryService.ExportCategoriesAsync(listResponse.Data, request.ExportFormat, ct);

           return ResponseWrapper<byte[]>.Success(fileBytes);
       }
   }
   ```
4. **Service Generation Logic**:
   - **Excel (ClosedXML)**: Initialize `using var workbook = new XLWorkbook();`, populate worksheets, apply header styling (e.g., Bold, Background Color, Font Color), call `worksheet.Columns().AdjustToContents()`, save to a `MemoryStream`, and return `.ToArray()`.
   - **PDF (QuestPDF)**: Create `Document.Create(...)`, specify page orientations, page margins, table headers, table cells, and page number footer, compile to `MemoryStream`, and return `.ToArray()`.

### Step 5: Map the Minimal API Endpoint
1. Open the matching routing map class in `UMS.API/Endpoints/` (e.g. `CategoryEndpoints.cs`).
2. Add route mappers using version variables. Bridge response wrappers to client outputs using the `.ToApiResult()` extension:
   ```csharp
   // Standard paginated query with [AsParameters] binding
   group.MapGet("/paged", async (ISender sender, [AsParameters] PagedFilterRequest filter, CancellationToken ct) =>
   {
       var query = new GetCategoriesPagedQuery { PagedFilterRequest = filter };
       var response = await sender.Send(query, ct);
       return response.ToApiResult(); // Bridges wrapper to Results.Json
   })
   .Produces<IResponseWrapper<PagedResult<CategoryResponse>>>()
   .WithName("GetCategoriesPaged");

   // Binary stream export route
   group.MapGet("/export", async (
       ISender sender,
       string? searchTerm,
       bool? isActive,
       string? sortBy,
       string? sortDirection,
       string? exportFormat,
       CancellationToken ct) =>
   {
       var query = new ExportCategoriesQuery
       {
           SearchTerm = searchTerm,
           IsActive = isActive,
           SortBy = sortBy,
           SortDirection = sortDirection,
           ExportFormat = exportFormat ?? "excel"
       };
       var response = await sender.Send(query, ct);
       if (!response.IsSuccessful || response.Data == null)
       {
           return response.ToApiResult();
       }

       var isPdf = (exportFormat ?? "").Equals("pdf", StringComparison.OrdinalIgnoreCase);
       var contentType = isPdf ? "application/pdf" : "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
       var extension = isPdf ? "pdf" : "xlsx";
       var fileName = $"Categories_{DateTime.UtcNow:yyyyMMddHHmmss}.{extension}";

       return Results.File(response.Data, contentType, fileName);
   })
   .Produces(StatusCodes.Status200OK, contentType: "application/pdf")
   .Produces(StatusCodes.Status200OK, contentType: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
   .WithName("ExportCategories")
   .RequireAuthorization(AppPermission.NameFor(AppService.Product, AppFeature.Categories, AppAction.Read));
   ```
3. NEVER write controller files or use standard controller attribute mappings.

### Step 6: Implement Automated Tests
1. **Unit Test:** Under `UMS.Application.Tests/Handlers/{Feature}/`, create unit test scenarios using an in-memory db setup (`CategoryHandlerTestSupport`).
2. **Integration Test:** Under `UMS.API.Tests/Endpoints/`, add endpoint integration tests inheriting from `ApiTestBase`. Verify routing mappings, status returns, and authorization limits.

---

## Expected Outcome (Definition of Done)
- Command/Query request record and Handler class created in the feature directory.
- Validator class implementing `AbstractValidator` created and wired.
- Queries bound using `[AsParameters]` for complex requests.
- Export route mapped, returning binary files via `Results.File()` with custom content types and timestamps.
- API route successfully mapped to the Minimal API routing group and returned via `response.ToApiResult()`.
- 1 handler unit test and 1 endpoint integration test written and passing.

---

## Troubleshooting & Rollback

### If compilation fails due to missing references:
- Verify that `global using Mediator;` is available.
- Ensure the Command implements `ICommand<T>` and the handler class implements `ICommandHandler<TRequest, TResponse>` (not `IRequest`/`IRequestHandler`).
- Ensure the project builds. The Mediator source generator compiles routing types at build time.

### Rollback Strategy
To undo the endpoint changes:
1. Delete the files created in `UMS.Application/Features/{FeatureName}s/`.
2. Remove the route definition from the Endpoint map configuration file under `UMS.API/Endpoints/`.
3. Delete the unit and integration test methods created for this endpoint.
