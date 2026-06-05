You are analyzing the UMS (User Management System) codebase. Your task is to produce TWO categories of artifacts:

1. RULES FILES — declarative constraints, conventions, and standards the codebase must follow
2. SKILL FILES — procedural step-by-step workflows for common development tasks (including detailed testing and code review procedures)

After analyzing the codebase structure, existing patterns, naming conventions, project references, dependency injection wiring, middleware pipelines, CQRS handler patterns, validation patterns, mapping patterns, entity definitions, EF Core configurations, React component patterns, state management, routing, and styling conventions, produce ALL of the files listed below.

Every rule and skill must be derived from what you actually observe in the codebase. Where the codebase is silent, apply the established best practice for that technology. Never invent conventions that contradict existing code.

---

## PART 1: RULES FILES TO GENERATE

### File 1: `docs/ai-rules/01-backend-architecture.md`
Generate a rule file covering:
- Project dependency direction (API → Application → Domain, Infrastructure → Application → Domain, Infrastructure → Domain; never the reverse)
- What belongs in each layer: API (controllers, middleware, startup wiring), Application (handlers, validators, DTOs, mappings, behaviors), Domain (entities, enums, interfaces, value objects, domain events), Infrastructure (EF DbContext, repositories, Identity, JWT, email, file storage, caching, seeding)
- Forbidden patterns: no domain logic in controllers, no EF Core types in Application or Domain, no business logic in Infrastructure, no direct DbContext usage from API controllers
- Mediator/CQRS conventions: every use case is a separate request, handlers are one-per-request, no handler does two things
- Naming conventions for requests: {Verb}{Noun}Command or {Verb}{Noun}Query (e.g., CreateUserCommand, GetUsersQuery)
- File organization: one request+handler+validator per folder or per feature

### File 2: `docs/ai-rules/02-backend-coding-standards.md`
Generate a rule file covering:
- C# naming: PascalCase for public members, _camelCase for private fields, async methods must end in Async
- Required attributes: [Authorize] on controllers that need auth, [ProducesResponseType] on all endpoints, [ApiVersion] on all controllers
- Validation: every Command must have a corresponding FluentValidation validator; validators must be registered via assembly scanning; never validate in handlers
- Mapping: use Mapster Config adapter pattern; never manually map in handlers; define mappings in the Application layer configuration
- Error handling: never throw raw exceptions from handlers; use Result<T> or custom domain exceptions; let the API middleware convert to ProblemDetails
- Response patterns: all API responses use consistent envelope (problem details for errors, typed DTOs for success)
- Logging: use ILogger<T>, never Console.WriteLine; structured logging with named parameters
- Async: all I/O operations must be async; never .Result, .Wait(), or GetAwaiter().GetResult()

### File 3: `docs/ai-rules/03-backend-data-and-infrastructure.md`
Generate a rule file covering:
- EF Core conventions: entity configurations in separate IEntityTypeConfiguration<T> classes; no fluent API in DbContext.OnModelCreating directly
- Migrations: always generate migrations for schema changes; never modify migrations by hand unless fixing a bug; name migrations descriptively
- Repository pattern conventions: if used, define interfaces in Domain, implement in Infrastructure; if not used, encapsulate all queries in handlers with IQueryable via DbContext
- Identity: all user/role management through the defined Identity services in Infrastructure; never access UserManager directly from handlers or controllers
- Seeding: all seed data in the seeding service; idempotent seeding only; never seed in migrations
- Connection strings and secrets: never hardcode; always from configuration; user secrets in dev, env vars in prod
- Multi-database support: ensure all queries work across SQL Server, SQLite, and InMemory; no raw SQL unless absolutely necessary and guarded by provider check

### File 4: `docs/ai-rules/04-backend-security.md`
Generate a rule file covering:
- Authentication: all auth endpoints must have rate limiting applied; JWT must use the configured issuer/audience/keys from configuration
- Authorization: use role-based and/or policy-based auth as defined; never roll custom auth checks in handlers
- CORS: configure allowed origins from configuration only; never use AllowAnyOrigin in production
- Input validation: validate all inputs at the API layer (FluentValidation) AND at domain level (domain invariants/guards); defense in depth
- Sensitive data: never log passwords, tokens, or PII; never return internal error details in production responses
- File uploads: validate file type, size, and name; store via the configured IFileStorageService; never save directly to disk from a controller

### File 5: `docs/ai-rules/05-frontend-architecture.md`
Generate a rule file covering:
- Project structure: pages/, components/ (shared vs feature-scoped), hooks/, services/, types/, utils/, routes/
- Component conventions: functional components only; named exports; one component per file; component file name matches component name in PascalCase
- Type safety: all API responses and requests must have TypeScript interfaces; never use any; use Zod or similar for runtime validation of API responses if observed in codebase
- Routing: all routes defined in a central router config; lazy-loaded route components; route params typed
- State management: server state via TanStack Query; local/UI state via React state; never duplicate server state in local state
- Styling: Tailwind utility classes only; no inline styles; extract repeated patterns into shared components; use Radix UI primitives for accessible interactive elements
- Icons: Lucide icons only; consistent sizing

### File 6: `docs/ai-rules/06-frontend-coding-standards.md`
Generate a rule file covering:
- Naming: PascalCase for components and types, camelCase for functions and variables, UPPER_SNAKE_CASE for constants
- Hooks: custom hooks prefixed with "use"; hooks must not return complex objects that change reference every render without memoization
- Props: define prop interfaces inline or co-located; use readonly where possible; destructured in function signature
- Error boundaries: every page-level component wrapped or near an error boundary
- API calls: centralized in a service layer; never call fetch/axios directly from components; use TanStack Query hooks wrapping the service calls
- Forms: controlled components; validation on blur and submit; display field-level errors
- Accessibility: all interactive elements keyboard-navigable; use Radix primitives which handle this; always provide aria labels where Radix doesn't
- ESLint: zero warnings allowed; all rules observed

### File 7: `docs/ai-rules/07-testing-standards.md`
Generate a rule file covering the *standards and conventions* for testing:
- Test project mapping: one test project per source project; test namespace mirrors source namespace
- Naming: {MethodName}_{Scenario}_{Expected} (e.g., CreateUser_WithDuplicateEmail_ReturnsConflict)
- Unit test boundaries: test Application handlers with mocked dependencies (Mediator pipeline behaviors excluded); test Domain entities and value objects with no mocks; test Infrastructure services with integration or mocked external deps
- Integration test boundaries: test API endpoints with WebApplicationFactory; test EF queries with real database (SQLite or InMemory); test the full pipeline for critical flows (register, login, role assignment)
- Frontend test boundaries: test hooks with renderHook; test components with RTL; test user interactions not implementation details; mock API at the service layer
- Structure: Arrange-Act-Assert pattern always
- Isolation: No test interdependence; each test sets up its own state
- Data generation: Use builder/factory pattern for test data; never manually construct complex objects in every test

### File 8: `docs/ai-rules/08-project-conventions.md`
Generate a catch-all rule file covering:
- Git: conventional commits (feat:, fix:, chore:, refactor:, test:, docs:); never commit directly to main; PR descriptions must reference the issue
- API versioning: new endpoints must declare version; breaking changes get a new major version
- OpenAPI: all endpoints must have summary, description, and response types documented
- Audit trails: all mutations to users, roles, and categories must create audit log entries via the audit service; never audit reads
- Performance: no N+1 queries; all list endpoints must support pagination; all async; cache reference data

---

## PART 2: SKILL FILES TO GENERATE

### File 9: `docs/ai-rules/skill-add-new-api-endpoint.md`
Generate a step-by-step procedural workflow:
1. Define the request type (Command or Query) in Application
2. Define the response DTO in Application
3. Create the FluentValidation validator in Application
4. Create the Mapster mapping configuration if new entity-to-DTO mapping needed
5. Implement the handler in Application
6. Register the request in Mediator assembly scanning (if manual registration is used)
7. Create the controller endpoint in API with proper attributes
8. Add API version annotation
9. Add OpenAPI documentation attributes
10. Write unit test for handler
11. Write integration test for endpoint
12. Verify the endpoint appears in Scalar/OpenAPI UI
13. Manual smoke test

### File 10: `docs/ai-rules/skill-add-new-entity.md`
Generate a step-by-step procedural workflow:
1. Define the entity class in Domain with properties, constructors, and domain invariants
2. Define any value objects or enums in Domain
3. Define the repository interface in Domain (if repository pattern is used)
4. Create the IEntityTypeConfiguration<T> in Infrastructure
5. Register the entity in DbContext DbSet
6. Add any domain event definitions if applicable
7. Generate and review the EF Core migration
8. Apply migration to dev database and verify schema
9. Add seed data in seeding service if applicable
10. Create the CRUD Command/Query set in Application
11. Create validators for each Command
12. Create mappings
13. Implement handlers
14. Create API controller endpoints
15. Write all tests (unit for entity logic, unit for handlers, integration for endpoints, integration for DB queries)
16. Add audit trail integration for mutations

### File 11: `docs/ai-rules/skill-add-new-frontend-feature.md`
Generate a step-by-step procedural workflow:
1. Define TypeScript interfaces for the API request and response in types/
2. Create the API service function(s) in services/
3. Create TanStack Query hooks (useQuery for reads, useMutation for writes) in hooks/
4. Create the page component in pages/
5. Create any feature-specific sub-components in components/
6. Implement form handling and validation for any forms
7. Add the route to the router configuration
8. Add navigation entry if needed
9. Handle loading states, error states, and empty states
10. Ensure accessibility (keyboard nav, aria labels, focus management)
11. Write component tests
12. Write hook tests
13. Manual visual review
14. Test responsive behavior

### File 12: `docs/ai-rules/skill-add-auth-flow.md`
Generate a step-by-step procedural workflow for adding or modifying an authentication/authorization flow:
1. Identify the auth requirement (new endpoint? new role? new policy? new flow like 2FA?)
2. If new role/claim: add to role/category seed data; update role constants
3. If new policy: register in API startup/extension method
4. If new endpoint with auth: apply [Authorize] with appropriate policy/roles
5. If new auth flow: implement in Infrastructure auth service; add new handler in Application; add new endpoint in API; ensure rate limiting applies
6. Update JWT claims if new claims needed
7. Test: verify unauthenticated access is rejected; verify wrong role is rejected; verify correct access succeeds; verify token contains new claims
8. Frontend: update auth context/hook; update route guards; update login/register forms if needed
9. Audit: ensure auth events are auditable

### File 13: `docs/ai-rules/skill-add-database-migration.md`
Generate a step-by-step procedural workflow:
1. Make the entity or configuration changes
2. Verify the changes compile
3. Generate migration with descriptive name
4. Review the generated Up and Down methods
5. Verify idempotency (running twice should not fail)
6. Test migration against clean database
7. Test migration against existing database with data
8. Verify Down method rolls back cleanly
9. Commit migration with entity changes together in one commit
10. If seed data changed, update seeding service, not the migration

### File 14: `docs/ai-rules/skill-debug-and-fix.md`
Generate a step-by-step procedural workflow:
1. Reproduce the issue (write a failing test first if possible)
2. Identify the layer: is it API routing, Application logic, Domain invariant, Infrastructure/data, Frontend state/rendering, or Frontend API call?
3. Fix at the correct layer — do not work around a Domain bug by patching the API layer
4. Verify the fix doesn't break existing tests
5. Add a regression test that would have caught the original bug
6. Run the full test suite
7. Check for similar patterns elsewhere in the codebase that might have the same bug

### File 15: `docs/ai-rules/skill-testing-workflow.md`
Generate a detailed, step-by-step procedural workflow specifically for writing tests. This is the go-to process whenever the agent or a developer needs to test a feature:
1. Identify the test scope: Is this a Domain unit test, Application handler test, Infrastructure integration test, API endpoint test, or Frontend component/hook test?
2. Create the test file in the correct test project, mirroring the source folder structure.
3. Set up the test class: constructor setup for common mocks (e.g., DbContext, Mediator, ILogger), test data builders.
4. Write the first test case (Happy Path): Arrange necessary data, Act on the system, Assert the expected outcome.
5. Write the edge cases and validation failures: e.g., duplicate entities, missing required fields, unauthorized access.
6. Write the error/exception paths: e.g., database connection failure, external service unavailable.
7. For Integration/API tests: use WebApplicationFactory, ensure a clean database state per test, test the full HTTP pipeline (status codes, response body structure, headers).
8. For Frontend tests: use Testing Library, query by role/text (not test-id if possible), test user interactions (clicks, form inputs), assert loading/error/success states.
9. Run the specific test locally and ensure it passes.
10. Run the broader test suite to ensure no regressions.
11. Review test for readability: Can a new developer understand the scenario without asking the author?

### File 16: `docs/ai-rules/skill-code-review.md`
Generate a comprehensive, step-by-step procedural workflow for performing a code review (both for AI self-review and human review guidelines):
1. Understand the context: Read the PR description and linked issue. What is the goal?
2. Review architecture & layering: Are changes in the correct projects? Are dependency directions respected? (API → App → Domain). Is logic leaking into the wrong layer?
3. Review security & auth: Are new endpoints properly authorized? Is input validated at the API and Domain levels? Are there any SQL injection risks, or PII/sensitive data in logs?
4. Review backend implementation: Are CQRS conventions followed? Is validation in FluentValidation, not handlers? Is mapping using Mapster? Are domain invariants enforced?
5. Review database changes: Is the EF migration safe? Is there data loss? Are queries optimized (no N+1, proper pagination)?
6. Review frontend implementation: Are TypeScript types used (no `any`)? Is server state in TanStack Query? Are components accessible (Radix UI)? Are loading/error states handled?
7. Review testing: Are there tests for the new code? Do tests follow the naming convention? Are edge cases covered? Are integration tests used where appropriate?
8. Review cleanliness: No commented-out code, no leftover TODOs, no console.logs, proper naming conventions, no magic strings.
9. Provide constructive feedback: If issues found, explain *why* it's an issue and suggest the correct pattern based on the project rules.
10. Final approval: Confirm all CI checks pass, all conversations are resolved, and the code aligns with all Rules Files before approving.

---

## OUTPUT FORMAT

For each file, output in the following format:

Use standard Markdown content within each file. At the top of every file, include a standardized header block like this:
[Rule/Skill Name]
Type: Rule / Skill
Applies To: [e.g., Backend, Frontend, Testing, All]
When to Use: [e.g., "Apply strictly to all C# files", "Follow this process when adding a new database table"]

Before generating each file, briefly state what you observed in the codebase that informed the rules in that file.

After all files are generated, provide a SUMMARY section listing:
- Total number of rules files
- Total number of skill files
- Any areas where the codebase was ambiguous and you had to make assumptions (and what those assumptions were)
- A brief guide on how the user can integrate these files into their specific AI IDE (e.g., referencing the folder in `.github/copilot-instructions.md`, `CLAUDE.md`, `.cursorrules`, or `.windsurfrules`)