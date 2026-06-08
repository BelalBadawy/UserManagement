# UMS Developer Rules and Skills Master Index

**Type:** Rule  
**Applies To:** All  
**When to Use:** Always refer to this master index to locate relevant guidelines, architectural rules, coding standards, and procedural skills.

This index maps the development standards and procedural workflows established for the User Management System (UMS) codebase.

| File Name | Type | Applies To | Summary |
| :--- | :--- | :--- | :--- |
| **Last Updated: 2026-06-08** | - | - | Playbook last revised date. |
| [00-INDEX.md](00-INDEX.md) | Rule | All | A master index serving as the table of contents for all architectural rules and skill workflows. |
| [01-backend-architecture.md](01-backend-architecture.md) | Rule | Backend | Enforces project dependency directions, layer boundaries, CQRS layouts, and Martinothamar's Mediator. |
| [02-backend-coding-standards.md](02-backend-coding-standards.md) | Rule | Backend | Defines C# syntax styles, Minimal API extensions, pipeline validation, Mapster mappings, and ResponseWrapper contracts. |
| [03-backend-data-and-infrastructure.md](03-backend-data-and-infrastructure.md) | Rule | Backend | Dictates EF Core configurations, migration workflows, DbContext abstraction, Identity services, and database providers. |
| [04-backend-security.md](04-backend-security.md) | Rule | Backend | Outlines auth rate-limiting, JWT parameters, the AppPermission model, file uploads, and PII protection. |
| [05-frontend-architecture.md](05-frontend-architecture.md) | Rule | Frontend | Specifies Vite/React folder structures, TypeScript interfaces, router configs, and state separation rules. |
| [06-frontend-coding-standards.md](06-frontend-coding-standards.md) | Rule | Frontend | Sets frontend naming conventions, memoization, controlled forms, API client layering, and accessibility guides. |
| [07-testing-standards.md](07-testing-standards.md) | Rule | Testing | Outlines test naming patterns, unit testing scopes (SQLite), integration testing scopes (SQL Server), and RTL boundaries. |
| [08-project-conventions.md](08-project-conventions.md) | Rule | All | Covers Git conventional commits, API version sets, Scalar OpenAPI documentation, mutation audit logs, and performance rules. |
| [skill-add-new-api-endpoint.md](skill-add-new-api-endpoint.md) | Skill | Backend | Step-by-step procedural workflow for introducing a new Mediator command or query endpoint. |
| [skill-add-new-entity.md](skill-add-new-entity.md) | Skill | Backend | Guide to creating a domain entity, mapping configurations, generating migrations, and scaffolding CRUD. |
| [skill-add-new-frontend-feature.md](skill-add-new-frontend-feature.md) | Skill | Frontend | Steps to introduce new UI pages or features using TanStack Query, React Router, and component patterns. |
| [skill-add-auth-flow.md](skill-add-auth-flow.md) | Skill | All | Workflow for introducing a permission claim, seeding baseline roles, protecting endpoints, and wrapping client routes. |
| [skill-add-database-migration.md](skill-add-database-migration.md) | Skill | Backend | Actionable steps to generate, test, apply, and rollback EF Core migrations. |
| [skill-debug-and-fix.md](skill-debug-and-fix.md) | Skill | All | Standard checklist and pipeline for diagnosing, localizing, fixing, and writing regression tests for bugs. |
| [skill-testing-workflow.md](skill-testing-workflow.md) | Skill | Testing | Procedural workflow for designing and writing unit, integration, and RTL tests. |
| [skill-code-review.md](skill-code-review.md) | Skill | All | Diagnostic checklist for checking code structure, security, performance, client state, and coding quality. |
