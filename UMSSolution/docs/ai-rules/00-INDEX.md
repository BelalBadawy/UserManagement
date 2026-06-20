# UMS Developer Rules and Skills Master Index

**Type:** Rule  
**Applies To:** All  
**When to Use:** Always refer to this master index to locate relevant guidelines, architectural rules, coding standards, and procedural skills.

This index maps the development standards and procedural workflows established for the User Management System (UMS) codebase.

| File Name | Type | Applies To | Summary |
| :--- | :--- | :--- | :--- |
| **Last Updated: 2026-06-10** | - | - | Playbook last revised date. |
| [00-INDEX.md](00-INDEX.md) | Rule | All | A master index serving as the table of contents for all architectural rules and skill workflows. |
| [01-backend-architecture.md](01-backend-architecture.md) | Rule | Backend | Enforces project dependency directions, layer boundaries, CQRS layouts, and Martinothamar's Mediator. |
| [02-backend-coding-standards.md](02-backend-coding-standards.md) | Rule | Backend | Defines C# syntax styles, Minimal API extensions, pipeline validation, and ResponseWrapper contracts. |
| [03-backend-data-and-infrastructure.md](03-backend-data-and-infrastructure.md) | Rule | Backend | Dictates EF Core configurations, migration workflows, DbContext abstraction, Identity services, and database providers. |
| [04-backend-security.md](04-backend-security.md) | Rule | Backend | Outlines auth rate-limiting, JWT parameters, the AppPermission model, file uploads, and PII protection. |
| [05-frontend-architecture.md](05-frontend-architecture.md) | Rule | Frontend | Specifies Vite/React folder structures, TypeScript interfaces, router configs, and state separation rules. |
| [06-frontend-coding-standards.md](06-frontend-coding-standards.md) | Rule | Frontend | Sets frontend naming conventions, memoization, controlled forms, API client layering, and accessibility guides. |
| [07-testing-standards.md](07-testing-standards.md) | Rule | Testing | Outlines test naming patterns, unit testing scopes (SQLite), integration testing scopes (SQL Server), and RTL boundaries. |
| [08-project-conventions.md](08-project-conventions.md) | Rule | All | Covers Git conventional commits, API version sets, Scalar OpenAPI documentation, mutation audit logs, and performance rules. |
| [skill-add-new-api-endpoint.md](skill-add-new-api-endpoint.md) | Skill | Backend | Workflow for introducing a Mediator command/query, mapping paged result structures, and implementing ClosedXML/QuestPDF file exports. |
| [skill-add-new-entity.md](skill-add-new-entity.md) | Skill | Backend | Guide to creating a domain entity, defining database mappings (unique indexes and rowversion type), and handling two-phase transaction saves. |
| [skill-add-new-frontend-feature.md](skill-add-new-frontend-feature.md) | Skill | Frontend | Steps to add React pages using URL search parameters state, controlled Radix inputs, api-client, and TanStack optimistic status updates. |
| [skill-add-auth-flow.md](skill-add-auth-flow.md) | Skill | All | Workflow for introducing permission constants, understanding PermissionPolicyProvider policy resolution, and route-level silent refresh guards. |
| [skill-add-database-migration.md](skill-add-database-migration.md) | Skill | Backend | Actionable steps to generate, apply, and rollback migrations, standardizing unique index names (UX_ prefix) and SQL Server test setups. |
| [skill-debug-and-fix.md](skill-debug-and-fix.md) | Skill | All | Standard pipeline for localizing bugs, handling ErrorHandlingMiddleware status code maps (400, 401, 404, 409), and regression testing. |
| [skill-testing-workflow.md](skill-testing-workflow.md) | Skill | Testing | Procedural workflow for unit testing, integration tests, and scaffolding custom `{Entity}HandlerTestScope` supports using SQLite. |
| [skill-code-review.md](skill-code-review.md) | Skill | All | Checklist aligned 1:1 with architectural Rules 01-08 for auditing Pull Requests before merging. |
