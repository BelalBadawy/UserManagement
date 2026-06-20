# Skill: Testing Workflow

**Type:** Skill  
**Applies To:** Testing  
**When to Use:** Use this process when writing unit tests for handlers, integration tests for API endpoints, or React frontend component tests.

---

## Related Rules
- [07-testing-standards.md](docs/ai-rules/07-testing-standards.md) (Test namespaces, project mapping rules, test boundary conditions)

---

## Real Example Reference
- **Category Unit Testing support**: [UMS.Application.Tests/Support/Categories/CategoryHandlerTestSupport.cs](UMS.Application.Tests/Support/Categories/CategoryHandlerTestSupport.cs)
- **Category Handler Unit Tests**: [UMS.Application.Tests/Handlers/Categories/CategoryCommandHandlerTests.cs](UMS.Application.Tests/Handlers/Categories/CategoryCommandHandlerTests.cs)
- **API Endpoint Integration Tests**: [UMS.API.Tests/Endpoints/CategoryEndpointsTests.cs](UMS.API.Tests/Endpoints/CategoryEndpointsTests.cs)

---

## Procedural Workflow

### Step 1: Identify Test Scope
Determine what category of test to write based on the feature changes:
- **Domain Unit Test:** Fast validation checks of domain model calculations and state transitions. No mocks.
- **Application Handler Unit Test:** Uses SQLite in-memory test databases (`CategoryHandlerTestSupport.cs`) to verify database write transactions and Mediator Command/Query outputs. Mocks external services.
- **API Endpoint Integration Test:** Uses `CustomWebApplicationFactory` to spin up a local ASP.NET test server and call routes using `Client`. Runs against a real test database (SQL Server) to verify routing, authorization policies, and middleware handlers.
- **Frontend RTL Test:** Uses React Testing Library to verify component rendering and user actions. Mocks API calls.

### Step 2: Scaffold Unit Test Support Fixture
When testing handlers for a new entity, developers must scaffold a custom `{Entity}HandlerTestScope` and `{Entity}HandlerTestDbContext` mirroring the categories pattern:

1. **Create Supporting File**: Create `{Entity}HandlerTestSupport.cs` under the namespace `UMS.Application.Tests.Support.{FeatureName}s;`.
2. **Implement Test DbContext**:
   Create a test DbContext that inherits from `DbContext` and implements `IApplicationDbContext`. It must map the SQLite-compatible schemas and mock transaction APIs:
   ```csharp
   internal sealed class ProductHandlerTestDbContext : DbContext, IApplicationDbContext
   {
       private static readonly JsonSerializerOptions SerializerOptions = new(JsonSerializerDefaults.Web);

       public ProductHandlerTestDbContext(DbContextOptions<ProductHandlerTestDbContext> options)
           : base(options) { }

       public bool ThrowConcurrencyOnSave { get; set; }

       // Core DbSets from interface
       public DbSet<Product> Products => Set<Product>();
       public DbSet<Category> Categories => Set<Category>();
       public DbSet<AuditTrail> AuditTrails => Set<AuditTrail>();
       public DbSet<LogUserActivity> LogUserActivities => Set<LogUserActivity>();
       public DbSet<OutboxMessage> OutboxMessages => Set<OutboxMessage>();

       // Mock transactions as completed tasks
       public Task StartTransaction(CancellationToken cancellationToken = default) => Task.CompletedTask;
       public Task CommitTransaction(CancellationToken cancellationToken = default) => Task.CompletedTask;
       public Task RollbackTransaction(CancellationToken cancellationToken = default) => Task.CompletedTask;

       public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
       {
           if (ThrowConcurrencyOnSave)
           {
               ThrowConcurrencyOnSave = false; // Reset to prevent infinite loops
               throw new DbUpdateConcurrencyException();
           }
           return base.SaveChangesAsync(cancellationToken);
       }

       public void AddOutboxMessage<TNotification>(TNotification notification) where TNotification : class
       {
           var notificationType = notification.GetType();
           OutboxMessages.Add(new OutboxMessage
           {
               Type = notificationType.AssemblyQualifiedName ?? notificationType.FullName ?? notificationType.Name,
               Payload = JsonSerializer.Serialize(notification, notificationType, SerializerOptions),
               OccurredOnUtc = DateTime.UtcNow
           });
       }

       public void SetOriginalRowVersion<TEntity>(TEntity entity, byte[] rowVersion) where TEntity : class, IDataConcurrency
       {
           Entry(entity).Property(x => x.RowVersion).OriginalValue = rowVersion;
       }

       protected override void OnModelCreating(ModelBuilder modelBuilder)
       {
           // Explicitly map keys and indices using SQLite-compatible definitions
           modelBuilder.Entity<Product>(builder =>
           {
               builder.ToTable("Products");
               builder.HasKey(x => x.Id);
               builder.Property(x => x.Id).ValueGeneratedOnAdd();
               builder.Property(x => x.RowVersion).IsConcurrencyToken();
               builder.HasQueryFilter(x => !x.SoftDeleted);
           });
           
           modelBuilder.Entity<OutboxMessage>(builder =>
           {
               builder.ToTable("OutboxMessages");
               builder.HasKey(x => x.Id);
           });
       }
   }
   ```
3. **Implement Test Scope**:
   Create a test scope class implementing `IAsyncDisposable` that opens an isolated SQLite in-memory database and registers the `RecordingCacheService` (which records removed and set keys for caching assertions):
   ```csharp
   internal sealed class ProductHandlerTestScope : IAsyncDisposable
   {
       private readonly SqliteConnection _connection;

       private ProductHandlerTestScope(SqliteConnection connection, ProductHandlerTestDbContext dbContext)
       {
           _connection = connection;
           DbContext = dbContext;
           Cache = new RecordingCacheService(); // Records Set/Remove keys for assertion
       }

       public ProductHandlerTestDbContext DbContext { get; }
       public RecordingCacheService Cache { get; }

       public static async Task<ProductHandlerTestScope> CreateAsync()
       {
           var connection = new SqliteConnection("Data Source=:memory:");
           await connection.OpenAsync();

           var options = new DbContextOptionsBuilder<ProductHandlerTestDbContext>()
               .UseSqlite(connection)
               .EnableSensitiveDataLogging()
               .Options;

           var dbContext = new ProductHandlerTestDbContext(options);
           await dbContext.Database.EnsureCreatedAsync();

           return new ProductHandlerTestScope(connection, dbContext);
       }

       public async Task<Product> SeedProductAsync(string name, string code, decimal price)
       {
           var product = new Product
           {
               Name = name,
               Code = code,
               Price = price,
               RowVersion = [1]
           };
           DbContext.Products.Add(product);
           await DbContext.SaveChangesAsync();
           return product;
       }

       public async ValueTask DisposeAsync()
       {
           await DbContext.DisposeAsync();
           await _connection.DisposeAsync();
       }
   }
   ```

### Step 3: Write the Handler Unit Test
1. Create the test class file mirroring the feature namespace (e.g. `CreateProductCommandHandlerTests.cs`).
2. Run tests utilizing the scoped SQLite database context:
   ```csharp
   [Fact]
   public async Task Handle_should_create_product_and_enqueue_outbox_message()
   {
       // Arrange
       await using var scope = await ProductHandlerTestScope.CreateAsync();
       var handler = new CreateProductCommandHandler(scope.DbContext, scope.Cache);
       var command = new CreateProductCommand("Sample Product", "PROD123", 99.99m);

       // Act
       var result = await handler.Handle(command, CancellationToken.None);

       // Assert output wrapper
       result.IsSuccessful.Should().BeTrue();
       result.Data.Should().BeGreaterThan(0);

       // Assert database persistence
       var product = await scope.DbContext.Products.SingleAsync();
       product.Name.Should().Be("Sample Product");

       // Assert cache invalidations
       scope.Cache.RemovedKeys.Should().Contain("products:list");

       // Assert Outbox enqueuing state (eventual consistency assertion)
       var outbox = await scope.DbContext.OutboxMessages.SingleAsync();
       outbox.Type.Should().Contain(nameof(ProductCreatedEvent));
       outbox.Payload.Should().Contain($"\"productId\":{product.Id}");
   }
   ```

### Step 4: Write Edge Cases and Exception Paths
1. **Validator Errors**: Write scenarios asserting that input violations (like missing required fields) fail gracefully and return wrapping error payloads with a 400 status.
2. **Optimistic Concurrency Exceptions**:
   Set `ThrowConcurrencyOnSave = true` on the context and verify that the handler catches EF's concurrency failure and returns a 409 status code with an unsuccessful response wrapper:
   ```csharp
   [Fact]
   public async Task Handle_should_fail_when_update_hits_concurrency_conflict()
   {
       // Arrange
       await using var scope = await ProductHandlerTestScope.CreateAsync();
       var product = await scope.SeedProductAsync("Existing", "EX1", 10m);
       scope.DbContext.ThrowConcurrencyOnSave = true; // Forces exception on SaveChangesAsync
       var handler = new UpdateProductCommandHandler(scope.DbContext, scope.Cache);
       var command = new UpdateProductCommand(product.Id, "Updated Price", 15m, rowVersion: [2]);

       // Act
       var result = await handler.Handle(command, CancellationToken.None);

       // Assert
       result.IsSuccessful.Should().BeFalse();
       result.StatusCode.Should().Be(409);
       result.Messages.Should().Contain(msg => msg.Contains("Concurrency conflict"));
   }
   ```

### Step 5: API Endpoint Integration Test
1. Inherit from `ApiTestBase` and annotate the class with the API test collection:
   ```csharp
   [Collection("API collection")]
   public class ProductEndpointsTests : ApiTestBase
   {
       public ProductEndpointsTests(CustomWebApplicationFactory factory) : base(factory) { }
       
       [Fact]
       public async Task Post_should_return_403_when_role_lacks_permission()
       {
           // Setup client lacking Product.Create permission
           var client = Factory.CreateClientWithRole("Basic");
           var response = await client.PostAsJsonAsync("/api/v1/products", new CreateProductRequest("Name", "CODE1"));
           response.StatusCode.Should().Be(HttpStatusCode.Forbidden);
       }
   }
   ```
2. Integration tests run against the SQL Server test instance configured in `appsettings.Testing.json` via `ApiTestDatabaseInitializer.cs`.

### Step 6: Execute and Verify
1. Run target tests:
   ```powershell
   dotnet test --filter FullyQualifiedNameOfTestClass
   ```

---

## Expected Outcome (Definition of Done)
- Supporting support scope (`{Entity}HandlerTestScope` and `DbContext`) scaffolded under the matching test namespace.
- Happy path, validation edge cases, authorization roles, and database concurrency failures covered.
- SQLite-in-memory databases used for application handler testing; real SQL Server test databases used for integration testing.
- Tests execute and pass successfully.
