# Skill: Add Auth Flow

**Type:** Skill  
**Applies To:** All (Backend and Frontend)  
**When to Use:** Follow this process when protecting endpoints, adding permissions, seeding user roles, or securing routes on the frontend.

---

## Related Rules
- [01-backend-architecture.md](file:///d:/_MyFolder/MyWorkSpace/UserManagement/UMSSolution/docs/ai-rules/01-backend-architecture.md) (Dependency boundaries, endpoint layouts)
- [04-backend-security.md](file:///d:/_MyFolder/MyWorkSpace/UserManagement/UMSSolution/docs/ai-rules/04-backend-security.md) (JWT authentication parameters, rate limit bounds, AppPermission architecture)
- [05-frontend-architecture.md](file:///d:/_MyFolder/MyWorkSpace/UserManagement/UMSSolution/docs/ai-rules/05-frontend-architecture.md) (Route guards, protected routes components)

---

## Procedural Workflow

### Step 1: Define Permission Constants
1. Open the file containing authorization constants (e.g. `AppPermission.cs` or `AppPermissions.cs` in the backend project).
2. Declare the new permission constants defining Service, Feature, and Action paths:
   ```csharp
   public static class AppPermissions
   {
       public static class Categories
       {
           public const string Read = "Permission.Product.Categories.Read";
           public const string Create = "Permission.Product.Categories.Create";
       }
   }
   ```

### Step 2: Seed Baseline Claims
1. Open `ApiTestDatabaseInitializer.cs` (or production database seed configuration).
2. Verify that the new permissions are added to the list of baseline claims (e.g., `AppPermissions.AllPermissions`) assigned to the `Admin` role by default during environment setup.

### Step 3: Guard Backend Minimal API Endpoint
1. Navigate to the endpoint map definition under `UMS.API/Endpoints/`.
2. Append `.RequireAuthorization(AppPermission.NameFor(...))` to the route:
   ```csharp
   group.MapPost("/", async (ISender sender, CreateCategoryRequest request) => { ... })
       .RequireAuthorization(AppPermission.NameFor(AppService.Product, AppFeature.Categories, AppAction.Create));
   ```

### Step 4: Handle Claims on Frontend Client
1. The frontend checks auth claims based on JWT payload decodings. Verify token decoders (`lib/jwt.ts`) parse permission fields correctly.
2. The user profile response from the API must return the array of user claims/permissions.

### Step 5: Update Frontend Route Guards
1. Open `src/App.tsx`.
2. Wrap the feature page route within the `<ProtectedRoute>` component. Supply the required permission strings to the guard parameters:
   ```typescript
   <Route element={<ProtectedRoute allowedPermissions={['Permission.Product.Categories.Read']} />}>
     <Route path="/admin/categories" element={<CategoriesManagement />} />
   </Route>
   ```

### Step 6: Test Security Boundaries
1. In `UMS.API.Tests/Endpoints/`, append endpoint access validation tests.
2. Confirm the route returns:
   - `401 Unauthorized` for anonymous calls.
   - `403 Forbidden` for low-privilege sessions lacking claims.
   - `200 OK` (or appropriate 2xx status) for sessions having the correct claims.

---

## Expected Outcome (Definition of Done)
- Permission constant declared in C# backend classes.
- Claims seeding configurations updated to include the new permissions.
- Backend Minimal API endpoint protected with the required authorization policies.
- Frontend React route wrapped inside a `<ProtectedRoute>` with matching permission parameters.
- Tests written verifying `401`, `403`, and `200` behaviors under different authorization scenarios.

---

## Troubleshooting & Rollback

### If auth fails on all requests in tests:
- Verify that testing tokens are signed with the same keys, issuer, and audience details mapped within `appsettings.Testing.json`.
- Ensure baseline DB seeding is executed on startup prior to running test calls.

### Rollback Strategy
1. Remove the permission string mapping from database seeding services.
2. Revert the route parameters: remove `.RequireAuthorization(...)` from the backend route.
3. Clean up the page guards in the client's routing setup (remove permission parameters from `<ProtectedRoute>`).
4. Delete permission check test suites.
