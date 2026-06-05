# Skill: Add Database Migration

**Type:** Skill  
**Applies To:** Backend (C# / .NET)  
**When to Use:** Follow this process when updating EF Core entities, introducing database tables, changing field mappings, or updating indices.

---

## Related Rules
- [03-backend-data-and-infrastructure.md](file:///d:/_MyFolder/MyWorkSpace/UserManagement/UMSSolution/docs/ai-rules/03-backend-data-and-infrastructure.md) (EF configurations, context boundaries, migrations conventions)
- [08-project-conventions.md](file:///d:/_MyFolder/MyWorkSpace/UserManagement/UMSSolution/docs/ai-rules/08-project-conventions.md) (Performance, N+1 query rules)

---

## Procedural Workflow

### Step 1: Implement Entity and Mapping Changes
1. Modify or create target domain model classes under `UMS.Domain/Entities/`.
2. Add or update companion `IEntityTypeConfiguration<T>` files under `UMS.Infrastructure/Persistence/DbConfigurations/`.
3. If introducing new tables, register their corresponding `DbSet<T>` properties inside `UMS.Infrastructure/Persistence/Contexts/ApplicationDbContext.cs`.
4. Build the solution and verify that it compiles.

### Step 2: Generate Migration Script
1. Open a terminal at the workspace root directory.
2. Run the Entity Framework Core CLI migrations generator tool. Specify descriptive PascalCase naming parameters:
   ```powershell
   dotnet ef migrations add AddCategoryDescription --project UMS.Infrastructure --startup-project UMS.API --context ApplicationDbContext
   ```

### Step 3: Review Generated Migration Codes
1. Open the newly created migration file under `UMS.Infrastructure/Migrations/`.
2. Inspect both `Up` and `Down` methods:
   - Ensure columns types, lengths, and constraints match your configurations.
   - Verify indices are named properly (`UX_TableName_FieldName` pattern).
   - If migrating schema changes on populated tables, add default value settings to avoid constraint violations.
   - Verify the `Down` method cleanly undoes all actions created in the `Up` method.

### Step 4: Apply Migration
1. Apply the database changes to your local development database:
   ```powershell
   dotnet ef database update --project UMS.Infrastructure --startup-project UMS.API --context ApplicationDbContext
   ```
2. Verify that the table schema has been updated by inspecting the local database catalog.

### Step 5: Verify Seeding and Integration Tests
1. Run local integration tests to verify database initialization.
2. Confirm the test environment initializes cleanly: running `EnsureDeletedAsync()` and `MigrateAsync()` successfully.

---

## Expected Outcome (Definition of Done)
- Compilation succeeds.
- Migration files (both designer and code files) generated under `UMS.Infrastructure/Migrations/`.
- Local development database successfully updated to the latest migration.
- Test suites run and pass.

---

## Troubleshooting & Rollback

### Troubleshooting
- **If `migrations add` fails with a context mapping error:** Verify `IApplicationDbContext` interfaces are not referenced in the commands and that the project build completes successfully.
- **If `database update` fails with a schema constraint violation:** Verify that you aren't attempting to add a non-nullable column to a populated table without default configurations.

### Rollback Strategy
1. To rollback a database schema change, execute a database update targeting the previous migration name:
   ```powershell
   dotnet ef database update NameOfPreviousMigration --project UMS.Infrastructure --startup-project UMS.API --context ApplicationDbContext
   ```
2. Once the database has been rolled back, remove the generated migration files from the codebase:
   ```powershell
   dotnet ef migrations remove --project UMS.Infrastructure --startup-project UMS.API --context ApplicationDbContext
   ```
3. Revert your entity classes, DbSet configurations, and type mapping modifications.
