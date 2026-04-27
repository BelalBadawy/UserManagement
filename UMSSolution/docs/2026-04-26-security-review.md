# ASP.NET Core Solution Review — UMS (User Management System)

**Date:** 2026-04-26  
**Solution:** `UMSSolution` · **Platform:** .NET 10 · **Architecture:** Clean Architecture + CQRS (MediatR-style via Mediator) · **Identity:** ASP.NET Core Identity + JWT · **Persistence:** EF Core / SQL Server

---

## Executive Summary

The solution is well-structured and demonstrates a strong command of Clean Architecture, CQRS, pipeline behaviors, permission-based authorization, and modern C# (.NET 10). The test coverage is thorough across all four layers. However, **six critical security issues** must be addressed before this can go anywhere near production, led by secrets committed to source control and a fully open CORS policy.

---

## A. Clean Code & Modern C#

### Summary

Code is idiomatic modern C# — records, pattern matching, primary constructors, file-scoped namespaces, and `init`-only properties are used well. One important correctness bug lives in the pipeline behavior.

| Severity | Area  | Location                                                        | Issue                                                                                                                                                      | Suggested Fix                                                                                               |
| -------- | ----- | --------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| 🔴       | Clean | `UMS.Application/Behaviors/ValidationPipelineBehavior.cs:56`    | Validation failures call `Fail(…, 500)` — returns HTTP 500 (Internal Server Error) for bad client input                                                    | Change the default `statusCode` argument to `400`                                                           |
| 🟡       | Clean | `UMS.Application/Behaviors/ValidationPipelineBehavior.cs:45-59` | `CreateValidationFailureResponse` uses reflection (`GetMethod`, `MakeGenericType`) at runtime on every validation failure — fragile and slow               | Introduce a `IValidationFailureFactory` interface or a non-generic approach                                 |
| 🟡       | Clean | `UMS.API/Middlewares/ErrorHandlingMiddleware.cs:69`             | `ex.Message` is written directly to the HTTP response — leaks internal paths, DB connection info, or framework internals in production                     | In production, return a generic message and log the full exception; only expose `ex.Message` in development |
| 🟡       | Clean | `UMS.API/Program.cs:22-28`                                      | Significant block of commented-out code (`AddControllers`, `MapScalarApiReference`, etc.)                                                                  | Remove dead code; put decisions in git history                                                              |
| 🔵       | Clean | `UMS.Application/Dtos/JWT/JwtConfiguration.cs`                  | Config key `TokenExpiryInMunites` — typo ("Munites" vs "Minutes") propagated to `appsettings.json` and all test configs                                    | Rename to `TokenExpiryInMinutes` consistently                                                               |
| 🔵       | Clean | `UMS.API/Endpoints/AccountEndpoints.cs:37`                      | `forgot-password` accepts a bare `string email` parameter — Minimal API binds this as a raw JSON string, which is non-standard and error-prone for clients | Create a `record ForgotPasswordRequest(string Email)` DTO                                                   |

---

## B. ASP.NET Core & Architecture Best Practices

### Summary

The layering is very clean — endpoints are thin, services hold business logic, domain has no infrastructure deps. A couple of architectural rules are broken in the infrastructure layer.

| Severity | Area | Location                                                         | Issue                                                                                                                                                                                                | Suggested Fix                                                                                                          |
| -------- | ---- | ---------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| 🟡       | Arch | `UMS.Infrastructure/Identity/Services/RoleService.cs:13`         | `RoleService` directly injects the concrete `ApplicationDbContext` instead of `IApplicationDbContext`, breaking the abstraction that every other service correctly uses                              | Replace with `IApplicationDbContext`; move `RoleClaims` query to the interface                                         |
| 🟡       | Arch | `UMS.API/Program.cs:57-68`                                       | Middleware ordering issue: `UseStaticFiles()` is called **after** `UseRouting()` — static files should be served first to avoid unnecessary route evaluation                                         | Move `app.UseStaticFiles()` before `app.UseRouting()`                                                                  |
| 🟡       | Arch | `UMS.Infrastructure/Identity/IdentityServiceExtensions.cs`       | Both `System.Text.Json` (in `ApplicationDbContext`) and `Newtonsoft.Json` (in JWT event handlers) are used in the same solution — doubles serialization surface                                      | Consolidate on `System.Text.Json`; replace `JsonConvert.SerializeObject` in JWT events                                 |
| 🟡       | Arch | `UMS.API/Endpoints/UserEndpoints.cs`                             | `generate-change-email-token` and `generate-2fa-recovery-codes` fall inside the `RequireAuthorization()` group but have **no specific permission** constraint — any authenticated user can call them | Add explicit `RequireAuthorization(AppPermission.NameFor(…, AppAction.ChangeEmail))` and `Manage2FA` respectively      |
| 🔵       | Arch | `UMS.Infrastructure/Identity/IdentityServiceExtensions.cs:47-49` | `IUserService`, `IRoleService`, and `ITokenService` are registered as `Transient` but wrap scoped dependencies (`UserManager<T>`) without comment                                                    | Add a brief comment or move to `Scoped` to match the lifetime of the dependencies they wrap                            |
| 🔵       | Arch | `UMS.Application/Authorization/AppPermissions.cs:76`             | `BasicPermissions` is always empty because all permissions default `IsBasic = false` — the `Basic` role is seeded with zero permissions                                                              | Mark intended basic permissions with `IsBasic = true`, or remove the `BasicPermissions`/`AdminPermissions` distinction |

---

## C. Security & Vulnerability Check

### Summary

Six critical issues. Two are high-severity data breaches (secrets in git, CORS wildcard). Two are standard OWASP concerns (user enumeration, claim injection). One is a missing HTTPS enforcement flag. All must be fixed before any non-local deployment.

| Severity | Area     | Location                                                                              | Issue                                                                                                                                                                    | Suggested Fix                                                                                                                                          |
| -------- | -------- | ------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 🔴       | Security | `UMS.API/appsettings.json`                                                            | **Production secrets committed to source control**: JWT signing key, `IdProtection.SecretKey`, SMTP password, and seed user passwords are all in plain text              | Remove all secrets; use ASP.NET Core User Secrets for local dev, environment variables or Azure Key Vault for staging/prod; **rotate every value now** |
| 🔴       | Security | `UMS.API/ServiceCollectionExtensions.cs:33-38`                                        | `AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader()` — allows any website to make cross-origin calls                                                                     | Configure a strict allowlist: `.WithOrigins("https://your-frontend.com").AllowAnyMethod().AllowAnyHeader()`                                            |
| 🔴       | Security | `UMS.Infrastructure/Identity/IdentityServiceExtensions.cs:95`                         | `bearer.RequireHttpsMetadata = false` — JWT tokens accepted over plain HTTP; `UseHsts()` is also absent                                                                  | Set `RequireHttpsMetadata = true`; add `app.UseHsts()` for non-development environments                                                                |
| 🔴       | Security | `UMS.Infrastructure/Identity/Services/UserService.cs:338,434`                         | **User enumeration**: `ForgotPasswordAsync` returns `"This email doesn't exist."` and `ResendConfirmationEmailAsync` does the same                                       | Return `"If the email is registered, you will receive an email shortly."` unconditionally                                                              |
| 🔴       | Security | `UMS.Infrastructure/Identity/Services/RoleService.cs:193-195`                         | `UpdateRolePermissionsAsync` uses `rc.ClaimType` directly from the client request — a caller can inject arbitrary claim types (e.g. `ClaimTypes.Email`) into a role      | Whitelist: force `ClaimType = AppClaim.Permission` and validate `ClaimValue` against `AppPermissions.AllPermissions`                                   |
| 🔴       | Security | `UMS.API/appsettings.json:3`                                                          | Connection string uses `TrustServerCertificate=True` — disables TLS certificate validation for SQL Server                                                                | Remove `TrustServerCertificate=True`; install a valid cert or use a proper CA chain                                                                    |
| 🟡       | Security | `UMS.Application/Features/Users/Commands/ChangeUserPassword/ChangePasswordRequest.cs` | `ChangePasswordRequest.UserId` comes from the request body — any user with `Update` permission can supply a different `UserId` and change another user's password (IDOR) | Derive `UserId` from `ICurrentUserService.GetUserId()` in the handler, not from the request DTO                                                        |
| 🟡       | Security | `UMS.Infrastructure/Identity/Services/TokenService.cs:239-266`                        | `GetClaimsAsync` queries role claims in a loop (N+1): for each role, a separate `_roleManager.GetClaimsAsync` roundtrip is made                                          | Use a single JOIN query: `_context.RoleClaims.Where(rc => roleIds.Contains(rc.RoleId))`                                                                |
| 🟡       | Security | `UMS.Infrastructure/Identity/Services/TokenService.cs:187-194`                        | 2FA JTI replay protection uses `IMemoryCache` (process-local) — in multi-instance deployments the same challenge token can be replayed against a different instance      | Replace with `IDistributedCache` (Redis / SQL)                                                                                                         |
| 🟡       | Security | `UMS.Infrastructure/Identity/Services/UserService.cs:511-512`                         | Admin lockout guard compares by email from `SeedUsersConfiguration` — brittle if admin email changes post-deployment                                                     | Use a dedicated `IsSystemAdmin` flag on `ApplicationUser`, or an immutable role-based guard                                                            |
| 🔵       | Security | `UMS.API/Program.cs:43-55`                                                            | Scalar API UI is publicly accessible in development without authentication (`.RequireAuthorization()` is commented out)                                                  | Uncomment or add `[Authorize]`                                                                                                                         |
| 🔵       | Security | `UMS.API/appsettings.json:25`                                                         | `EmailConfiguration.EnableSsl = false` — email sent over plain SMTP                                                                                                      | Set `true` for any non-test environment; template a per-environment override                                                                           |

---

## D. Maintainability & Flexibility

### Summary

The abstraction story is clean and the test suite is comprehensive. Two performance patterns stand out as problems at scale.

| Severity | Area     | Location                                                      | Issue                                                                                                                                                                             | Suggested Fix                                                                                    |
| -------- | -------- | ------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| 🟡       | Maintain | `UMS.Infrastructure/Identity/Services/UserService.cs:154-168` | `GetAllUsersAsync()` loads **every user into memory** with `ToListAsync()` — no pagination, no projection                                                                         | Deprecate or protect this endpoint; for public use, replace with the existing paged variant      |
| 🟡       | Maintain | `UMS.Infrastructure/Identity/Services/UserService.cs:280-295` | `GetUserRolesAsync` iterates all roles and calls `_userManager.IsInRoleAsync` per role — N database calls                                                                         | Use `_userManager.GetRolesAsync(user)` once and compute the ViewModel in memory                  |
| 🟡       | Maintain | `UMS.Infrastructure/Identity/Services/TokenService.cs:63-66`  | `AccessFailedAsync` is called **before** the lockout check (line 69) — a locked-out user who enters the wrong password gets "Invalid Credentials" rather than "Account is locked" | Move `IsLockedOutAsync` check to before the password check and before `AccessFailedAsync`        |
| 🔵       | Maintain | `UMS.Infrastructure/Identity/Services/UserService.cs:66`      | `RefreshToken` initialized to `_dateTimeService.NowUtc.Ticks.ToString()` during registration — predictable, low-entropy value                                                     | Use `GenerateRefreshToken()` (already available in `TokenService`) or move it to a shared helper |

---

## Top 5 Priorities (Fix in This Order)

| #   | Priority                                                             | Description                                                                                                                                                                                                                 |
| --- | -------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | 🔴 **Rotate & externalize all secrets**                              | The JWT key, email password, IdProtection key, and seed passwords in `appsettings.json` are in git history and must be treated as compromised. Rotate every value immediately; move to User Secrets / env vars / Key Vault. |
| 2   | 🔴 **Restrict CORS and enable HTTPS enforcement**                    | Replace `AllowAnyOrigin` with a specific origin allowlist. Set `RequireHttpsMetadata = true`. Add `app.UseHsts()` for non-development.                                                                                      |
| 3   | 🔴 **Fix claim injection in `UpdateRolePermissionsAsync`**           | Whitelist the allowed `ClaimType` to `AppClaim.Permission` and validate `ClaimValue` against the known permission list before persisting.                                                                                   |
| 4   | 🔴 **Fix user enumeration in ForgotPassword and ResendConfirmation** | Return a fixed, non-disclosing message regardless of whether the email exists.                                                                                                                                              |
| 5   | 🟡 **Fix validation pipeline status code + IDOR in ChangePassword**  | Validation failures returning 500 confuse clients and monitoring. `ChangePasswordRequest.UserId` from the body is an IDOR — derive it from the JWT instead.                                                                 |

---

## High-Level Refactoring Recommendations

1. **Rate limiting** — Add `app.UseRateLimiter()` (.NET 7+) with a sliding-window policy on `/account/login`, `/account/forgot-password`, and `/account/login-2fa` to defend against brute-force.
2. **Consolidate JSON serializer** — Remove the `Newtonsoft.Json` dependency; rewrite the JWT event handlers using `System.Text.Json`.
3. **Distributed 2FA JTI store** — Extract the replay cache into `IDistributedCache` now so scaling later is a config change, not a code change.
4. **N+1 claim loading** — Refactor `GetClaimsAsync` in `TokenService` to a single query joining `UserRoles → Roles → RoleClaims` in one DB round-trip.
5. **Soft-delete global filters** — Verify that `OutboxMessage` is correctly excluded from the soft-delete query filter (the `OnModelCreating` loop already skips `AuditTrail`).
