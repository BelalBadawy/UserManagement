# Skill: Add Auth Flow

**Type:** Skill  
**Applies To:** All (Backend and Frontend)  
**When to Use:** Follow this process when protecting endpoints, adding permissions, seeding user roles, or securing routes on the frontend.

---

## Related Rules
- [01-backend-architecture.md](docs/ai-rules/01-backend-architecture.md) (Dependency boundaries, endpoint layouts)
- [04-backend-security.md](docs/ai-rules/04-backend-security.md) (JWT authentication parameters, rate limit bounds, AppPermission architecture)
- [05-frontend-architecture.md](docs/ai-rules/05-frontend-architecture.md) (Route guards, protected routes components)

---

## Real Example Reference
- **System Permissions Constants**: [UMS.Application/Authorization/AppPermissions.cs](UMS.Application/Authorization/AppPermissions.cs)
- **Runtime Policy Provider Registration**: [UMS.Infrastructure/Identity/IdentityServiceExtensions.cs](UMS.Infrastructure/Identity/IdentityServiceExtensions.cs)
- **Runtime Policy Interception**: [UMS.Infrastructure/Identity/Permissions/PermissionPolicyProvider.cs](UMS.Infrastructure/Identity/Permissions/PermissionPolicyProvider.cs)
- **Runtime Permission Handler**: [UMS.Infrastructure/Identity/Permissions/PermissionAuthorizationHandler.cs](UMS.Infrastructure/Identity/Permissions/PermissionAuthorizationHandler.cs)
- **Frontend Protected Guard Component**: [UMS.Client/src/components/ProtectedRoute.tsx](UMS.Client/src/components/ProtectedRoute.tsx)
- **Frontend Authentication Context**: [UMS.Client/src/components/AuthContext.tsx](UMS.Client/src/components/AuthContext.tsx)

---

## Procedural Workflow

### Step 1: Define Permission Constants
1. Open the system permissions configuration file: [UMS.Application/Authorization/AppPermissions.cs](UMS.Application/Authorization/AppPermissions.cs).
2. Check if the target Service, Feature, or Action is already declared. If not, add them as `public const string` values inside the static classes:
   ```csharp
   public static class AppService
   {
       public const string Product = nameof(Product);
   }

   public static class AppFeature
   {
       public const string Categories = nameof(Categories);
   }

   public static class AppAction
   {
       public const string Create = nameof(Create);
       public const string Read = nameof(Read);
   }
   ```
3. Add a new `AppPermission` record instance to the private `All` array inside the static class `AppPermissions`:
   ```csharp
   private static readonly AppPermission[] All =
   [
       // ... existing permissions ...
       new(AppService.Product, AppFeature.Categories, AppAction.Create, "Create Categories"),
       new(AppService.Product, AppFeature.Categories, AppAction.Read, "Read Categories", IsBasic: true),
   ];
   ```
   *Note: Set `IsBasic: true` only if the permission belongs to standard authenticated users. Otherwise, omit it (meaning it belongs to Admin users).*

### Step 2: Runtime Authorization Resolution Mechanics
Developers must understand how policy strings are parsed at runtime by ASP.NET Core:
1. When `.RequireAuthorization(AppPermission.NameFor(service, feature, action))` is appended to an endpoint, it generates the policy string name (e.g. `Permission.Product.Categories.Read`).
2. The dynamic resolution mechanism consists of:
   - **`PermissionPolicyProvider`**: Registered as `IAuthorizationPolicyProvider` (Singleton). It intercepts policy names starting with `"Permission."` and dynamically constructs an `AuthorizationPolicy` containing a `PermissionRequirement` instance mapped to that string.
   - **`PermissionAuthorizationHandler`**: Registered as `IAuthorizationHandler` (Scoped). It checks user context claims for claim types of `AppClaim.Permission` where the value matches the requirement and the issuer matches the JWT configurations.
3. Seeding is executed automatically in the testing environment via `ApiTestDatabaseInitializer.cs` and in development environments via `ApplicationDbSeeder.cs`, which query `AppPermissions.AllPermissions` and add claims to baseline roles.

### Step 3: Guard Backend Minimal API Endpoint
1. Open the Minimal API routing class under `UMS.API/Endpoints/`.
2. Apply the `.RequireAuthorization(...)` configuration using `AppPermission.NameFor(...)`:
   ```csharp
   group.MapPost("/", async (ISender sender, CreateCategoryRequest request) => { ... })
       .RequireAuthorization(AppPermission.NameFor(AppService.Product, AppFeature.Categories, AppAction.Create));
   ```

### Step 4: Handle Claims & Silent Refresh on Frontend
1. **Claims Decoding**: The client application decodes the JWT access token using `decodeToken(storedToken)` inside `jwt.ts` and loads permission lists into the `user` state inside `AuthContext.tsx`.
2. **Silent Token Refresh**:
    To prevent concurrent API requests from failing during token refreshes, the refresh sequence is handled at the routing level in [UMS.Client/src/components/ProtectedRoute.tsx](UMS.Client/src/components/ProtectedRoute.tsx):
   - The route guard `ProtectedRoute` checks token expiration using `isTokenExpired(storedToken)` inside a React `useEffect` callback before rendering route contents.
   - If the token is expired, it runs `await refreshAccessToken()`.
   - The route displays a loading spinner and blocks child page components from mounting or making API requests until the refresh completes.

### Step 5: Update Frontend Route Guards
1. Open the routing configuration file `src/App.tsx` (or target navigation routing file).
2. Protect child routes by wrapping them in `<ProtectedRoute>` and passing the target permission string:
   ```typescript
   <Route element={<ProtectedRoute allowedPermissions={['Permission.Product.Categories.Read']} />}>
     <Route path="/admin/categories" element={<CategoriesManagement />} />
   </Route>
   ```

### Step 6: Test Security Boundaries
1. In `UMS.API.Tests/Endpoints/`, append integration tests targeting role authorization scopes.
2. Verify:
   - `401 Unauthorized` for anonymous requests.
   - `403 Forbidden` for authenticated requests lacking permission claims.
   - `200 OK` (or appropriate response) when matching claims are present.

---

## Expected Outcome (Definition of Done)
- Permission constants declared in `AppService`, `AppFeature`, and `AppAction` inside `AppPermissions.cs`.
- Seeding registers the claim automatically for baseline roles.
- Dynamic runtime provider `PermissionPolicyProvider` maps endpoint policies to matching claims validation handlers.
- Minimal API endpoints mapped and protected with matching `AppPermission.NameFor(...)` policy rules.
- Frontend routing wrapped inside `<ProtectedRoute>` which performs route-blocking silent token refresh when token expiration is detected.
- Endpoint validation tests pass, confirming 401, 403, and 2xx responses.

---

## Troubleshooting & Rollback

### If auth fails on all requests in tests:
- Verify testing tokens are signed using keys, issuer, and audience matching `appsettings.Testing.json`.
- Ensure baseline DB seeding is executed prior to running testing calls.

### Rollback Strategy
1. Delete the `AppPermission` record from `AppPermissions.cs`.
2. Revert route bindings: remove `.RequireAuthorization(...)` from Minimal API endpoints.
3. Remove permission constraints from the React route definitions in `src/App.tsx`.
4. Delete permission check test cases.
