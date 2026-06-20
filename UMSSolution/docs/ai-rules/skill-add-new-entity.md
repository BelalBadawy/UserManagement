# Skill: Add New Entity

**Type:** Skill  
**Applies To:** Backend (C# / .NET)  
**When to Use:** Follow this workflow when defining new domain models, database configurations, and setting up their CRUD operations.

---

## Related Rules
- [01-backend-architecture.md](docs/ai-rules/01-backend-architecture.md) (Layer boundaries, Mediator configurations)
- [03-backend-data-and-infrastructure.md](docs/ai-rules/03-backend-data-and-infrastructure.md) (EF configurations, context parameters, migrations naming)
- [08-project-conventions.md](docs/ai-rules/08-project-conventions.md) (Audit logging, version variables)

---

## Real Example Reference
- **C# Entity Domain Model**: [UMS.Domain/Entities/Category.cs](UMS.Domain/Entities/Category.cs)
- **Database Mapping Configuration**: [UMS.Infrastructure/Persistence/DbConfigurations/CategoryConfiguration.cs](UMS.Infrastructure/Persistence/DbConfigurations/CategoryConfiguration.cs)
- **DbContext Interfaces**: [UMS.Application/Interfaces/Common/IApplicationDbContext.cs](UMS.Application/Interfaces/Common/IApplicationDbContext.cs)
- **Concrete Context**: [UMS.Infrastructure/Persistence/Contexts/ApplicationDbContext.cs](UMS.Infrastructure/Persistence/Contexts/ApplicationDbContext.cs)
- **Dependency Registration Extension**: [UMS.Infrastructure/ServiceCollectionExtensions.cs](UMS.Infrastructure/ServiceCollectionExtensions.cs)
- **Domain Event & Handler**: [UMS.Application/Features/Categories/Events/CategoryCreatedEvent.cs](UMS.Application/Features/Categories/Events/CategoryCreatedEvent.cs)

---

## Procedural Workflow

### Step 1: Define Domain Entity
1. In `UMS.Domain/Entities/`, create the entity class `{EntityName}.cs` extending `BaseEntity<int>` (which only defines `Id`) and implementing `IFullEntity`:
   ```csharp
   namespace UMS.Domain.Entities
   {
       public class Category : BaseEntity<int>, IFullEntity, IDataConcurrency
       {
           public string Name { get; set; } = string.Empty;
           public string Slug { get; set; } = string.Empty;
           public string NormalizedName { get; set; } = string.Empty;
           public string NormalizedSlug { get; set; } = string.Empty;
           public bool IsActive { get; set; } = true;
           public int SortOrder { get; set; }

           // IAuditable properties must be manually declared on the class
           public int? CreatedBy { get; set; }
           public DateTime CreatedAt { get; set; }
           public int? LastModifiedBy { get; set; }
           public DateTime? LastModifiedAt { get; set; }

           // ISoftDelete properties must be manually declared on the class
           public bool SoftDeleted { get; set; }
           public int? DeletedBy { get; set; }
           public DateTime? DeletedAt { get; set; }

           // IDataConcurrency property must be manually declared on the class
           public byte[] RowVersion { get; set; } = Array.Empty<byte>();
       }
   }
   ```
2. **Inheritance Decision Guideline**:
   - Use `IFullEntity` for standard primary business records needing audit trails, soft deletes, and optimistic concurrency.
   - For read-only reference data or configuration lookups, omit `ISoftDelete` and `IDataConcurrency` (and their respective auto-properties), implementing only `IAuditable` or no tracking interfaces.
3. Ensure there are no database framework namespace imports (e.g. `Microsoft.EntityFrameworkCore`) inside domain model files.

### Step 2: Configure EF Core Mapping
1. Under `UMS.Infrastructure/Persistence/DbConfigurations/`, create the configuration file `{EntityName}Configuration.cs` implementing `IEntityTypeConfiguration<T>`:
   ```csharp
   using Microsoft.EntityFrameworkCore;
   using Microsoft.EntityFrameworkCore.Metadata.Builders;
   using UMS.Domain.Entities;

   namespace UMS.Infrastructure.Persistence.DbConfigurations
   {
       public class CategoryConfiguration : IEntityTypeConfiguration<Category>
       {
           public void Configure(EntityTypeBuilder<Category> builder)
           {
               builder.ToTable("Categories");
               builder.HasKey(x => x.Id);
               builder.Property(x => x.Id).ValueGeneratedOnAdd();
               
               builder.Property(x => x.Name).IsRequired().HasMaxLength(150);
               builder.Property(x => x.Slug).IsRequired().HasMaxLength(250);

               // Unique Index naming convention (UX_)
               builder.HasIndex(x => x.NormalizedName)
                   .IsUnique()
                   .HasDatabaseName("UX_Categories_NormalizedName");

               // Concurrency mapping mapping (rowversion type)
               builder.Property(x => x.RowVersion)
                   .IsConcurrencyToken()
                   .ValueGeneratedOnAddOrUpdate()
                   .HasColumnType("rowversion");

               // Query filter is dynamically applied in ApplicationDbContext for ISoftDelete, 
               // but it can be specified here if custom behaviors are needed.
           }
       }
   }
   ```

### Step 3: Register in DbContext
1. Register the entity DbSet property on the interface [UMS.Application/Interfaces/Common/IApplicationDbContext.cs](UMS.Application/Interfaces/Common/IApplicationDbContext.cs):
   ```csharp
   DbSet<Category> Categories { get; }
   ```
2. Register the concrete DbSet property on [UMS.Infrastructure/Persistence/Contexts/ApplicationDbContext.cs](UMS.Infrastructure/Persistence/Contexts/ApplicationDbContext.cs):
   ```csharp
   public DbSet<Category> Categories => Set<Category>();
   ```

### Step 4: Register Technical Services in DI
1. If the entity requires technical infrastructure services (such as generating reports/exports e.g. `ICategoryExportService` / `CategoryExportService`), register it as scoped inside [UMS.Infrastructure/ServiceCollectionExtensions.cs](UMS.Infrastructure/ServiceCollectionExtensions.cs):
   ```csharp
   services.AddScoped<ICategoryExportService, CategoryExportService>();
   ```

### Step 5: Implement Application Logic & Handlers
1. Create the feature directory: `UMS.Application/Features/{FeatureName}s/`.
2. Implement Mediator commands and queries under feature directories:
   - **Queries and Reports**: Inject `IApplicationDbContext` directly. Perform querying, filtering, and joining inside the Query Handlers. If multiple handlers share identical filtering/sorting logic, extract it into a static query extension method on `IQueryable` (e.g. `CategoryQueryExtensions.cs`). If formatting or exporting is required, delegate that technical aspect to an infrastructure service interface like `ICategoryExportService`.
   - **Mutations (Commands)**: Inject `IApplicationDbContext` and `ICacheService` directly into the Command Handlers to handle transaction logic and cache eviction.
3. **Cache Invalidation Ownership**: Command handlers own cache invalidation. On success, call `_cacheService.Remove(key)` for all cached keys in the handler, NOT inside notification handlers.
4. **Two-Phase Save Transaction Sequence**:
   Implement commands using the standard try-catch transaction pattern. Catch database exceptions, execute rollbacks, and return wrapping failures:
   ```csharp
   public class CreateCategoryCommandHandler(
       IApplicationDbContext applicationDbContext,
       ICacheService cacheService)
      : IRequestHandler<CreateCategoryCommand, IResponseWrapper<int>>
   {
       private readonly IApplicationDbContext _applicationDbContext = applicationDbContext;
       private readonly ICacheService _cacheService = cacheService;

       public async ValueTask<IResponseWrapper<int>> Handle(CreateCategoryCommand request, CancellationToken ct)
       {
           // ... Validation and Guard logic ...

           var category = new Category { Name = request.Name, Slug = request.Slug };

           try
           {
               await _applicationDbContext.StartTransaction(ct);

               // Step 1: Save Entity State changes
               await _applicationDbContext.Categories.AddAsync(category, ct);
               await _applicationDbContext.SaveChangesAsync(ct); // Generates category.Id

               // Step 2: Enqueue Domain Event Outbox message with generated ID
               _applicationDbContext.AddOutboxMessage(new CategoryCreatedEvent(category.Id));
               await _applicationDbContext.SaveChangesAsync(ct);

               // Step 3: Commit transaction
               await _applicationDbContext.CommitTransaction(ct);
           }
           catch (Exception ex)
           {
               try
               {
                   await _applicationDbContext.RollbackTransaction(ct);
               }
               catch (Exception rollbackEx)
               {
                   // Log rollback failure
               }

               return ResponseWrapper<int>.Fail($"Database transaction failed: {ex.Message}");
           }

           // Step 4: Invalidate cache (Command Handler responsibility)
           foreach (var key in CategoryCacheKeys.All)
           {
               _cacheService.Remove(key);
           }

           return ResponseWrapper<int>.Success(category.Id, "Category created successfully.");
       }
   }
   ```

### Step 6: Implement Domain Events & Notification Handlers
1. Create the domain event record under `UMS.Application/Features/{FeatureName}s/Events/` implementing `INotification` (from the `Mediator` namespace):
   ```csharp
   public class CategoryCreatedEvent : INotification
   {
       public CategoryCreatedEvent(int id) => CategoryId = id;
       public int CategoryId { get; }
   }
   ```
2. Create the event handler implementing `INotificationHandler<T>` in the same folder.
   - **Eventual Consistency Side-effects**: Use notification handlers for asynchronous activities (sending confirmation emails, publishing integration events to external brokers, logging analytics). Do NOT put synchronous cache invalidations here.
   - **Outbox Processor**: The runtime background processing worker is currently `[AWAITING IMPLEMENTATION — No codebase example yet]`. Verify event dispatch logic using unit tests against `OutboxMessages` DB entries.

### Step 7: Implement Soft-Delete Restore Workflow
If an administrative command needs to restore a soft-deleted record:
1. Retrieve the deleted record by using `.IgnoreQueryFilters()` to bypass the global EF Core filter:
   ```csharp
   var entity = await _applicationDbContext.Categories
       .IgnoreQueryFilters()
       .FirstOrDefaultAsync(x => x.Id == request.Id, ct);
   ```
2. Manually restore properties and save:
   ```csharp
   entity.SoftDeleted = false;
   entity.DeletedAt = null;
   entity.DeletedBy = null;
   await _applicationDbContext.SaveChangesAsync(ct);
   ```
   *Note: Because the entity state is Modified, not Deleted, the ApplicationDbContext save interceptor ignores it, updating database fields cleanly.*

---

## Expected Outcome (Definition of Done)
- Domain Entity class defined under `UMS.Domain/Entities/` implementing required interface auto-properties.
- Mapping class defined under `UMS.Infrastructure/Persistence/DbConfigurations/` using `UX_` index prefix and `rowversion` database mapping type.
- DbSet registered in both `IApplicationDbContext.cs` and `ApplicationDbContext.cs`.
- Technical infrastructure services (like export services) registered as scoped dependencies under `ServiceCollectionExtensions.cs`.
- Handlers implementing the two-phase try-catch transaction sequences returning `ResponseWrapper.Fail()` on catch.
- Asynchronous side-effects configured inside `INotificationHandler<T>` events.
- Unit and integration tests compile, asserting Outbox enqueuing states.
