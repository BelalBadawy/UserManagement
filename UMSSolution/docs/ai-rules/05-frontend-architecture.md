# UMS Frontend Architecture

**Type:** Rule  
**Applies To:** Frontend (React / TypeScript)  
**When to Use:** Apply when adding routes, structuring components, defining pages, or managing React application states.

---

## 1. Project Directory Layout

The frontend source is located in `UMS.Client/src` and organized as follows:
- **`components/`:** Reusable UI components.
  - `components/ui/`: Low-level wrapper components (e.g., button, card, sheet, dialog, toast). Usually scaffolded via shadcn/ui.
  - `components/`: Shared application components (e.g., `AuthContext.tsx`, `ProtectedRoute.tsx`).
- **`layouts/`:** Page structures and navigation layouts (e.g., `AdminLayout.tsx`, `LoginLayout.tsx`).
- **`pages/`:** Page-level feature entry points (e.g., `UserManagement.tsx`, `CategoriesManagement.tsx`).
- **`lib/`:** Central client configuration (`api-client.ts`) and feature api modules (e.g., `categories-api.ts`).
- **`hooks/`:** Reusable React custom hooks.
- **`assets/`:** Static files, images, or stylesheets.

---

## 2. Component Design Conventions

- **Functional Only:** All components must be functional components using React hooks. Do not use legacy class-based components.
- **PascalCase Filenames:** Component filenames must match their component names in PascalCase (e.g. `PasswordStrengthMeter.tsx`).
- **One Component Per File:** Define only one component per file. Sub-components must be extracted into their own files.
- **RULE: Component & Page Exports:** Shared UI wrapper and application components (located in `src/components/` and `src/components/ui/`) must use named exports. Page-level components in `src/pages/` must use `default` exports to enable code-splitting via `React.lazy` at the router boundary.

---

## 3. Strict Type Safety

- **TypeScript Enforcement:** Type interfaces are mandatory for every API request, API response envelope, and component prop.
- **Ban `any`:** The `any` type is strictly forbidden. Always define precise types or generic parameter bindings.
- **Co-locate Props:** Define prop interfaces directly above the component definition in the same file.

---

## 4. State Management Separation Rules

To maintain high rendering performance and clean code, state is strictly divided into domains:

### A. Server State (TanStack Query)
- All network fetched records, caching states, fetching updates, and mutations must be managed via `TanStack Query`.
- **Query Keys Pattern:** Query keys must follow a strict array structure:
  ```typescript
  ['feature', 'action', ...params]
  // Example:
  ['categories', 'list', pageNumber, statusFilter]
  ```
- **No State Duplication:** NEVER copy fetched server data into React local state (e.g., `useState`). Bind component rendering directly to query results.

### B. Table State (TanStack React Table)
- Sorting configurations, pagination indices, filtering tokens, and grid column details must be managed strictly using `TanStack React Table` hooks.
- **RULE: Manual Sorting & Pagination Mode:** For all server-side paginated tables, the TanStack React Table instance must run in manual mode (`manualPagination: true`, `manualSorting: true`). Handlers for pagination and sorting changes must update URL search parameters, which in turn hydrates the table state and triggers network requests.

### C. Local UI State (React `useState` / `useReducer`)
- Simple presentation-only details (e.g., modal toggle states, loading parameters for local processes, dirty check status, input form field states) are kept in standard React `useState` hooks.

### D. RULE: URL-driven Filter Synchronization (For Directory Pages)
All paginated administration directory pages (e.g., Category or User Management) must synchronize filter state to the URL query string:
- **Hydration from URL:** Read filter states (page, size, search term, sort column, sort direction, active status) directly from URL query parameters.
- **Local Form State:** Maintain separate local state hooks (e.g., `localSearch`, `localStatus`) for form controls.
- **Back/Forward Navigation Sync:** Synchronize local form inputs when URL parameters change by keeping track of previous parameter values via a `prevParams` state object.
- **Dirty Checking & Apply Filters:** Compare local form states with URL parameters to calculate an `isDirty` flag. Do not apply filter parameters to the query or update page state until the user clicks an "Apply Filters" button (form submit) or clicks a "Reset Filters" button.
- **Pagination & Sorting Auto-Apply:** Unlike text inputs, clicking column headers to sort or using pagination buttons must immediately update the URL query string and reset page number to `1`.

---

## 5. Routing and guards

- **Central Router:** All routes are declared within `src/App.tsx` using `react-router-dom` v6 routing components.
- **Lazy Loading:** Large page components must be lazy-loaded using `React.lazy` and wrapped in `<Suspense>`.
- **Security Guards:** Protect routes using `<ProtectedRoute>` elements:
  - Authenticated: Enforce login credentials.
  - Permissions/Roles: Filter routes dynamically based on permissions (e.g., `allowedPermissions={['Permission.Product.Categories.Read']}`).

---

## 6. CSS Styling and UI Elements

- **Tailwind Utility CSS:** All layouts and page styling must utilize Tailwind CSS classes. Inline `style={...}` tags are forbidden.
- **Radix UI Primitives:** Leverage Radix UI primitives (or shadcn components wrapped around them) for complex interactive elements (such as `Dialog`, `Sheet`, `Toast`, `Select`) to guarantee keyboard navigation and screen-reader accessibility.
- **Icons:** Use ONLY `lucide-react` icons. Maintain a consistent size (typically `w-4 h-4` or `w-5 h-5`) for UI balance.
- **Standard Data Grids:** All admin data tables requiring pagination, sorting, and filtering must utilize TanStack React Table and the shared `<DataTablePagination />` component. All admin data tables must also include the `<DataTableExport />` component providing Excel (.xlsx) and PDF (.pdf) download capabilities. Do not build custom pagination or exports from scratch, nor use standard HTML tables for admin lists.

### Error Boundary Strategy
- **Shared Component:** Use a single `<PageErrorBoundary>` component wrapping all `<Route>` elements alongside `<React.Suspense>`.
- **Fallback UI:** Display a user-friendly message with a "Retry" button that calls `resetErrorBoundary()`.
- **Query Errors vs Render Errors:** TanStack Query handles expected API errors (show inline error states in components). Error Boundaries handle unexpected rendering crashes (show full-page fallback). Do NOT use error boundaries for expected API failure states (e.g., 400 validation errors, 404 not found).
