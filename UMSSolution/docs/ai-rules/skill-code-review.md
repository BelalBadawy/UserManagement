# Skill: Code Review

**Type:** Skill  
**Applies To:** All  
**When to Use:** Use this checklist when performing code reviews (both for AI self-reviews and human developer code reviews) prior to merging PRs.

---

## Related Rules
- [00-INDEX.md](file:///d:/_MyFolder/MyWorkSpace/UserManagement/UMSSolution/docs/ai-rules/00-INDEX.md) (Master index of all conventions and architectural rules)

---

## Procedural Workflow

### Step 1: Understand the Context
1. Read the Pull Request description, associated tickets, and spec updates.
2. Confirm you understand the functional goals, user flows, and affected subsystems before reviewing any file changes.

### Step 2: Verify Architecture & Layering Rules
Verify references and folder layout configurations match [01-backend-architecture.md](file:///d:/_MyFolder/MyWorkSpace/UserManagement/UMSSolution/docs/ai-rules/01-backend-architecture.md):
- **References Check:** Ensure `Domain` and `Application` contain no references to concrete layers (such as `Infrastructure` or `API`).
- **Framework Banishments:** Confirm no `MediatR` dependencies or `ControllerBase` inheritances were introduced.
- **CQRS Layout:** Ensure features are organized under `Features/{FeatureName}/Commands/` or `Features/{FeatureName}/Queries/` directories.

### Step 3: Verify Backend Coding and Validation Standards
Verify implementation logic follows [02-backend-coding-standards.md](file:///d:/_MyFolder/MyWorkSpace/UserManagement/UMSSolution/docs/ai-rules/02-backend-coding-standards.md):
- **Naming Style:** Verify PascalCase and async suffixes are used correctly.
- **Endpoint Definitions:** Ensure no `[Route]` or `[Authorize]` attributes exist. Check that routing uses Minimal API extension maps.
- **Validation Pipeline:** Check that commands and queries requiring validation implement `IValidateMe`, and validation logic is encapsulated in FluentValidation validator classes (no validation in handlers).
- **Response Wrapper:** Verify that all routes return wrapped payload envelopes (`ResponseWrapper<T>`).

### Step 4: Verify Database & Infrastructure Implementations
Verify database mappings match [03-backend-data-and-infrastructure.md](file:///d:/_MyFolder/MyWorkSpace/UserManagement/UMSSolution/docs/ai-rules/03-backend-data-and-infrastructure.md):
- **EF Configurations:** Ensure entity mappings are defined in separate configuration classes (not inline inside `ApplicationDbContext.OnModelCreating`).
- **Context Access:** Confirm handlers use `IApplicationDbContext` for database queries (not direct `ApplicationDbContext` injections).
- **Multi-DB Safety:** Check for raw SQL queries. Ensure queries are compatible with SQL Server, SQLite, and InMemory.

### Step 5: Verify Security Constraints
Verify access guards match [04-backend-security.md](file:///d:/_MyFolder/MyWorkSpace/UserManagement/UMSSolution/docs/ai-rules/04-backend-security.md):
- **Endpoint Authorization:** Confirm routes require authorization policies (`.RequireAuthorization(AppPermission.NameFor(...))`).
- **Data Protection:** Verify user parameters and PII are excluded from audit logging outputs.
- **Safe Storage:** Ensure uploaded files are validated and stored using `IFileStorageService`.

### Step 6: Verify Frontend Architecture & State Conventions
Verify React client components follow [05-frontend-architecture.md](file:///d:/_MyFolder/MyWorkSpace/UserManagement/UMSSolution/docs/ai-rules/05-frontend-architecture.md):
- **State Separation:** Ensure server state uses TanStack Query, grid rendering uses TanStack Table, and local view state uses `useState`.
- **API client layering:** Confirm components NEVER invoke the base client (`api-client.ts`) directly. They must use custom hooks wrapping feature API modules.
- **Radix UI Accessibility:** Verify components use Radix primitives and provide descriptive ARIA tags.

### Step 7: Verify Testing Implementations
Verify test coverage matches [07-testing-standards.md](file:///d:/_MyFolder/MyWorkSpace/UserManagement/UMSSolution/docs/ai-rules/07-testing-standards.md):
- **Independent Context:** Ensure tests run in isolation and do not share mutating data.
- **Test Helpers:** Confirm handler unit tests use SQLite test scopes and API tests use `CustomWebApplicationFactory`.

---

## Expected Outcome (Definition of Done)
- Pull Request audited against the structural checklists.
- Feedback generated detailing rule violations.
- Code conforms to all guidelines.

---

## Troubleshooting & Resolution
- **If violations are identified:** Do not bypass constraints. Flag the specific lines and detail the corresponding rules.
- **Re-Review Process:** After updates are committed, run through the verification checks again to ensure no regressions are introduced.
