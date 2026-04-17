# Infrastructure & Data Layer

## Entity Framework Core Standards
- Integer Identity: All tables use int-based PK
- Standard Audit Fields: CreatedBy (int?), CreatedAt (datetime2), ModifiedBy (int?), ModifiedAt (datetime2)
- Concurrency: Every entity has RowVersion (byte[]) for optimistic concurrency
- Soft Delete: IsDeleted (bit), DeletedAt, DeletedBy + global query filter

## EF Core Performance
- AsNoTracking() by default for read-only queries (Get[Entity]Query)
- AsSplitQuery() for queries with multiple Include() collections
- ExecuteUpdateAsync/ExecuteDeleteAsync for bulk operations
- EF.CompileAsyncQuery for high-throughput read paths

## Hangfire Background Jobs
- Fire-and-forget, scheduled, delayed jobs offloaded to Hangfire
- Jobs triggered via interfaces in Domain/Application, implemented in Infrastructure

## Caching (IMemoryCache)
- Role-to-Claim mappings, dynamic permissions, rate limiting counters
- Invalidate cache programmatically when Admins update roles/claims

## Specification Pattern
- Complex EF Core queries encapsulated in reusable Specification class
- Prevents query logic bleeding into Application layer

## Outbox Background Processing
- Hangfire processes OutboxMessages (serialized Domain Events)
- Guarantees event dispatching even if API crashes after transaction