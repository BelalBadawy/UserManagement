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

---

## 6. Core Identity Integration

- **Encapsulated Identity:** All user management, roles assignment, and password validation must be processed via the designated Infrastructure Identity services (e.g., `UserService.cs` implementing `IUserService`).
- Handlers and endpoint extension mappings must NEVER inject the Identity `UserManager<T>` or `RoleManager<T>` directly. Implement service wrapper interfaces in the Application project and implement them inside the Infrastructure project.

---

## 7. Data Seeding Services

- **Idempotent Execution:** Baseline categories, roles, and default permissions seeding are handled by the database seeding pipeline (`ApiTestDatabaseInitializer` for tests, baseline infrastructure seeders for production).
- Seeding routines must be idempotent, checking for object existence (e.g., `SingleOrDefaultAsync`) before attempting to write record duplicates.
