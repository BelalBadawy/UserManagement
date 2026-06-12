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

## Real Example Reference
- **Frontend Page Component**: [CategoriesManagement.tsx](file:///d:/_MyFolder/MyWorkSpace/UserManagement/UMSSolution/UMS.Client/src/pages/CategoriesManagement.tsx)
- **Base Client API Configuration**: [api-client.ts](file:///d:/_MyFolder/MyWorkSpace/UserManagement/UMSSolution/UMS.Client/src/lib/api-client.ts)
- **Feature API Services**: [categories-api.ts](file:///d:/_MyFolder/MyWorkSpace/UserManagement/UMSSolution/UMS.Client/src/lib/categories-api.ts)
- **TanStack Query custom Hooks**: [useCategories.ts](file:///d:/_MyFolder/MyWorkSpace/UserManagement/UMSSolution/UMS.Client/src/hooks/useCategories.ts)

---

## Procedural Workflow

### Step 1: Base API Client & Types Definitions
1. Identify input and output DTO structures from backend endpoints.
2. Under `src/lib/`, create or update your feature API service module (e.g. `categories-api.ts`).
3. Define TypeScript interfaces. The client envelope `ApiResponse<T>` maps 1:1 to C# `IResponseWrapper<T>` (automatic PascalCase to camelCase conversion during serialization):
   ```typescript
   export interface ApiResponse<T = any> {
     messages: string[];
     isSuccessful: boolean;
     statusCode: number;
     data?: T;
   }

   export interface CategoryResponse {
     id: number;
     name: string;
     slug: string;
     parentId?: number;
     sortOrder: number;
     isActive: boolean;
     rowVersion: number[];
   }
   ```
4. **Base Client Configuration Details (`src/lib/api-client.ts`)**:
   - The base client prepends base URL configurations (`import.meta.env.VITE_API_BASE_URL` or default `https://localhost:7122`).
   - It automatically extracts JWT tokens from `localStorage.getItem('token')` and appends them as a `Bearer` token inside the `Authorization` header.
   - It sets `Content-Type: application/json` and stringifies request bodies unless options body is a `FormData` instance.

### Step 2: Implement Feature API Services
1. Define feature services inside your api module, calling base `api.get`, `api.post`, `api.put`, and `api.delete` requests:
   ```typescript
   import { api } from './api-client';
   import type { ApiResponse } from './api-client';

   export const categoriesApi = {
     getPagedList: (params: PagedFilterRequest): Promise<ApiResponse<PagedResult<CategoryResponse>>> => {
       const query = new URLSearchParams(params as any).toString();
       return api.get(`api/v1/categories/paged?${query}`);
     },
     create: (data: CreateCategoryRequest): Promise<ApiResponse<number>> => {
       return api.post('api/v1/categories', data);
     },
     update: (data: UpdateCategoryRequest): Promise<ApiResponse<void>> => {
       return api.put('api/v1/categories', data);
     },
     changeStatus: (id: number, isActive: boolean): Promise<ApiResponse<number>> => {
       return api.put(`api/v1/categories/${id}/status?isActive=${isActive}`);
     }
   };
   ```

### Step 3: Implement TanStack Query Hooks
1. Create a custom query hook file in `src/hooks/` (e.g., `useCategories.ts`).
2. Map operations using structured cache query keys. Implement standard invalidation on mutate success, alongside optimistic status update routines:
   - **Standard Mutation Invalidation**:
     On success of write operations (create/update/delete), invalidate queries matching the cache query key:
     ```typescript
     export function useCreateCategory() {
       const queryClient = useQueryClient();
       const toast = useToast();

       return useMutation({
         mutationFn: (data: CreateCategoryRequest) => categoriesApi.create(data),
         onSuccess: (response) => {
           if (response.isSuccessful) {
             toast.success('Category created successfully!');
             queryClient.invalidateQueries({ queryKey: ['categories'] });
           } else {
             toast.error(response.messages[0] || 'Failed to create category.');
           }
         }
       });
     }
     ```
   - **5-Step Optimistic Status Toggles**:
     For status toggles, mutate local query cache on `onMutate`, rollback on `onError`, and invalidate/refetch on `onSettled`:
     ```typescript
     export function useChangeCategoryStatus() {
       const queryClient = useQueryClient();
       const toast = useToast();

       return useMutation({
         mutationFn: (data: { id: number; isActive: boolean }) =>
           categoriesApi.changeStatus(data.id, data.isActive),
         
         // 1. Cancel outgoing queries & snapshot current cache
         onMutate: async ({ id, isActive }) => {
           await queryClient.cancelQueries({ queryKey: ['categories'] });
           const previousQueries = queryClient.getQueriesData<PagedResult<CategoryResponse>>({
             queryKey: ['categories', 'list']
           });

           // 2. Optimistically update cached lists
           previousQueries.forEach(([queryKey]) => {
             queryClient.setQueryData<PagedResult<CategoryResponse>>(queryKey, (old) => {
               if (!old) return old;
               return {
                 ...old,
                 data: old.data.map((cat) =>
                   cat.id === id ? { ...cat, isActive } : cat
                 )
               };
             });
           });

           return { previousQueries };
         },
         
         // 3. Rollback to snapshot on failure
         onError: (err: Error, _variables, context) => {
           if (context?.previousQueries) {
             context.previousQueries.forEach(([queryKey, queryData]) => {
               queryClient.setQueryData(queryKey, queryData);
             });
           }
           toast.error(err.message || 'Failed to update category status.');
         },
         
         onSuccess: (response, variables) => {
           if (response.isSuccessful) {
             toast.success(`Category status updated successfully.`);
           } else {
             toast.error(response.messages[0] || 'Failed to update status.');
           }
         },

         // 4. Force background refetch on settle
         onSettled: () => {
           queryClient.invalidateQueries({ queryKey: ['categories'] });
         }
       });
     }
     ```

### Step 4: Create Pages, URL State Synchronization, and Form Layouts
1. In `src/pages/`, create the view entry component (e.g. `CategoriesManagement.tsx`).
2. **URL State Synchronization**:
   Synchronize grid query states (page, size, search, sorting) with URL query parameters using React Router's `useSearchParams`. Read parameters on render, and update them on interaction:
   ```typescript
   const [searchParams, setSearchParams] = useSearchParams();
   const page = parseInt(searchParams.get('page') || '1', 10);
   const search = searchParams.get('search') || '';
   const sortBy = searchParams.get('sortBy') || 'sortOrder';
   const sortDir = searchParams.get('sortDir') || 'asc';

   const updateFilter = (newParams: Partial<PagedFilterRequest>) => {
     const current = Object.fromEntries(searchParams.entries());
     setSearchParams({ ...current, ...newParams, page: String(newParams.page || 1) });
   };
   ```
3. **Rule 06 Frontend Coding Guidelines**:
   - **DatePicker**: Do not use native HTML date inputs. Use a custom `<DatePicker>` component wrapping `react-day-picker` and `date-fns`. Always transmit dates in `"yyyy-MM-dd"` ISO format to the API, while presenting localized formats in the UI.
   - **Validation timing**: Execute form field validations only on `onBlur` or form submit. Do not validate fields during `onChange` keystroke events.
   - **Auto-slugification**: Form name inputs must generate slugs automatically. If name inputs contain non-ASCII characters, slugification must append `crypto.randomUUID()` as a fallback identifier.
   - **Unsaved Navigation Guard**: Protect page forms from accidental navigation data losses. Use React Router `useBlocker` or handle window `beforeunload` event warnings if form states are dirty.
4. **Radix Components**: Wrap Create/Edit operations inside Radix UI controlled sheets or dialog states.

### Step 5: Configure Router Paths
1. Open `src/App.tsx`.
2. Map the new route path, wrapping admin pages inside `<ProtectedRoute allowedPermissions={['...']}>`.

### Step 6: Write Co-located Component and Hook Tests
1. **Co-locating Page Tests**: Page unit tests must be co-located with their target pages. Place the test file next to the component (e.g. `src/pages/CategoriesManagement.tsx` has `src/pages/CategoriesManagement.test.tsx`).
2. Assert rendering, validation triggers, optimistic state shifts, and mock service responses using React Testing Library and user-event simulation.

---

## Expected Outcome (Definition of Done)
- TypeScript interfaces representing request/response envelopes mapped correctly.
- Custom query hooks built, including standard query invalidations and 5-step optimistic status update hooks.
- URL state synchronization implemented, linking page state variables to URL search parameters.
- DatePicker and validation timing standards applied conforming to Rule 06.
- Page unit tests co-located beside page files.
