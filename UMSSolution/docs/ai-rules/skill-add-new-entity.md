# Skill: Add New Entity

**Type:** Skill  
**Applies To:** Backend (C# / .NET)  
**When to Use:** Follow this workflow when defining new domain models, database configurations, and setting up their CRUD operations.

---

## Related Rules
- [01-backend-architecture.md](file:///d:/_MyFolder/MyWorkSpace/UserManagement/UMSSolution/docs/ai-rules/01-backend-architecture.md) (Layer boundaries, Mediator configurations)
- [03-backend-data-and-infrastructure.md](file:///d:/_MyFolder/MyWorkSpace/UserManagement/UMSSolution/docs/ai-rules/03-backend-data-and-infrastructure.md) (EF configurations, context parameters, migrations naming)
- [08-project-conventions.md](file:///d:/_MyFolder/MyWorkSpace/UserManagement/UMSSolution/docs/ai-rules/08-project-conventions.md) (Audit logging, version variables)

---

## Procedural Workflow

### Step 1: Define Domain Entity
1. In `UMS.Domain/Entities/`, create the entity file `{EntityName}.cs` extending `BaseEntity` or implementing relevant interfaces (`IAuditable`, `ISoftDelete`, `IDataConcurrency`):
   ```csharp
   namespace UMS.Domain.Entities
   {
       public class Category : BaseEntity, IAuditable, ISoftDelete, IDataConcurrency
       {
           public string Name { get; set; } = string.Empty;
           public string Slug { get; set; } = string.Empty;
           public bool SoftDeleted { get; set; }
           public byte[] RowVersion { get; set; } = [];
       }
   }
   ```
2. Verify that there are **NO database framework imports** (e.g. EF Core namespace references) inside this file.

### Step 2: Configure EF Core Mapping
1. Under `UMS.Infrastructure/Persistence/DbConfigurations/`, create the mapping file `{EntityName}Configuration.cs` implementing `IEntityTypeConfiguration<T>`:
   ```csharp
   public class CategoryConfiguration : IEntityTypeConfiguration<Category>
   {
       public void Configure(EntityTypeBuilder<Category> builder)
       {
           builder.ToTable("Categories");
           builder.HasKey(x => x.Id);
           builder.Property(x => x.Name).IsRequired().HasMaxLength(150);
       }
   }
   ```

### Step 3: Register in DbContext
1. Open `UMS.Infrastructure/Persistence/Contexts/ApplicationDbContext.cs`.
2. Declare the `DbSet<T>` property:
   ```csharp
   public DbSet<Category> Categories => Set<Category>();
   ```

### Step 4: Create Database Migration
1. Open a terminal and generate the migration from the repository root:
   ```powershell
   dotnet ef migrations add Add{EntityName}Table --project UMS.Infrastructure --startup-project UMS.API --context ApplicationDbContext
   ```
2. Review the generated migration file. Run validation commands and check that `Up` and `Down` are correctly mapped.
3. Update the dev database:
   ```powershell
   dotnet ef database update --project UMS.Infrastructure --startup-project UMS.API --context ApplicationDbContext
   ```

### Step 5: Implement Application Logic & Endpoints
1. Create the feature directory: `UMS.Application/Features/{FeatureName}s/`.
2. Implement Mediator Commands (Create, Update, Delete) and Queries (GetById, GetPaged) under the feature directory.
3. Wire FluentValidation validations for all commands.
4. For mutating commands, ensure outbox notifications and audit trails are logged:
   ```csharp
   _applicationDbContext.AddOutboxMessage(new CategoryCreatedEvent(category.Id));
   ```
5. Map Minimal API endpoints under `UMS.API/Endpoints/`. Protect endpoints with `.RequireAuthorization(AppPermission.NameFor(...))`.

### Step 6: Create Baseline Tests
1. Write unit tests for the command and query handlers under `UMS.Application.Tests/Handlers/`.
2. Write integration tests under `UMS.API.Tests/Endpoints/` to verify endpoint routing, schema returns, and role matrices.

---

## Expected Outcome (Definition of Done)
- Domain Entity class defined under `UMS.Domain/Entities/`.
- Mapping class defined under `UMS.Infrastructure/Persistence/DbConfigurations/`.
- DbSet registered in `ApplicationDbContext.cs`.
- EF migration successfully generated, applied, and verified against SQL Server.
- Mediator CRUD logic, command validators, and handlers implemented in UMS.Application.
- Minimal API routes mapped and authorized in UMS.API.
- Full test coverage (handler unit tests and API integration tests) passes.

---

## Troubleshooting & Rollback

### Migration Failures:
- If `migrations add` fails: Verify syntax, entity configuration logic, and database properties. Delete any partially generated migration classes and try again.
- If `database update` fails: Verify connection strings in `appsettings.Testing.json` or `appsettings.json`, and verify SQL Server is running.

### Rollback Strategy
1. Revert DB schema changes:
   ```powershell
   dotnet ef database update <PreviousMigrationName> --project UMS.Infrastructure --startup-project UMS.API
   ```
2. Remove the migration using:
   ```powershell
   dotnet ef migrations remove --project UMS.Infrastructure --startup-project UMS.API --context ApplicationDbContext
   ```
3. Remove the added entity class, entity configuration file, DbSet declaration, and delete application handler files.
