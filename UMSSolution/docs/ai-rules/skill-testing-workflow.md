# Skill: Testing Workflow

**Type:** Skill  
**Applies To:** Testing  
**When to Use:** Use this process when writing unit tests for handlers, integration tests for API endpoints, or RTL component tests.

---

## Related Rules
- [07-testing-standards.md](file:///d:/_MyFolder/MyWorkSpace/UserManagement/UMSSolution/docs/ai-rules/07-testing-standards.md) (Test namespaces, project mapping rules, test boundary conditions)

---

## Procedural Workflow

### Step 1: Identify Test Scope
Determine what category of test to write based on the feature changes:
- **Domain Unit Test:** Fast validation checks of domain model calculations and state transitions. No mocks.
- **Application Handler Unit Test:** Uses SQLite in-memory test databases (`CategoryHandlerTestSupport.cs`) to verify database write transactions and Mediator Command/Query outputs. Mocks external services.
- **API Endpoint Integration Test:** Uses `CustomWebApplicationFactory` to spin up a local ASP.NET test server and call routes using `Client`. Runs against a real test database (SQL Server) to verify routing, authorization policies, and middleware handlers.
- **Frontend RTL Test:** Uses React Testing Library to verify component rendering and user actions (e.g. form inputs, page clicks). Mocks API calls.

### Step 2: Create Test File and Setup Context
1. Create the test class file in the correct test project. The namespace and folder layout must mirror the source code project.
2. If writing a handler unit test:
   - Create a test scope:
     ```csharp
     await using var scope = await CategoryHandlerTestScope.CreateAsync();
     ```
3. If writing an API endpoint test:
   - Inherit from `ApiTestBase` and annotate the class with the API test collection:
     ```csharp
     [Collection("API collection")]
     public class CategoryEndpointsTests : ApiTestBase
     {
         public CategoryEndpointsTests(CustomWebApplicationFactory factory) : base(factory) { }
     }
     ```

### Step 3: Write the Happy Path Scenario
1. Implement the Arrange-Act-Assert structure:
   - **Arrange:** Initialize required seed data (e.g., calling `Seeder.SeedCategoryAsync(...)`), mock adapters, and prepare parameters.
   - **Act:** Execute the target method (e.g. calling the handler `Handle(...)` or firing the API endpoint `Client.GetAsync(...)`).
   - **Assert:** Validate output properties (e.g., using FluentAssertions `.Should().BeTrue()`).

### Step 4: Write Edge Cases and Validation Failures
1. Write test cases targeting duplicate values, invalid inputs, and bounds limits.
2. Confirm the command validator blocks invalid input requests:
   - Validate that a command missing required fields returns an unsuccessful wrapped payload with a 400 status code.
3. Write test cases targeting security controls. Verify that anonymous or low-privilege sessions get rejected with 401 or 403 status codes.

### Step 5: Write Error and Exception Paths
1. Test how the system behaves when external services are unavailable or throw exceptions (e.g., database concurrency issues).
2. For database concurrency:
   - Set `ThrowConcurrencyOnSave = true` on the database context and verify that the handler returns a 409 status code with a descriptive error message:
     ```csharp
     scope.DbContext.ThrowConcurrencyOnSave = true;
     var result = await handler.Handle(command, CancellationToken.None);
     result.IsSuccessful.Should().BeFalse();
     result.StatusCode.Should().Be(409);
     ```

### Step 6: Execute and Verify
1. Run the specific test locally:
   ```powershell
   dotnet test --filter FullyQualifiedNameOfTestClass
   ```
2. Verify that the test passes, logging is clean, and database changes are rolled back cleanly.

---

## Expected Outcome (Definition of Done)
- Test class created in the correct test project, matching the source project directory structure.
- Happy path, validation edge cases, authorization limits, and database error scenarios covered.
- Tests use standard testing fixtures (`CategoryHandlerTestSupport`, `CustomWebApplicationFactory`) for database isolation.
- All tests execute and pass successfully.

---

## Troubleshooting & Rollback

### Common Testing Pitfalls:
- **Test Interference:** If tests fail when run in parallel, verify that you aren't referencing shared static database instances. Ensure each test run utilizes isolated connection parameters or databases.
- **SQL Server Connection Errors:** If integration tests fail to connect, verify that SQL Server is running and matches the connection details in `appsettings.Testing.json`.

### Rollback Process
To undo testing updates:
- Delete the created test class file from the test project.
- Clean up any dummy test data seeds added to test fixtures.
