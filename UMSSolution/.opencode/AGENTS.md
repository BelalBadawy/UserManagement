# AGENTS.md

# IMPORTANT
Whenever a new conversation begins do NEVER just start to code (There is no other exceptions to this rule!) - Instead do the following steps:
1. Find `Available $skills` and `Available information tools` that are relevant for the task and read their details.
2. Investigate the code-base for existing implementation details.
3. Think about the question/task, and what might be unclear for the implementation.
4. Finally ask the user 3-20 clarifying questions in a **numbered list** (NEVER PRESENT THEM AS JUST BULLETS; EACH QUESTION NEED A NUMBER). 

Once these questions are answered, you can begin coding (for follow-ups, you should not do this)

---


## Solution Structure

Clean Architecture with 4 layers + tests:
- `UMSSolution/UMS.API` - Web API (entrypoint)
- `UMSSolution/UMS.Application` - CQRS handlers, validators
- `UMSSolution/UMS.Domain` - Entities, no external deps
- `UMSSolution/UMS.Infrastructure` - EF Core, Hangfire, email
- `UMSSolution/UMS.Tests` - Unit tests
- `UMSSolution/UMS.IntegrationTests` - Integration tests

Dependencies flow inward only: API → Application → Domain

## Build & Run

```powershell
cd UMSSolution
dotnet build
dotnet run --project UMS.API
```

## Testing

```powershell
dotnet test                           # all tests
dotnet test --project UMS.Tests       # unit tests only
dotnet test --project UMS.IntegrationTests  # integration tests
```

## Key Technologies

- ASP.NET Core 10
- CQRS via Mediator.SourceGenerator
- EF Core with SQL Server
- FluentValidation
- JWT + Refresh Tokens
- Hangfire for background jobs
- IMemoryCache for permissions

## API Access

- Swagger: `/swagger` when running
- Health: `/health/live`, `/health/ready`
- Versioned routes: `/api/v1/...`