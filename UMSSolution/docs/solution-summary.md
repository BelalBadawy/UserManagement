# UMS Solution Summary

UMSSolution is a layered user management platform built mainly with .NET. The backend is organized into clear API, Application, Domain, and Infrastructure projects, with separate test projects for each backend layer. There is also a `UMS.Client` frontend project, but it is not currently included in the solution file.

The API project exposes endpoints for accounts, users, roles, categories, and audit trails. Startup wiring shows support for OpenAPI documentation, bearer authentication, CORS, rate limiting for auth-related traffic, centralized error handling, static files, and API versioning.

The Application layer contains the use-case logic and cross-cutting behaviors. It is wired with Mediator, FluentValidation, and Mapster, which suggests a CQRS-style flow where requests are validated and mapped before reaching handlers and services.

The Domain layer holds the core business model, including entities, enums, common types, and interfaces. The Infrastructure layer provides technical implementations such as database access, identity/authentication services, permissions, JWT setup, caching, email delivery, file storage, current-user access, and database seeding.

At a high level, the solution appears designed for secure user and access management, with emphasis on authentication flows, role/category management, auditability, and maintainable separation of concerns.

## Tech Stack

- Backend: .NET 10 and ASP.NET Core Web API
- Architecture: layered API, Application, Domain, and Infrastructure projects
- API tooling: ASP.NET OpenAPI, Scalar, and API versioning
- Application patterns: Mediator, FluentValidation, and Mapster
- Data access: Entity Framework Core 10
- Databases: SQL Server, SQLite, and InMemory
- Security: ASP.NET Core Identity, JWT bearer authentication, CORS, and rate limiting
- Supporting services: distributed memory cache, FluentEmail SMTP integration, local file storage, and audit trail services
- Frontend: React 19, TypeScript, and Vite
- Frontend UI/tooling: Tailwind CSS 4, Radix UI, TanStack React Table, React Router, Lucide, and ESLint
- Testing: dedicated test projects for API, Application, Domain, and Infrastructure
