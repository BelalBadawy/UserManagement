Act as a Senior Principal Engineer performing a strict Cross-Feature Consistency Audit on the UMS codebase. 

Our goal is the "Single-Author Illusion": ensuring that if someone reads the Categories, Users, and Audit Logs features, they cannot tell they were written at different times. Identical problems must have been solved with identical patterns, naming conventions, and file structures.

Please review the codebase against the rules in `docs/ai-rules/` and specifically compare the three main domains (Categories, Users, Audit Logs) against each other. 

Generate a "Consistency Audit Report" with the following sections:

## 1. Backend Minimal API Endpoints
Compare `CategoryEndpoints.cs`, `UserEndpoints.cs`, and `AuditTrailEndpoints.cs`.
- Are the route structures consistent (e.g., `/export` mapped the same way)?
- Is `.RequireAuthorization()` applied consistently?
- Is the parameter binding (e.g., `[AsParameters]`) uniform?
- **Drift Found:** (List any inconsistencies)

## 2. Backend Service Layer & Query Building
Compare `CategoryService.cs`, `UserService.cs`, and `AuditTrailService.cs`.
- Are the methods for paged lists, full lists, and exports named identically (e.g., `GetPagedAsync`, `GetListAsync`, `ExportAsync`)?
- Is the extracted query builder helper named and structured consistently (e.g., `BuildQuery(...)`)?
- Do they all handle the `IResponseWrapper` envelope identically?
- **Drift Found:** (List any inconsistencies)

## 3. Backend Mediator Handlers
Compare the Handlers for Paged Queries and Export Queries across all three domains.
- Do they all use primary constructors consistently?
- Do they all delegate to the Service layer in the exact same way?
- Are the record definitions for Commands/Queries structured identically?
- **Drift Found:** (List any inconsistencies)

## 4. Frontend Page State Management (The Batch-Apply Pattern)
Compare `CategoriesManagement.tsx`, `UserManagement.tsx`, and `AuditLogsManagement.tsx`.
- Are the local state variables named uniformly? (e.g., `localSearch`, `localStatus` vs `localSearchTerm`, `localIsActive`).
- Is the `prevParams` render-phase synchronization logic copy-paste identical in structure?
- Is the `isDirty` calculation logic structured the same way?
- Is the `handleApplyFilters` and `handleResetFilters` logic structurally identical?
- **Drift Found:** (List any inconsistencies)

## 5. Frontend Export Alignment
Compare how the `<DataTableExport />` `onExport` callback is wired up in all three pages.
- Do all three pages strictly pull export parameters from the URL `searchParams` (not local states)?
- Is the mapping from URL params to the API call identical in structure?
- **Drift Found:** (List any inconsistencies)

## 6. Frontend API Modules
Compare `categories-api.ts`, `users-api.ts`, and `audit-logs-api.ts`.
- Is the `fetch` + `Blob` download logic for exports identical, or has it been slightly rewritten in each file?
- Are the parameter types/interfaces structured the same way?
- **Drift Found:** (List any inconsistencies)

---

## 7. 7. Frontend Route & Component Consistency
Compare the folder structure and file naming in UMS.Client/src/pages/ for all modules.

Are the page files consistently named using PascalCase? (e.g., CategoriesManagement.tsx, UserManagement.tsx, AuditLogsManagement.tsx).
Are the API modules consistently named in src/lib/? (e.g., categories-api.ts, users-api.ts, audit-logs-api.ts).
Are the custom hooks consistently named in src/hooks/? (e.g., useCategories.ts, useUsers.ts, useAuditLogs.ts).
Is the route definition pattern in UMS.Client/src/App.tsx identical for all modules (using <ProtectedRoute> and lazy loading where applicable)?
Drift Found: (List any inconsistencies)

---

## Final Output Requirement
Based on your findings, provide a **Refactoring Plan** to eliminate the drift. 
Group the refactoring tasks by "Quick Wins" (naming changes, minor syntax alignment) and "Structural Alignment" (logic that needs to be rewritten to match the dominant pattern). Do not change the dominant pattern; align the outliers to it.