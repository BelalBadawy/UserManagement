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
- **Enforced Memoization:** Use `useMemo` and `useCallback` to wrap objects and callback functions returned by hooks or passed as dependencies to prevent unnecessary re-renders:
  ```typescript
  const values = useMemo(() => ({ user, hasPermission }), [user, hasPermission]);
  const handleToggle = useCallback(() => setIsOpen(prev => !prev), []);
  ```
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
- **Validation Timing:** Validate forms on input blur (ONLY after the field has been touched/submitted) AND on form submission. Avoid validating while the user is actively typing in the field. Display clear, inline validation error messages.

---

## 6. Accessibility & UX Requirements

- **Radix UI Primitives:** Leverage Radix UI primitives to ensure correct keyboard focus management, modal closures on ESC, and overlay handling.
- **ARIA Annotations:** Always supply accessible ARIA descriptions (`aria-label`, `aria-describedby`) for interactive buttons and dialog inputs.
- **Error Boundaries:** Every major page entry point must be wrapped within or near a React Error Boundary to catch and handle rendering crashes gracefully.
- **ESLint Conformance:** The codebase maintains zero warnings. All ESLint rules must be strictly adhered to during development.
