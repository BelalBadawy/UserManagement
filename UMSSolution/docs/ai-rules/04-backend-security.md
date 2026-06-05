# UMS Backend Security

**Type:** Rule  
**Applies To:** Backend (C# / .NET)  
**When to Use:** Apply when adding or modifying authenticated endpoints, defining authorization policies, handling passwords/tokens, or working with file storage.

---

## 1. Authentication and JWT Setup

- **JWT Parameters:** Bearer tokens must be configured using secure parameters retrieved from the application settings:
  - `JwtSettings:SecretKey` (minimum 256-bit entropy).
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

---

## 2. Permission Authorization Architecture (`AppPermission`)

- **Banned Custom Verification:** Handlers must never perform custom security role or claim evaluations inline.
- **Strongly Typed Constants:** Permissions must be defined as static constants representing structured paths (e.g. `Permission.Identity.Users.Read` mapped inside `AppPermissions`).
- **Enforcing Policy Checks:** Secure Minimal API endpoints at the routing boundary using:
  ```csharp
  .RequireAuthorization(AppPermission.NameFor(AppService.Product, AppFeature.Categories, AppAction.Create))
  ```

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
