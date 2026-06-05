# Skill: Add New Frontend Feature

**Type:** Skill  
**Applies To:** Frontend (React / TypeScript)  
**When to Use:** Follow this workflow when adding new UI pages, feature views, forms, or navigation items.

---

## Related Rules
- [05-frontend-architecture.md](file:///d:/_MyFolder/MyWorkSpace/UserManagement/UMSSolution/docs/ai-rules/05-frontend-architecture.md) (Frontend folder layout, state boundaries, routing setup)
- [06-frontend-coding-standards.md](file:///d:/_MyFolder/MyWorkSpace/UserManagement/UMSSolution/docs/ai-rules/06-frontend-coding-standards.md) (Prop rules, form validation hooks, API layering, accessibility)
- [07-testing-standards.md](file:///d:/_MyFolder/MyWorkSpace/UserManagement/UMSSolution/docs/ai-rules/07-testing-standards.md) (RTL component tests, user action assertions)

---

## Procedural Workflow

### Step 1: Define TypeScript Types
1. Identify the input and output DTO structures of the backend endpoints.
2. In the appropriate feature api module under `src/lib/` (or a dedicated type definitions file), define the TypeScript interfaces:
   ```typescript
   export interface CategoryResponse {
     id: number;
     name: string;
     slug: string;
     isActive: boolean;
   }
   ```
3. NEVER use `any` to skip typing response definitions.

### Step 2: Implement Feature API Services
1. In `src/lib/` create or update the feature API service module (e.g. `categories-api.ts`).
2. Implement typed HTTP mappings calling the base API client:
   ```typescript
   import { api } from './api-client';
   
   export const categoriesApi = {
     getById: (id: number): Promise<ApiResponse<CategoryResponse>> => {
       return api.get(`api/v1/categories/${id}`);
     },
     create: (data: CreateCategoryRequest): Promise<ApiResponse<number>> => {
       return api.post('api/v1/categories', data);
     }
   };
   ```

### Step 3: Implement TanStack Query Hooks
1. Create a custom query hook file in `src/hooks/` (e.g., `useCategories.ts`).
2. Map endpoints to `useQuery` or `useMutation` hooks using structured query key arrays:
   ```typescript
   import { useQuery } from '@tanstack/react-query';
   import { categoriesApi } from '../lib/categories-api';
   
   export function useCategory(id: number) {
     return useQuery({
       queryKey: ['categories', 'detail', id],
       queryFn: () => categoriesApi.getById(id),
       select: (res) => res.data
     });
   }
   ```

### Step 4: Create Pages and UI Components
1. In `src/pages/`, create the view entry component (e.g., `CategoriesManagement.tsx`).
2. Use TanStack React Table for grid layouts requiring pagination, sorting, or filtering.
3. Keep page components clean: delegate complex elements into sub-components inside `src/components/`.
4. Enforce loading, empty, and query error visual screens:
   ```typescript
   if (isLoading) return <Loader2 className="animate-spin" />;
   if (error) return <ErrorMessage message="Failed to load database." />;
   ```
5. Apply Radix UI components (Sheet, Dialog, Toast) for interactive inputs to guarantee keyboard accessibility.

### Step 5: Configure Router Paths
1. Open `src/App.tsx`.
2. Map the new route path to the parent route configuration. Ensure private admin routes are protected by `<ProtectedRoute>`:
   ```typescript
   <Route element={<ProtectedRoute allowedPermissions={['Permission.Product.Categories.Read']} />}>
     <Route path="/admin/categories" element={<CategoriesManagement />} />
   </Route>
   ```

### Step 6: Write Component and Hook Tests
1. Create tests matching the component paths inside `src/__tests__/` or next to the component.
2. Assert rendering, inputs validation, hook state changes, and button click transactions using RTL and user-event simulation. Mock service integrations at the API module boundary.

---

## Expected Outcome (Definition of Done)
- TypeScript interfaces created representing request and response models.
- Service mapping methods added inside the feature api file (e.g. `categories-api.ts`).
- Query hooks wrapping feature service endpoints created in `src/hooks/`.
- UI Page and components developed utilizing Tailwind CSS and Radix UI layout elements.
- Route mapped within `src/App.tsx` and protected with appropriate permissions check.
- RTL test suite created and passing successfully.

---

## Troubleshooting & Common Pitfalls
- **Nesting UI states in server state:** Do not map TanStack Query returns into component `useState` blocks. Bind rendering directly to `data` destructured from the query.
- **Missing route mapping:** If routing loads a blank screen, verify that routes are registered inside `src/App.tsx` and nested within their corresponding parent route layout container.
- **Rollback Process:** To discard frontend features, delete page files, remove service calls, delete query hooks, clean up route paths in `App.tsx`, and delete test files.
