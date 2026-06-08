# UMS Backend Security

**Type:** Rule  
**Applies To:** Backend (C# / .NET)  
**When to Use:** Apply when adding or modifying authenticated endpoints, defining authorization policies, handling passwords/tokens, or working with file storage.

---

## 1. Authentication and JWT Setup

- **JWT Parameters:** Bearer tokens must be configured using secure parameters retrieved from the application settings:
  - `JwtSettings:SecretKey` (Minimum 32 characters / 256 bits. Generate using `openssl rand -base64 32`).
  - `JwtSettings:Issuer`.
  - `JwtSettings:Audience`.
  - Token expiration limits must be strictly set (e.g., Access token: 15 mins, Refresh token: 7 days).
- **Authentication Rate Limiting:** All authentication-related routes (e.g., login, register, password reset, 2FA validation) must be guarded using rate-limiting policies:
  ```csharp
  // Configure sliding window limiter for auth endpoints
  builder.Services.AddRateLimiter(options =>
  {
      options.AddSlidingWindowLimiter("auth", limiter => { ... });
  });
  // Enforce on endpoints
  group.RequireRateLimiting("auth");
  ```

### CSRF Protection
- Because refresh tokens are stored in `httpOnly` cookies, the API is vulnerable to CSRF. Mitigate this by configuring the cookie with `SameSite=Strict` (or `Lax` where necessary).
- For API mutation requests, require either an anti-forgery token via `builder.Services.AddAntiforgery()` and `RequireAntiforgery()`, or enforce a custom header requirement (e.g., `X-Requested-With: XMLHttpRequest`) which browsers automatically prevent cross-origin.
- *Note: Short-lived access tokens kept purely in memory and sent via `Authorization: Bearer` headers are inherently CSRF-resistant.*

### Identity & Password Policies
- Enforce ASP.NET Identity's lockout settings (e.g., `DefaultLockoutTimeSpan`, `MaxFailedAccessAttempts`) and password complexity requirements (`RequiredLength`, `RequireDigit`, etc.) in the Infrastructure identity configuration.

---

## 2. Permission Authorization Architecture (`AppPermission`)

- **Banned Custom Verification:** Handlers must never perform custom security role or claim evaluations inline.
- **Strongly Typed Constants:** Permissions must be defined using static constants representing structured paths mapped inside `AppPermissions` (e.g., using `AppService`, `AppFeature`, and `AppAction`).
- **RULE: Enforcing Policy Checks:** All mutating endpoints (Create, Update, Delete, status change, lock/unlock, etc.) and restricted query/export endpoints must be explicitly guarded at the routing boundary using strongly typed authorization policies derived from `AppPermission.NameFor(...)`:
  ```csharp
  .RequireAuthorization(AppPermission.NameFor(AppService.Product, AppFeature.Categories, AppAction.Create))
  ```
- Anonymous access should only be allowed where explicitly specified (e.g., public read queries/lists using `.AllowAnonymous()`).

---

## 3. Workflow for Adding New Authorized Endpoints

When implementing a feature that requires access control, developers must strictly execute this sequence:
1. **Define Permission:** Add the permission constant in `AppPermissions` under the appropriate Service/Feature/Action definition.
2. **Configure Baseline Seeding:** Add the new permission string mapping to the baseline seeding task (e.g., in `ApiTestDatabaseInitializer.cs` or production seeders) to ensure it is granted to the `Admin` role by default.
3. **Guards on Endpoints:** Append the fluent validation method `.RequireAuthorization(AppPermission.NameFor(AppService.X, AppFeature.Y, AppAction.Z))` onto the Minimal API endpoint map definition.

---

## 4. Input Validation (Defense in Depth)

- **API-Level Validation:** Intercept bad data at the entry boundary using FluentValidation mapping via the `IValidateMe` pipeline.
- **Domain Invariant Validation:** Maintain database integrity by validating parameters at creation within domain models (e.g., validation rules inside constructors or setters) to ensure invalid entities are never instantiated.

---

## 5. Protected/Sensitive Data Management

- **Logging Scrubbing:** Never log user passwords, security tokens, verification pins, recovery codes, or sensitive PII details.
- **Sanitized Responses:** Internal exceptions (such as stack traces, database schema errors, SQL state exceptions) must never be returned to the client in production responses. Return generic error messages via the `ResponseWrapper` envelope instead.

---

## 6. Secure File Storage and Upload Rules

- **Upload Handlers:** API endpoints must never write uploaded files directly to local disk folders.
- **Service Abstracting:** All files must be processed and persisted using the configured `IFileStorageService` abstraction.
- **Security Checklists:** Before saving a file, verify the following details:
  - Validate file extension against a clean whitelist (e.g., `.jpg`, `.png`, `.pdf`).
  - Enforce strict size limits (e.g., maximum 5MB).
  - Clean and rename filenames (e.g., convert to GUIDs) to prevent path traversal attacks.

---

## 7. Production Security Hardening

- **CORS Policy:** Define explicit origin allowlists. Never use `AllowAnyOrigin` in production environments.
- **HTTPS Enforcement:** Mandate `app.UseHttpsRedirection()` and `app.UseHsts()` in production pipeline configuration.
- **Security Headers:** Add middleware to inject `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, and appropriate Content-Security-Policy headers.
- **Token Storage on Client:** Mandate `httpOnly` cookies for refresh tokens. Short-lived access tokens may be kept in memory only; never store tokens in `localStorage`.
- **Input Size Limits:** Enforce `maxRequestBodySize` and `KestrelServerLimits.MaxRequestLength` to prevent DoS via oversized payloads.
