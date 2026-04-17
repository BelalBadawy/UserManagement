# Architecture & C# 14 Guidelines

## Clean Architecture
- 4-layer: Domain → Application → Infrastructure → API (Presentation)
- Domain: Pure C# (Entities, Enums, Exceptions, Interfaces). NO external deps
- Application: CQRS, DTOs, Validators. Depends ONLY on Domain
- Infrastructure: EF Core, Hangfire, Cache. Depends on Application + Domain
- API: Minimal APIs, Middlewares, Program.cs. Depends on Infrastructure + Application
- **CRITICAL:** Dependency flow MUST point inward. Domain NEVER references Application or Infrastructure

## SOLID Principles
- SRP: Handlers and Services do one thing
- OCP: Use abstractions/polymorphism, not modifying existing classes
- LSP: Subtypes substitutable for base types
- ISP: Keep interfaces small and focused (e.g., IValidateMe)
- DIP: High-level modules depend on abstractions, not low-level

## C# 14 Standards
- Primary Constructors: Always use for DI
- File-Scoped Namespaces: Must use to save horizontal indentation
- Collection Expressions: Use [] for empty arrays/lists
- Async/Await: Use pervasively. Never block with .Result or .Wait()

## High-Performance (Zero-Allocation)
- Use Span<T> / ReadOnlySpan<T> for sync string/array manipulation
- Use Memory<T> / ReadOnlyMemory<T> for async operations
- Use ArrayPool<T>.Shared.Rent() for large temp buffers

## Value Objects & Domain Modeling
- Value Objects: readonly record struct (stack allocation + value semantics)
- Validate at construction (illegal states unrepresentable)
- **CRITICAL:** DO NOT use implicit operators. All boundary crossings explicit.
- Use Pattern Matching (switch expressions, property patterns)

## Domain Events
- Entities inherit from base Entity class with IReadOnlyCollection<IDomainEvent>
- Entities raise Domain Events instead of executing side effects directly