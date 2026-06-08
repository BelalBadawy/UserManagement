# UMS Testing Standards

**Type:** Rule  
**Applies To:** Testing (Backend, Frontend)  
**When to Use:** Apply when adding new test suites, mock configurations, testing APIs, or component verification files.

---

## 1. Project Organization and Naming Rules

- **Mapping Projects:** Every source project must have a corresponding test project (e.g., `UMS.Application.Tests` maps `UMS.Application`). The namespace and folder layout must mirror the source code project.
- **Naming Pattern:** Test method names must strictly follow the `{MethodName}_{Scenario}_{Expected}` convention:
  ```csharp
  [Fact]
  public async Task CreateUser_WithDuplicateEmail_ReturnsConflict() { ... }
  ```
- **Structure Pattern:** Always structure tests using the Arrange-Act-Assert (AAA) pattern. Use empty lines to separate these sections for readability.
- **Test Execution Budgets:** Unit tests must complete in < 500ms. Integration tests must complete in < 10s.
- **Coverage Thresholds:** Target &ge; 80% line coverage for `UMS.Application` and `UMS.Domain` projects.

---

## 2. Unit Testing Boundaries

### Domain Unit Tests
- **Target:** Entities, value objects, domain invariants, exceptions.
- **Rules:** Unit tests in `UMS.Domain.Tests` must run pure, fast, and containing NO mock assertions or external dependencies.

### Application Handler Unit Tests
- **Target:** Mediator CQRS handler pipelines.
- **Rules:** Tests must mock all external services (e.g. Email services, token systems).
- **RULE: SQLite Test DB Scope Setup:** Handlers executing database reads or writes must run within an isolated test scope (typically implementing `IAsyncDisposable` and utilizing a nested SQLite in-memory DB configuration).
  - Use `new SqliteConnection("Data Source=:memory:")` opened once per scope.
  - Set up `DbContext` options using `.UseSqlite(connection)`.
  - Enforce database schema creation via `await dbContext.Database.EnsureCreatedAsync()`.
  - Simulate cache interactions using a light recorder class (e.g., `RecordingCacheService` implementing `ICacheService`).
  - Test optimistic concurrency exceptions by configuring save overrides that throw `DbUpdateConcurrencyException` when a flag (e.g. `ThrowConcurrencyOnSave`) is set.
  - Verify domain event dispatching by checking the count and content of `OutboxMessages` seeded/saved to the context.

  *Example:*
  ```csharp
  await using var scope = await CategoryHandlerTestScope.CreateAsync();
  var handler = new CreateCategoryCommandHandler(scope.DbContext, scope.Cache);
  ```

### SQLite In-Memory Caveats
Be aware of behavioral differences between SQLite and SQL Server when writing handler tests:
- Enable foreign keys explicitly in your scope setup: `connection.Execute("PRAGMA foreign_keys = ON;")`
- String comparison is case-insensitive by default in SQLite, which may mask case-sensitivity bugs.
- Schema-qualified table names (like the Identity schema) are ignored by SQLite.
- SQL Server-specific functions (e.g., `STRING_AGG`, `TRY_CONVERT`) will not work in SQLite tests.
- Always validate critical query logic and concurrency handling against SQL Server integration tests.

---

## 3. Integration & Endpoint Testing Boundaries

### API Endpoints Tests
- **Target:** HTTP routing configurations, authorization attributes, model bindings, middleware handlers.
- **Rules:** Enforce integration tests in `UMS.API.Tests` using `CustomWebApplicationFactory` and `ApiTestBase`.
- **Database Engine:** Must execute against a real database instance (SQL Server as specified in `ApiTestDatabaseInitializer.cs`), performing schema migrations (`MigrateAsync()`) and baseline seeds mapping.
- **Clean State:** The database initializer must drop and recreate the schema (`EnsureDeletedAsync()`) to ensure absolute environment isolation.
- **Authorization Scenarios:** Run security matrix theories verifying access blocks across different client groups:
  ```csharp
  [Theory]
  [InlineData("anonymous", HttpStatusCode.Unauthorized)]
  [InlineData("low-privilege", HttpStatusCode.Forbidden)]
  [InlineData("privileged", HttpStatusCode.OK)]
  ```

---

## 4. Frontend Testing Boundaries

- **Hooks Testing:** Test React custom hooks using React Testing Library's `renderHook` helper.
- **Component Tests:** Verify visual components using React Testing Library (`RTL`) and Jest/Vitest.
- **User Interactions:** Assert user-facing text and behaviors (using user interactions like clicking buttons or typing text) rather than verifying component internals.
- **Accessible Queries:** Select elements using accessible properties (`screen.getByRole`, `screen.getByText`) rather than selecting using arbitrary `data-testid` attributes.
- **RULE: Service Hook Mocking:** Intercept API interactions in page tests by mocking React custom hooks (e.g., `vi.mock('../hooks/useCategories')` returning mocked `useCategoryList` hooks) rather than mocking fetch or Axios globally.
- **RULE: URL Parameter Update Assertions:** For all filters and search input controls on paged directory views:
  - Assert that changing input fields or dropdown options updates their local DOM value immediately, but does NOT mutate URL query parameters.
  - Assert that URL search parameters are updated ONLY after clicking the "Apply Filters" submit button.
  - Assert that clicking "Reset Filters" immediately resets both the local input values and clears the URL query parameters.

---

## 5. Test Data Generation and Isolation

- **Independent Execution:** Tests must not depend on database states mutated by other tests. Every test run must initialize and clean its own data sets.
- **Factory Helpers:** Object instantiation must leverage builder patterns or seeding helpers (such as `Seeder.SeedCategoryAsync` or test fixtures) rather than declaring complex objects manually inside each test method.
