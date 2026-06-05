# Skill: Debug and Fix

**Type:** Skill  
**Applies To:** All  
**When to Use:** Follow this diagnostic process when troubleshooting bugs, runtime crashes, UI failures, or resolving failing tests.

---

## Related Rules
- [02-backend-coding-standards.md](file:///d:/_MyFolder/MyWorkSpace/UserManagement/UMSSolution/docs/ai-rules/02-backend-coding-standards.md) (Standard errors response envelopes, logging conventions)
- [06-frontend-coding-standards.md](file:///d:/_MyFolder/MyWorkSpace/UserManagement/UMSSolution/docs/ai-rules/06-frontend-coding-standards.md) (Client boundary error boundaries, form handling)
- [07-testing-standards.md](file:///d:/_MyFolder/MyWorkSpace/UserManagement/UMSSolution/docs/ai-rules/07-testing-standards.md) (Test mapping rules, mock scopes, RTL conventions)

---

## Procedural Workflow

### Step 1: Reproduce the Issue
1. Collect the error details (stack traces, logs, network captures, console outputs).
2. Write a failing test first that isolates and reproduces the bug:
   - For backend business rules, add a unit test in the appropriate test project.
   - For API routing or validation, add an integration test case inheriting from `ApiTestBase`.
   - For frontend rendering or state bugs, add an RTL component test.
3. Verify that the newly written test fails under the expected conditions.

### Step 2: Localize the Layer
Trace the execution path to isolate the bug to its target layer:
- **Presentation Layer (UMS.API):** If the routing is wrong, HTTP parameters are ignored, authentication blocks fail, or endpoints throw serialization errors.
- **Application Layer (UMS.Application):** If commands validation fails to run, CQRS routing fails, or business calculations return bad DTO properties.
- **Domain Layer (UMS.Domain):** If entities initialize with invalid states, or core entity validation methods fail to block operations.
- **Infrastructure Layer (UMS.Infrastructure):** If database queries time out, mapping configs are incomplete, SMTP email dispatch fails, or token generation throws exceptions.
- **Frontend client (UMS.Client):** If page layouts fail to render, validation errors are hidden, TanStack Query keys are stale, or page actions fail to dispatch calls.

### Step 3: Implement Fix at the Correct Layer
- Do not patch issues in the wrong project. If a domain model validation logic is buggy, update the Domain class itself. Do not patch it in the API endpoints mapping code or write validation checks inside the client UI pages.
- Ensure the fix adheres to the coding standards and architecture rules.

### Step 4: Run Verification Tests
1. Run the failing test case you created in Step 1. Verify that the test now passes.
2. Add a regression test to the test suite to ensure the bug cannot be reintroduced.
3. Run the entire test suite of the project to ensure the change does not break other modules.

---

## Expected Outcome (Definition of Done)
- The issue is resolved and cannot be reproduced in the local environment.
- A new, passing regression test is added to the test suite.
- The full project test suite executes and passes with zero regressions.
- No debug code (e.g., `Console.WriteLine`, `console.log`, or commented-out blocks) remains in the codebase.

---

## Troubleshooting & Rollback

### If the fix breaks existing tests:
- Do not bypass verification requirements by disabling or deleting existing tests.
- Re-read the test scenario details to verify if the regression tests represent valid invariants, or if your change modified other business rules.

### Rollback Strategy
If the fix causes unexpected regressions and needs to be undone:
1. Revert the file changes using Git:
   ```bash
   git checkout -- path/to/file
   ```
2. Clean up any temporary debug logs or local testing databases before attempting a different solution.
