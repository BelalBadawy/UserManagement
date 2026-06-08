# UMS Backend Data and Infrastructure

**Type:** Rule  
**Applies To:** Backend (C# / .NET)  
**When to Use:** Apply when modifying entities, defining entity configurations, writing database migrations, writing queries, or integrating infrastructure services.

---

## 1. EF Core Mapping Configurations

- **Separate Mapping Classes:** Direct inline mapping configuration inside `ApplicationDbContext.OnModelCreating` is forbidden.
- Define a separate mapping class implementing `IEntityTypeConfiguration<TEntity>` for each database entity under the `UMS.Infrastructure/Persistence/DbConfigurations` folder.
- Model configurations must explicitly define key constraints, nullability, column data types (e.g., `nvarchar(150)`), default values, indices, and delete cascade behaviors:
  ```csharp
  public class CategoryConfiguration : IEntityTypeConfiguration<Category>
  {
      public void Configure(EntityTypeBuilder<Category> builder)
      {
          builder.ToTable("Categories");
          builder.HasKey(c => c.Id);
          builder.Property(c => c.Name).IsRequired().HasMaxLength(150).HasColumnType("nvarchar(150)");
          // configure other fields...
      }
  }
  ```
- **Index Conventions:** Explicitly define indexes in `IEntityTypeConfiguration` for foreign keys, frequently queried/sorted columns, and unique constraints. Do not rely on EF Core's default index creation for foreign keys if the column will be heavily filtered or sorted.
- **Concurrency Tokens:** Entities that support optimistic concurrency control (implementing `IDataConcurrency`) must map their `RowVersion` field to the SQL Server native `rowversion` type and flag it as a concurrency token using:
  ```csharp
  builder.Property(c => c.RowVersion)
      .IsConcurrencyToken()
      .HasColumnType("rowversion"); // SQL Server native type; SQLite ignores the type constraint
  ```

---

## 2. Database Context Injection Rules

- **Abstract Context Reference:** Handlers and core services must NEVER inject `ApplicationDbContext` directly.
- **Enforced Interface:** Inject the `IApplicationDbContext` interface (defined in `UMS.Application.Interfaces.Common`) to perform database queries.
- **EF Core Domain Ban:** The `UMS.Domain` project must NEVER reference `Microsoft.EntityFrameworkCore` or other ORM libraries.

---

## 3. Database Migration Workflow

- **Idempotent and Automated:** Schema mutations are tracked via EF Core migrations. Handlers or DB seeds must not modify schema definitions.
- **Migration Generation:** Always generate migrations using the CLI from the solution folder, targetting the Infrastructure project:
  ```powershell
  dotnet ef migrations add <DescriptiveMigrationName> --project UMS.Infrastructure --startup-project UMS.API --context ApplicationDbContext
  ```
- **Review Migrations:** Carefully verify generated `Up` and `Down` actions. Verify that data loss actions are guarded.
- **Never Seed in Migrations:** Do not write data seeding calls inside the migration's `Up` methods. Seeding is the responsibility of the dedicated database seeding services.

---

## 4. Multi-Database Support

- **Cross-Database Compatibility:** All LINQ queries must work across SQL Server (Production), SQLite (Testing), and InMemory (Prototyping).
- **No Raw SQL:** Raw database queries (e.g., `.FromSqlRaw`) are forbidden unless absolutely necessary.
- **Provider Checks:** If native functions are required, guard execution blocks using provider checks:
  ```csharp
  if (_applicationDbContext.Database.IsSqlServer())
  {
      // run SQL Server optimized query
  }
  ```

---

## 5. Connection Strings and Secret Keys

- **No Hardcoded Values:** Databases details, passwords, and security keys must never be hardcoded into source files or commit tracks.
- **Configuration Bindings:** Configure configurations inside `appsettings.json` and map them using Options mapping.
- **Development Secrets:** In the development environment, bind configurations to User Secrets (`dotnet user-secrets`).
- **Production Environment:** Bind configurations directly to secure environment variables.

### Options Pattern Validation
All strongly-typed configuration classes (e.g., `JwtSettings`, `DatabaseSettings`) must:
- Use data annotations for required fields and ranges.
- Call `.ValidateDataAnnotations().ValidateOnStart()` during service registration.
- Fail fast at application startup if configuration is missing or invalid, preventing runtime discovery of config errors.

---

## 6. Core Identity Integration

- **Encapsulated Identity:** All user management, roles assignment, and password validation must be processed via the designated Infrastructure Identity services (e.g., `UserService.cs` implementing `IUserService`).
- Handlers and endpoint extension mappings must NEVER inject the Identity `UserManager<T>` or `RoleManager<T>` directly. Implement service wrapper interfaces in the Application project and implement them inside the Infrastructure project.

---

## 7. Data Seeding Services

- **Idempotent Execution:** Baseline categories, roles, and default permissions seeding are handled by the database seeding pipeline (`ApiTestDatabaseInitializer` for tests, baseline infrastructure seeders for production).
- Seeding routines must be idempotent, checking for object existence (e.g. using `!_dbContext.Categories.Any()`) before attempting to write records.
- **Indexed Column Normalization:** When seeding lookup fields (such as Category name or slug) that have unique indexes, always manually apply uppercase normalization matching write rules (e.g., using `category.NormalizedName = name.ToUpperInvariant()`).

---

## 8. Global Model Creation Hooks

The `ApplicationDbContext` class must enforce global conventions dynamically in its `OnModelCreating` override:
- **Decimal Precision:** Intercept all decimal properties and configure their precision to 18 and scale to 6 globally:
  ```csharp
  var decimalProperties = entityType.GetProperties()
      .Where(p => p.ClrType == typeof(decimal) || p.ClrType == typeof(decimal?));
  foreach (var property in decimalProperties)
  {
      property.SetPrecision(18);
      property.SetScale(6);
  }
  ```
  *Note: Specific entities requiring different precision may override this global convention explicitly in their individual `IEntityTypeConfiguration<T>` class.*
- **Identity Table & Schema Configuration:** Strip the default ASP.NET Core `AspNet` prefix from Identity tables (e.g., `tableName.Substring(6)`), and assign them to the `Identity` schema (only when running on SQL Server).
- **Global Soft Delete Filters:** Iterate through all entity types and dynamically apply global soft-delete query filters on types implementing `ISoftDelete`:
  ```csharp
  if (typeof(ISoftDelete).IsAssignableFrom(entityType.ClrType))
  {
      entityType.AddSoftDeleteQueryFilter();
  }
  ```
