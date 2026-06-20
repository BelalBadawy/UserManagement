# UMS Frontend Coding Standards

**Type:** Rule  
**Applies To:** Frontend (React / TypeScript)  
**When to Use:** Apply when creating UI pages, writing custom hooks, implementing forms, mapping API responses, or updating styling.

---

## 1. Naming Conventions

- **PascalCase:** Use for components, context providers, and custom TypeScript types/interfaces:
  ```typescript
  export interface UserResponse { id: number; name: string; }
  export function CategoriesManagement() { ... }
  ```
- **camelCase:** Use for functions, variables, states, and parameters:
  ```typescript
  const [loading, setLoading] = useState(false);
  function handleNameChange(val: string) { ... }
  ```
- **UPPER_SNAKE_CASE:** Use for constant variables and static configuration mappings:
  ```typescript
  export const BASE_URL = 'https://localhost:7122';
  ```

---

## 2. API Client Layering Rule

To ensure clean separation of concerns, the API consumption pipeline must strictly follow these layers:
```
+-------------------------------------------------------------+
|                        UI Components                        |
+------------------------------+------------------------------+
                               | (1) Uses
                               v
+-------------------------------------------------------------+
|                     TanStack Query Hooks                    |
+------------------------------+------------------------------+
                               | (2) Wraps
                               v
+-------------------------------------------------------------+
|             Feature API Modules (categories-api.ts)         |
+------------------------------+------------------------------+
                               | (3) Calls
                               v
+-------------------------------------------------------------+
|              Base API Client (api-client.ts)                |
+-------------------------------------------------------------+
```
- **Base Client (`lib/api-client.ts`):** Defines default configurations like `BASE_URL`, token injection, HTTP request mappings (`get`, `post`, `put`, `delete`), and error translation.
- **Feature API Modules (`lib/categories-api.ts`):** Centralizes URL configurations and exposes typed promise endpoints calling `api.get` / `api.post`.
- **TanStack Query Hooks:** Exposes reactive states (loading, error, caching) by wrapping feature service endpoints.
- **UI Components Rules:** Components must NEVER call the base client `api-client.ts` directly. They must fetch data exclusively via TanStack Query hooks.

---

## 3. React Hooks and Memoization

- **Prefixing:** Custom hooks must start with the `use` prefix (e.g., `useAuth`).
- **Object Reference Preservation:** Hooks must avoid returning raw, complex objects that change references on every render.
- **Compiler-First Memoization:** React 19's compiler handles most memoization automatically. Do NOT add `useMemo` or `useCallback` by default.
- **Manual Memoization Exceptions:** Only add manual memoization when:
  - The React Compiler is confirmed disabled for the file, OR
  - A React DevTools Profiler trace proves a specific re-render is caused by reference instability AND the compiler failed to optimize it, OR
  - You are passing callbacks to a heavily rendered list item (e.g., 100+ rows) where the child does not use React.memo (and cannot be compiler-optimized).
- **Synchronous Route Guards:** Avoid using `useEffect` for synchronous authorization checks in route guards; evaluate permissions synchronously during render.

---

## 4. Component Properties (Props)

- **Co-located Interfaces:** Always define Prop interfaces directly above their parent functional component.
- **Props Destructuring:** Destructure prop arguments directly within the component function signature. Avoid repeating type names:
  ```typescript
  interface ButtonProps {
    readonly label: string;
    readonly onClick: () => void;
  }
  
  export function ActionButton({ label, onClick }: ButtonProps) {
    return <button onClick={onClick}>{label}</button>;
  }
  ```

---

## 5. Form Management and Validation

- **Controlled Inputs:** Map form elements to React states using controlled value variables (e.g. `<input value={name} onChange={...} />`).
- **Input Sanitization:** Sanitize user inputs dynamically (e.g. automatically trimming inputs on changes).
- **RULE: Auto-Slugification Utility:** Forms that capture names and dynamic slugs (such as create category dialogs) must auto-slugify the user-typed name dynamically during input typing (only in create mode) using a custom slug generator:
  ```typescript
  const generateSlug = (val: string) => {
    let slug = val
      .toLowerCase()
      .trim()
      .replace(/[^a-z0-9\s-]/g, '') // remove invalid characters
      .replace(/[\s-]+/g, '-')     // replace spaces or multiple hyphens with a single hyphen
      .replace(/^-+|-+$/g, '');    // strip leading/trailing hyphens
      
    // Non-ASCII Fallback (e.g., Arabic, Chinese):
    if (!slug && val.trim().length > 0) {
      // Add transliteration or fall back to GUID-based slug rather than an empty string
      slug = crypto.randomUUID();
    }
    return slug;
  };
  ```
- **Navigation Guard:** Forms with unsaved changes must use `useBlocker` (React Router) or `beforeunload` to prevent accidental data loss.
- **Validation Timing:** Validate forms on input blur (ONLY after the field has been touched/submitted) AND on form submission. Avoid validating while the user is actively typing in the field. Display clear, inline validation error messages.

---

## 6. Accessibility & UX Requirements

- **Radix UI Primitives:** Leverage Radix UI primitives to ensure correct keyboard focus management, modal closures on ESC, and overlay handling.
- **ARIA Annotations:** Always supply accessible ARIA descriptions (`aria-label`, `aria-describedby`) for interactive buttons and dialog inputs.
- **Error Boundaries:** Every major page entry point must be wrapped within or near a React Error Boundary to catch and handle rendering crashes gracefully.
- **ESLint Conformance:** The codebase maintains zero warnings. All ESLint rules must be strictly adhered to during development.

### Error Boundary Strategy
- Follow the Error Boundary Strategy defined in [05-frontend-architecture.md](05-frontend-architecture.md#error-boundary-strategy) §6.

---

## 7. Date Handling Standards

- **Forbidden Native Inputs:** Basic HTML `<input type="date">` inputs are strictly forbidden due to browser locale and formatting inconsistencies.
- **DatePicker Component:** All date input and selection fields must use the custom `<DatePicker>` component (located at `src/components/ui/date-picker.tsx` which wraps `react-day-picker` and uses `date-fns` for internal date operations).
- **Date Format Standard:** API-transmitted and URL date query parameters must strictly enforce ISO 8601 `yyyy-MM-dd` format. User-facing display formats may use `yyyy/MM/dd` if desired.
- **Backend Date Parsing:** The backend must safely parse date filters passed from the client using `DateTime.TryParseExact` with `"yyyy-MM-dd"` format and `CultureInfo.InvariantCulture` to prevent locale-specific server culture parsing issues.

---

## 8. Query Cache Invalidation and Optimistic Updates

To maintain clean and responsive cache state via `TanStack Query`, developers must follow these patterns:
- **RULE: Cache Invalidation on Mutation:** Successful write operations (mutations) must invalidate the corresponding feature's query keys globally to trigger automatic refetches:
  ```typescript
  onSuccess: (response) => {
    if (response.isSuccessful) {
      queryClient.invalidateQueries({ queryKey: ['categories'] });
    }
  }
  ```
- **RULE: Optimistic Updates with Rollback:** Quick presentation-level status toggles (e.g., activating or deactivating a category directly from a directory list switch) must implement optimistic query updates. In the hook definition:
  1. Cancel active outgoing queries using `queryClient.cancelQueries`.
  2. Cache the current state via `queryClient.getQueriesData`.
  3. Mutate the cache locally using `queryClient.setQueryData`.
  4. Implement `onError` to restore the previous cache state from context if the API call fails.
  5. Invalidate the query key inside `onSettled` to guarantee UI correctness.
  
  *Example (Optimistic Switch Hook):*
  ```typescript
  export function useChangeStatus() {
    const queryClient = useQueryClient();
    return useMutation({
      mutationFn: (data: { id: number; isActive: boolean }) => api.changeStatus(data.id, data.isActive),
      onMutate: async ({ id, isActive }) => {
        await queryClient.cancelQueries({ queryKey: ['feature'] });
        const previousQueries = queryClient.getQueriesData<PagedResult<FeatureResponse>>({ queryKey: ['feature', 'list'] });
        previousQueries.forEach(([queryKey]) => {
          queryClient.setQueryData<PagedResult<FeatureResponse>>(queryKey, (old) => {
            if (!old) return old;
            return {
              ...old,
              data: old.data.map((item) => item.id === id ? { ...item, isActive } : item)
            };
          });
        });
        return { previousQueries };
      },
      onError: (err, variables, context) => {
        if (context?.previousQueries) {
          context.previousQueries.forEach(([queryKey, queryData]) => {
            queryClient.setQueryData(queryKey, queryData);
          });
        }
      },
      onSettled: () => {
        queryClient.invalidateQueries({ queryKey: ['feature'] });
      }
    });
  }
  ```

---

## 9. Frontend Security

- **Token Refresh:** Implement silent token refresh using interceptors. Handle concurrent requests during token refresh by queuing them and replaying once the new token is acquired.
- **XSS Prevention:** Never use `dangerouslySetInnerHTML`. Sanitize any user input rendered to the DOM.

---

## 10. Concurrency Control and Serialization

- **RowVersion Representation:** The frontend must represent concurrency tokens as `rowVersion: string;` in TypeScript interfaces.
- **Serialization Note:** Backend `byte[]` RowVersion properties serialize as base64 strings via System.Text.Json. The frontend must treat and send `rowVersion` as a base64 string.
