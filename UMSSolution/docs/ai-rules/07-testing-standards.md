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

---

## 2. Unit Testing Boundaries

### Domain Unit Tests
- **Target:** Entities, value objects, domain invariants, exceptions.
- **Rules:** Unit tests in `UMS.Domain.Tests` must run pure, fast, and containing NO mock assertions or external dependencies.

### Application Handler Unit Tests
- **Target:** Mediator CQRS handler pipelines.
- **Rules:** Tests must mock all external services (e.g. Email services, token systems).
- **Database Simulation:** Use SQLite in-memory provider wrapped within a test scope setup (similar to `CategoryHandlerTestSupport.cs`) to check database operations and outbox messages:
  ```csharp
  await using var scope = await CategoryHandlerTestScope.CreateAsync();
  var handler = new CreateCategoryCommandHandler(scope.DbContext, scope.Cache);
  ```

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
- **Service Layer Mocking:** Intercept API interactions by mocking feature service calls (e.g., mocking `categoriesApi.getPagedList`) at the service layer boundary rather than mocking Axios or Fetch globally.

---

## 5. Test Data Generation and Isolation

- **Independent Execution:** Tests must not depend on database states mutated by other tests. Every test run must initialize and clean its own data sets.
- **Factory Helpers:** Object instantiation must leverage builder patterns or seeding helpers (such as `Seeder.SeedCategoryAsync` or test fixtures) rather than declaring complex objects manually inside each test method.
