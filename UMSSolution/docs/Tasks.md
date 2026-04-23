# Project Tasks: UMS Enterprise Refactoring

## Phase 1: Critical Security & Validation Fixes

### Task 1.1: Remove committed secrets from API configuration

Status: - [ ]
Description: Remove the hardcoded `DefaultConnection`, `IdProtection:SecretKey`, `JwtConfiguration:Secret`, and `EmailConfiguration:password` values from the tracked API configuration file. Replace each secret-bearing value with a non-secret placeholder or environment-variable-based configuration key so the repository no longer contains usable credentials.
File(s): `UMS.API/appsettings.json`
Acceptance Criteria:

- [ ] `UMS.API/appsettings.json` no longer contains a real database connection string, JWT secret, ID protection secret, or SMTP password.
- [ ] Secret-bearing settings are represented by non-sensitive placeholders or environment-variable-driven values only.
- [ ] A repository text search for the removed literal secret values returns no matches in tracked source files.

### Task 1.2: Remove hardcoded seeded admin credentials

Status: - [ ]
Description: Delete the hardcoded `Email` and `Password` constants used for seeded credentials so the repository does not store reusable administrator login data. Replace the implementation with configuration-driven or environment-driven bootstrap values that are not committed as secrets.
File(s): `UMS.Infrastructure/Identity/Constants/AppCredentials.cs`
Acceptance Criteria:

- [ ] `AppCredentials.cs` no longer contains the literal values `admin@gmail.com` or `Admin@123`.
- [ ] Seed credential values are sourced from non-committed configuration or are replaced with non-secret placeholders that cannot be used as real credentials.
- [ ] A repository text search for `admin@gmail.com` and `Admin@123` no longer finds matches in production source files.

### Task 1.3: Fix validation pipeline failure detection logic

Status: - [ ]
Description: Replace the incorrect condition `if (!validationResults.Any(vr => vr.IsValid))` with logic that collects all `ValidationFailure` items and fails whenever at least one validation failure exists. Preserve the existing aggregation of error messages and short-circuit the request when any validator reports an error.
File(s): `UMS.Application/Behaviors/ValidationPipelineBehavior.cs`
Acceptance Criteria:

- [ ] The pipeline returns a failed response when one validator fails and another validator passes for the same request.
- [ ] The decision to fail is based on the presence of validation failures, not on whether all validators are invalid.
- [ ] The file contains no remaining use of `!validationResults.Any(vr => vr.IsValid)`.

### Task 1.4: Add a validator for DeleteRoleCommand

Status: - [ ]
Description: Create a dedicated FluentValidation validator for `DeleteRoleCommand` that enforces `RoleId > 0`. The validator must be discoverable by the existing assembly scanning in the Application layer.
File(s): `UMS.Application/Features/Roles/Commands/DeleteRole/DeleteRoleCommand.cs`, `UMS.Application/Features/Roles/Commands/DeleteRole/DeleteRoleCommandValidator.cs`
Acceptance Criteria:

- [ ] A new validator file exists for `DeleteRoleCommand`.
- [ ] The validator contains a rule that rejects `RoleId <= 0`.
- [ ] The validator class is in the Application assembly and is discoverable by `AddValidatorsFromAssembly`.

### Task 1.5: Enable validation pipeline execution for DeleteRoleCommand

Status: - [ ]
Description: Modify `DeleteRoleCommand` so it implements `IValidateMe`, allowing the existing `ValidationPipelineBehavior` to execute the newly added validator before the handler runs.
File(s): `UMS.Application/Features/Roles/Commands/DeleteRole/DeleteRoleCommand.cs`
Acceptance Criteria:

- [ ] `DeleteRoleCommand` implements `IValidateMe`.
- [ ] Invalid `RoleId` values are rejected by the validation pipeline before `DeleteRoleCommandHandler.Handle` executes.
- [ ] The handler file no longer relies on missing pipeline validation for this command.

### Task 1.6: Enable validation pipeline execution for UpdateUserRolesCommand

Status: - [ ]
Description: Modify `UpdateUserRolesCommand` so it implements `IValidateMe`, allowing the existing `UpdateUserRolesCommandValidator` to run through the validation pipeline before the handler executes.
File(s): `UMS.Application/Features/Users/Commands/UpdateUserRoles/UpdateUserRolesCommand.cs`
Acceptance Criteria:

- [ ] `UpdateUserRolesCommand` implements `IValidateMe`.
- [ ] Invalid `UpdateUserRolesRequest` payloads are rejected by the validation pipeline before `UpdateUserRolesCommandHandler.Handle` executes.
- [ ] The validator file for `UpdateUserRolesCommand` is actively enforceable without changing the handler.

### Task 1.7: Enable validation pipeline execution for GetRefreshTokenQuery

Status: - [ ]
Description: Modify `GetRefreshTokenQuery` so it implements `IValidateMe`, allowing `GetRefreshTokenQueryValidator` to execute through the validation pipeline before the handler runs.
File(s): `UMS.Application/Features/Token/Queries/GetRefreshToken/GetRefreshTokenQuery.cs`
Acceptance Criteria:

- [ ] `GetRefreshTokenQuery` implements `IValidateMe`.
- [ ] Requests with empty `Token` or empty `RefreshToken` are rejected by the validation pipeline before `GetRefreshTokenQueryHandler.Handle` executes.
- [ ] The query can no longer bypass its validator.

### Task 1.8: Fix GetRefreshTokenQueryValidator namespace

Status: - [ ]
Description: Change the validator namespace from `UMS.Application.Features.Users.Validators` to the correct token query namespace so the file matches the feature structure and does not misclassify token validation as a user validator.
File(s): `UMS.Application/Features/Token/Queries/GetRefreshToken/GetRefreshTokenQueryValidator.cs`
Acceptance Criteria:

- [ ] The validator namespace matches the token query feature path.
- [ ] The validator type remains discoverable by Application assembly scanning.
- [ ] The file contains no `UMS.Application.Features.Users.Validators` namespace.

### Task 1.9: Rewrite user registration to use UserManager password flow

Status: - [ ]
Description: Remove the manual `PasswordHasher<ApplicationUser>` usage in `RegisterUserAsync` and call `_userManager.CreateAsync(newUser, userRegistration.Password)` so ASP.NET Identity enforces password validators, hashing, and lifecycle rules through the framework-supported path.
File(s): `UMS.Infrastructure/Identity/Services/UserService.cs`
Acceptance Criteria:

- [ ] `RegisterUserAsync` no longer creates `PasswordHasher<ApplicationUser>` directly.
- [ ] The user creation path uses `_userManager.CreateAsync(user, password)`.
- [ ] Password validation and hashing are delegated entirely to ASP.NET Identity.

### Task 1.10: Remove hardcoded seeded refresh token literals

Status: - [ ]
Description: Replace the literal seeded refresh token values `"123"` and `"321"` with non-hardcoded values that are not usable shared credentials. Do not leave static reusable token strings in the seed data.
File(s): `UMS.Infrastructure/Identity/Seeds/IdentityDbSeeder.cs`
Acceptance Criteria:

- [ ] `IdentityDbSeeder.cs` no longer contains `RefreshToken = "123"` or `RefreshToken = "321"`.
- [ ] Seeded refresh token values are generated or assigned in a non-reusable, non-hardcoded manner.
- [ ] A repository text search for those literals returns no matches in tracked source files.

### Task 1.11: Fix attachment stream lifetime in MailSenderService

Status: - [ ]
Description: Remove the pattern that creates `MemoryStream` instances inside a `using` scope and then adds them to `attachmentList` for later use. Ensure every attachment stream remains valid until `email.SendAsync(ct)` completes.
File(s): `UMS.Infrastructure/Services/Common/MailSenderService.cs`
Acceptance Criteria:

- [ ] No attachment stream is disposed before `email.SendAsync(ct)` completes.
- [ ] File attachments can be sent without using disposed streams.
- [ ] The file contains no `using var ms = new MemoryStream();` inside the attachment loop if the stream is stored for later send.

### Task 1.12: Honor EmailConfiguration.EnableSsl in MailSenderService

Status: - [ ]
Description: Replace the hardcoded `EnableSsl = true` assignment with the configured `_emailSettings.EnableSsl` value so the mail sender respects the declared environment configuration.
File(s): `UMS.Infrastructure/Services/Common/MailSenderService.cs`
Acceptance Criteria:

- [ ] The SMTP client uses `_emailSettings.EnableSsl`.
- [ ] The file contains no hardcoded `EnableSsl = true`.
- [ ] Mail sender behavior is controlled by `EmailConfiguration.EnableSsl`.

## Phase 2: Architecture & Clean Code Violations

### Task 2.1: Remove sync-over-async startup call from Program.cs

Status: - [ ]
Description: Eliminate `app.UseInfrastructureAsync().GetAwaiter().GetResult()` and change startup composition to use a fully asynchronous bootstrapping path. The final startup code must not block on an async method with `GetAwaiter().GetResult()`.
File(s): `UMS.API/Program.cs`, `UMS.Infrastructure/ServiceCollectionExtensions.cs`
Acceptance Criteria:

- [ ] `Program.cs` contains no `GetAwaiter().GetResult()` call.
- [ ] Infrastructure initialization is awaited through an async startup path.
- [ ] Application startup compiles and runs without sync-over-async blocking.

### Task 2.2: Remove duplicate IHttpContextAccessor registration

Status: - [ ]
Description: Delete the redundant explicit singleton registration `AddSingleton<IHttpContextAccessor, HttpContextAccessor>()` because `AddHttpContextAccessor()` already registers the service correctly.
File(s): `UMS.API/Program.cs`
Acceptance Criteria:

- [ ] `Program.cs` contains only one `IHttpContextAccessor` registration pattern.
- [ ] The explicit singleton registration is removed.
- [ ] API startup still resolves `IHttpContextAccessor` successfully.

### Task 2.3: Eliminate Infrastructure permission constant dependency from Category endpoints

Status: - [ ]
Description: Move the permission naming contract used by `CategoryEndpoints` out of Infrastructure so the API endpoint file no longer imports `UMS.Infrastructure.Identity.Constants`. Replace direct Infrastructure constant usage with an Application-layer or shared contract abstraction.
File(s): `UMS.API/Endpoints/CategoryEndpoints.cs`, `UMS.Infrastructure/Identity/Constants/AppAction.cs`, `UMS.Infrastructure/Identity/Constants/AppFeature.cs`, `UMS.Infrastructure/Identity/Constants/AppPermission.cs`, `UMS.Infrastructure/Identity/Constants/AppService.cs`
Acceptance Criteria:

- [ ] `CategoryEndpoints.cs` no longer imports `UMS.Infrastructure.Identity.Constants`.
- [ ] Authorization policy names used by category endpoints come from a non-Infrastructure contract.
- [ ] API builds without direct permission-constant coupling to Infrastructure.

### Task 2.4: Eliminate Infrastructure permission constant dependency from Role endpoints

Status: - [ ]
Description: Move the permission naming contract used by `RoleEndpoints` out of Infrastructure so the API endpoint file no longer imports `UMS.Infrastructure.Identity.Constants`.
File(s): `UMS.API/Endpoints/RoleEndpoints.cs`, `UMS.Infrastructure/Identity/Constants/AppAction.cs`, `UMS.Infrastructure/Identity/Constants/AppFeature.cs`, `UMS.Infrastructure/Identity/Constants/AppPermission.cs`, `UMS.Infrastructure/Identity/Constants/AppService.cs`
Acceptance Criteria:

- [ ] `RoleEndpoints.cs` no longer imports `UMS.Infrastructure.Identity.Constants`.
- [ ] Authorization policy names used by role endpoints come from a non-Infrastructure contract.
- [ ] API builds without direct permission-constant coupling to Infrastructure.

### Task 2.5: Eliminate Infrastructure permission constant dependency from User endpoints

Status: - [ ]
Description: Move the permission naming contract used by `UserEndpoints` out of Infrastructure so the API endpoint file no longer imports `UMS.Infrastructure.Identity.Constants`.
File(s): `UMS.API/Endpoints/UserEndpoints.cs`, `UMS.Infrastructure/Identity/Constants/AppAction.cs`, `UMS.Infrastructure/Identity/Constants/AppFeature.cs`, `UMS.Infrastructure/Identity/Constants/AppPermission.cs`, `UMS.Infrastructure/Identity/Constants/AppService.cs`
Acceptance Criteria:

- [ ] `UserEndpoints.cs` no longer imports `UMS.Infrastructure.Identity.Constants`.
- [ ] Authorization policy names used by user endpoints come from a non-Infrastructure contract.
- [ ] API builds without direct permission-constant coupling to Infrastructure.

### Task 2.6: Replace IFormFile in application file storage abstraction

Status: - [ ]
Description: Remove `IFormFile` from the Application layer file storage contract and replace it with a web-agnostic abstraction such as `Stream` plus metadata parameters required by the storage implementation. Update the interface signature so Application no longer depends on ASP.NET request types.
File(s): `UMS.Application/Interfaces/Common/IFileStorageService.cs`, `UMS.Application/UMS.Application.csproj`
Acceptance Criteria:

- [ ] `IFileStorageService` contains no `IFormFile` type usage.
- [ ] `UMS.Application.csproj` no longer requires ASP.NET-specific types solely for file storage abstractions.
- [ ] The Application layer no longer imports `Microsoft.AspNetCore.Http` for this contract.

### Task 2.7: Replace IFormFile in application email attachment DTO

Status: - [ ]
Description: Remove `IFormFile` from `SendEmailDto.Attachments` and replace it with a transport-agnostic attachment model that can be used outside ASP.NET request binding.
File(s): `UMS.Application/Dtos/Email/SendEmailDto.cs`
Acceptance Criteria:

- [ ] `SendEmailDto` contains no `IFormFile` property.
- [ ] Attachment data is represented by a web-agnostic model.
- [ ] The DTO can be used without referencing ASP.NET request types.

### Task 2.8: Remove obsolete ASP.NET Http package reference from Application project

Status: - [ ]
Description: Delete the `Microsoft.AspNetCore.Http` package reference from the Application project after removing all ASP.NET-only types from Application contracts and DTOs.
File(s): `UMS.Application/UMS.Application.csproj`
Acceptance Criteria:

- [ ] `UMS.Application.csproj` no longer references `Microsoft.AspNetCore.Http`.
- [ ] The Application project still builds successfully.
- [ ] No Application file requires ASP.NET-only HTTP types.

### Task 2.9: Remove DbContext cast from UpdateCategoryCommandHandler

Status: - [ ]
Description: Stop casting `IApplicationDbContext` to `DbContext` inside `UpdateCategoryCommandHandler`. Introduce an explicit abstraction on `IApplicationDbContext` for setting the original row version required for optimistic concurrency.
File(s): `UMS.Application/Features/Categories/Commands/Update/UpdateCategoryCommand.cs`, `UMS.Application/Interfaces/Common/IApplicationDbContext.cs`, `UMS.Infrastructure/Persistence/Contexts/ApplicationDbContext.cs`
Acceptance Criteria:

- [ ] `UpdateCategoryCommandHandler` contains no cast from `IApplicationDbContext` to `DbContext`.
- [ ] `IApplicationDbContext` exposes an explicit concurrency-related operation needed by the handler.
- [ ] Concurrency checks still work without leaking EF Core concrete type knowledge into Application.

### Task 2.10: Use ICurrentUserService for audit user IDs

Status: - [ ]
Description: Replace the hardcoded `userId = 0` assignments in `SaveChangesAsync` and `OnBeforeSaveChanges` with values retrieved from `_currentUserService.GetUserId()`. Ensure `CreatedBy`, `LastModifiedBy`, `DeletedBy`, and audit trail `UserId` reflect the real authenticated user when available.
File(s): `UMS.Infrastructure/Persistence/Contexts/ApplicationDbContext.cs`
Acceptance Criteria:

- [ ] `ApplicationDbContext.cs` contains no hardcoded `userId = 0` assignments for audit attribution.
- [ ] Audit and entity metadata use `_currentUserService.GetUserId()` when available.
- [ ] Created, modified, deleted, and audit records all derive actor identity from the current user service.

### Task 2.11: Remove broken duplicate CurrentUserService implementation

Status: - [ ]
Description: Delete the duplicate `CurrentUserService` implementation under `UMS.Infrastructure/Identity/Services` because its `SetCurrentUser` logic is incorrect and it conflicts conceptually with the working implementation in `UMS.Infrastructure/Services/Common`.
File(s): `UMS.Infrastructure/Identity/Services/CurrentUserService.cs`, `UMS.Infrastructure/Identity/IdentityServiceExtensions.cs`, `UMS.Infrastructure/ServiceCollectionExtensions.cs`
Acceptance Criteria:

- [ ] The duplicate `UMS.Infrastructure/Identity/Services/CurrentUserService.cs` file is removed or no longer used.
- [ ] DI registers exactly one `ICurrentUserService` implementation.
- [ ] Middleware and persistence code resolve the intended single current-user service implementation.

### Task 2.12: Remove duplicate ICurrentUserService registrations

Status: - [ ]
Description: Ensure `ICurrentUserService` is registered exactly once in the Infrastructure composition root after removing the duplicate implementation.
File(s): `UMS.Infrastructure/Identity/IdentityServiceExtensions.cs`, `UMS.Infrastructure/ServiceCollectionExtensions.cs`
Acceptance Criteria:

- [ ] Only one registration for `ICurrentUserService` exists across Infrastructure DI setup.
- [ ] The registered implementation is the working `UMS.Infrastructure.Services.Common.CurrentUserService`.
- [ ] Application startup resolves `ICurrentUserService` without ambiguity.

### Task 2.13: Define category normalized fields and unique indexes explicitly

Status: - [ ]
Description: Add explicit model configuration for the `NormalizedName` and `NormalizedSlug` values used by the category write commands, including the required unique indexes. The runtime model must match the query logic that uses these fields.
File(s): `UMS.Infrastructure/Persistence/DbConfigurations/CategoryConfiguration.cs`, `UMS.Application/Features/Categories/Commands/Create/CreateCategoryCommand.cs`, `UMS.Application/Features/Categories/Commands/Update/UpdateCategoryCommand.cs`
Acceptance Criteria:

- [ ] `CategoryConfiguration.cs` defines the normalized fields required by the category command queries.
- [ ] Unique indexes exist for the normalized category name and slug fields.
- [ ] The Application category command handlers query fields that are explicitly part of the EF model.

### Task 2.14: Configure Category.RowVersion as an explicit concurrency token

Status: - [ ]
Description: Add explicit EF configuration for `Category.RowVersion` so optimistic concurrency is enforced through model configuration rather than assumed behavior.
File(s): `UMS.Infrastructure/Persistence/DbConfigurations/CategoryConfiguration.cs`
Acceptance Criteria:

- [ ] `Category.RowVersion` is configured as a concurrency token in EF model configuration.
- [ ] The model configuration explicitly maps the row version behavior instead of leaving it implicit.
- [ ] Category update concurrency conflicts can be detected through EF configuration alone.

### Task 2.15: Generate a migration for category normalized fields and concurrency configuration

Status: - [ ]
Description: Create a new EF Core migration that captures the explicit `NormalizedName`, `NormalizedSlug`, and `RowVersion` model changes required by the category configuration updates.
File(s): `UMS.Infrastructure/Migrations/*`, `UMS.Infrastructure/Persistence/DbConfigurations/CategoryConfiguration.cs`
Acceptance Criteria:

- [ ] A new migration file exists after the configuration changes.
- [ ] The migration includes schema operations for the normalized category fields and their indexes if they were not already modeled correctly.
- [ ] The migration snapshot matches the updated `CategoryConfiguration`.

### Task 2.16: Fix wrong namespace on custom AuthorizeAttribute

Status: - [ ]
Description: Change the namespace from `eShop.Application.Attributes` to the correct UMS namespace so the file is not carrying unrelated project identity.
File(s): `UMS.Application/Attributes/AuthorizeAttribute.cs`
Acceptance Criteria:

- [ ] The file no longer uses the `eShop.Application.Attributes` namespace.
- [ ] The namespace aligns with the UMS Application project structure.
- [ ] The project builds without the old namespace.

### Task 2.17: Remove unused custom AuthorizeAttribute if it is not referenced

Status: - [ ]
Description: If the renamed custom `AuthorizeAttribute` is not referenced anywhere in the solution after namespace correction, delete the file entirely to remove dead code.
File(s): `UMS.Application/Attributes/AuthorizeAttribute.cs`
Acceptance Criteria:

- [ ] The attribute file is removed if no solution references remain.
- [ ] A repository text search confirms there are no usages before deletion.
- [ ] The solution builds successfully after deletion.

### Task 2.18: Fix incorrect validator class name for UpdateUserCommand

Status: - [ ]
Description: Rename `UpdateUserCommandValidatorValidator` to `UpdateUserCommandValidator` so the class name matches the file name and feature intent.
File(s): `UMS.Application/Features/Users/Commands/UpdateUser/UpdateUserCommandValidator.cs`
Acceptance Criteria:

- [ ] The validator class is named `UpdateUserCommandValidator`.
- [ ] The file name and class name match.
- [ ] Validator discovery still works after the rename.

### Task 2.19: Fix incorrect validator class name for ForgotPasswordCommand

Status: - [ ]
Description: Rename `ForgotPasswordCommandValidatorValidator` to `ForgotPasswordCommandValidator` so the class name matches the file name and feature intent.
File(s): `UMS.Application/Features/Users/Commands/ForgotPassword/ForgotPasswordCommandValidator.cs`
Acceptance Criteria:

- [ ] The validator class is named `ForgotPasswordCommandValidator`.
- [ ] The file name and class name match.
- [ ] Validator discovery still works after the rename.

### Task 2.20: Remove meaningless boolean NotNull validation from UserRegistrationCommandValidator

Status: - [ ]
Description: Delete the `NotNull()` rules applied to non-nullable `bool` properties `AutoConfirmEmail` and `ActivateUser`, because those rules can never fail and provide false validation coverage.
File(s): `UMS.Application/Features/Users/Commands/UserRegistration/UserRegistrationCommandValidator.cs`
Acceptance Criteria:

- [ ] The validator contains no `NotNull()` checks on `AutoConfirmEmail`.
- [ ] The validator contains no `NotNull()` checks on `ActivateUser`.
- [ ] Remaining rules in the validator still compile and execute correctly.

### Task 2.21: Remove meaningless boolean NotNull validation from ChangeUserStatusValidator

Status: - [ ]
Description: Delete the `NotNull()` rule applied to non-nullable `bool` property `ActivateOrDeactivate`, because the rule can never fail.
File(s): `UMS.Application/Features/Users/Commands/ChangeUserStatus/ChangeUserStatusValidator.cs`
Acceptance Criteria:

- [ ] The validator contains no `NotNull()` rule for `ActivateOrDeactivate`.
- [ ] The validator still enforces `UserId` validation.
- [ ] The file builds without the removed boolean rule.

### Task 2.22: Add validator for GetRoleByIdQuery

Status: - [ ]
Description: Create a FluentValidation validator that enforces `RoleId > 0` for `GetRoleByIdQuery`.
File(s): `UMS.Application/Features/Roles/Queries/GetRoleById/GetRoleByIdQuery.cs`, `UMS.Application/Features/Roles/Queries/GetRoleById/GetRoleByIdQueryValidator.cs`
Acceptance Criteria:

- [ ] A validator file exists for `GetRoleByIdQuery`.
- [ ] The validator rejects `RoleId <= 0`.
- [ ] The query participates in pipeline validation if required by the current pipeline marker pattern.

### Task 2.23: Add validator for GetPermissionsQuery

Status: - [ ]
Description: Create a FluentValidation validator that enforces `RoleId > 0` for `GetPermissionsQuery`.
File(s): `UMS.Application/Features/Roles/Queries/GetPermissions/GetPermissionsQuery.cs`, `UMS.Application/Features/Roles/Queries/GetPermissions/GetPermissionsQueryValidator.cs`
Acceptance Criteria:

- [ ] A validator file exists for `GetPermissionsQuery`.
- [ ] The validator rejects `RoleId <= 0`.
- [ ] The query participates in pipeline validation if required by the current pipeline marker pattern.

### Task 2.24: Add validator for GetUserRolesQuery

Status: - [ ]
Description: Create a FluentValidation validator that enforces `UserId > 0` for `GetUserRolesQuery`.
File(s): `UMS.Application/Features/Users/Queries/GetUserRolesQuery.cs`, `UMS.Application/Features/Users/Queries/GetUserRolesQueryValidator.cs`
Acceptance Criteria:

- [ ] A validator file exists for `GetUserRolesQuery`.
- [ ] The validator rejects `UserId <= 0`.
- [ ] The query participates in pipeline validation if required by the current pipeline marker pattern.

### Task 2.25: Add validator for GetCategoryByIdQuery

Status: - [ ]
Description: Create a FluentValidation validator that enforces `Id > 0` for `GetCategoryByIdQuery`.
File(s): `UMS.Application/Features/Categories/Queries/GetCategoryById/GetCategoryByIdQuery.cs`, `UMS.Application/Features/Categories/Queries/GetCategoryById/GetCategoryByIdQueryValidator.cs`
Acceptance Criteria:

- [ ] A validator file exists for `GetCategoryByIdQuery`.
- [ ] The validator rejects `Id <= 0`.
- [ ] The query participates in pipeline validation if required by the current pipeline marker pattern.

### Task 2.26: Add validator for GetCategoryByIdAdminQuery

Status: - [ ]
Description: Create a FluentValidation validator that enforces `Id > 0` for `GetCategoryByIdAdminQuery`.
File(s): `UMS.Application/Features/Categories/Queries/GetCategoryByIdAdmin/GetCategoryByIdAdmin.cs`, `UMS.Application/Features/Categories/Queries/GetCategoryByIdAdmin/GetCategoryByIdAdminQueryValidator.cs`
Acceptance Criteria:

- [ ] A validator file exists for `GetCategoryByIdAdminQuery`.
- [ ] The validator rejects `Id <= 0`.
- [ ] The query participates in pipeline validation if required by the current pipeline marker pattern.

### Task 2.27: Add SortBy whitelist validation for GetCategoriesPagedQuery

Status: - [ ]
Description: Add explicit allowed sort-field validation to `GetCategoriesPagedQueryValidator` for the category paging query, matching the sort cases implemented in the handler.
File(s): `UMS.Application/Features/Categories/Queries/GetCategoriesPaged/GetCategoriesPagedQueryValidator.cs`, `UMS.Application/Features/Categories/Queries/GetCategoriesPaged/GetCategoriesPagedQuery.cs`
Acceptance Criteria:

- [ ] The validator rejects unsupported `SortBy` values.
- [ ] The allowed values match the sort switch cases implemented in the handler.
- [ ] Valid requests using supported sort fields pass validation.

### Task 2.28: Add SortBy whitelist validation for GetCategoriesPagedAdminQuery

Status: - [ ]
Description: Add explicit allowed sort-field validation to `GetCategoriesPagedAdminQueryValidator`, matching the sort cases implemented in the admin paging handler.
File(s): `UMS.Application/Features/Categories/Queries/GetCategoriesPagedAdmin/GetCategoriesPagedAdminQueryValidator.cs`, `UMS.Application/Features/Categories/Queries/GetCategoriesPagedAdmin/GetCategoriesPagedAdminQuery.cs`
Acceptance Criteria:

- [ ] The validator rejects unsupported `SortBy` values.
- [ ] The allowed values match the sort switch cases implemented in the handler.
- [ ] Valid requests using supported sort fields pass validation.

### Task 2.29: Fix filtered category cache key collision in GetAllCategoriesQuery

Status: - [ ]
Description: Replace the single cache key `CategoryCacheKeys.GetAll` with a key that includes the `isActive` filter value so filtered and unfiltered category lists cannot overwrite each other.
File(s): `UMS.Application/Features/Categories/Queries/GetAllCategories/GetAllCategoriesQuery.cs`, `UMS.Application/Features/Categories/CategoryCacheKeys.cs`
Acceptance Criteria:

- [ ] Cached category list keys differ for `isActive = true`, `isActive = false`, and `isActive = null`.
- [ ] The query no longer reads or writes filtered and unfiltered data under the same cache key.
- [ ] Cache invalidation still removes all category list variants.

## Phase 3: Performance & Async Issues

### Task 3.1: Add CancellationToken to Account endpoint handlers

Status: - [ ]
Description: Add `CancellationToken ct` parameters to each endpoint delegate in `AccountEndpoints` and pass the token into `sender.Send(...)`.
File(s): `UMS.API/Endpoints/AccountEndpoints.cs`
Acceptance Criteria:

- [ ] Every endpoint delegate in `AccountEndpoints.cs` accepts a `CancellationToken`.
- [ ] Every mediator send call in the file passes that token.
- [ ] No endpoint in the file calls `sender.Send(...)` without the request cancellation token.

### Task 3.2: Add CancellationToken to Category endpoint handlers

Status: - [ ]
Description: Add `CancellationToken ct` parameters to each endpoint delegate in `CategoryEndpoints` and pass the token into `sender.Send(...)`.
File(s): `UMS.API/Endpoints/CategoryEndpoints.cs`
Acceptance Criteria:

- [ ] Every endpoint delegate in `CategoryEndpoints.cs` accepts a `CancellationToken`.
- [ ] Every mediator send call in the file passes that token.
- [ ] No endpoint in the file calls `sender.Send(...)` without the request cancellation token.

### Task 3.3: Add CancellationToken to Role endpoint handlers

Status: - [ ]
Description: Add `CancellationToken ct` parameters to each endpoint delegate in `RoleEndpoints` and pass the token into `sender.Send(...)`.
File(s): `UMS.API/Endpoints/RoleEndpoints.cs`
Acceptance Criteria:

- [ ] Every endpoint delegate in `RoleEndpoints.cs` accepts a `CancellationToken`.
- [ ] Every mediator send call in the file passes that token.
- [ ] No endpoint in the file calls `sender.Send(...)` without the request cancellation token.

### Task 3.4: Add CancellationToken to User endpoint handlers

Status: - [ ]
Description: Add `CancellationToken ct` parameters to each endpoint delegate in `UserEndpoints` and pass the token into `sender.Send(...)`.
File(s): `UMS.API/Endpoints/UserEndpoints.cs`
Acceptance Criteria:

- [ ] Every endpoint delegate in `UserEndpoints.cs` accepts a `CancellationToken`.
- [ ] Every mediator send call in the file passes that token.
- [ ] No endpoint in the file calls `sender.Send(...)` without the request cancellation token.

### Task 3.5: Pass CancellationToken on default file save path

Status: - [ ]
Description: Change the normal-path file copy call from `await file.CopyToAsync(stream)` to the overload that passes the `ct` method parameter so both code paths in `SaveFileAsync` honor cancellation.
File(s): `UMS.Infrastructure/Services/LocalFileStorageService.cs`
Acceptance Criteria:

- [ ] Both file copy calls inside `SaveFileAsync` pass the `ct` parameter.
- [ ] The file contains no `CopyToAsync(stream)` call without a cancellation token in `SaveFileAsync`.
- [ ] `SaveFileAsync` honors cancellation consistently on both path branches.

### Task 3.6: Replace DateTime.Now with UTC/IDateTimeService in TokenService

Status: - [ ]
Description: Replace every `DateTime.Now` usage in `TokenService` with a UTC-based source. Prefer the existing `IDateTimeService` abstraction or explicit UTC time if the service is injected.
File(s): `UMS.Infrastructure/Identity/Services/TokenService.cs`
Acceptance Criteria:

- [ ] `TokenService.cs` contains no `DateTime.Now`.
- [ ] Token expiration and refresh token expiration are based on UTC time.
- [ ] Time acquisition is centralized through the existing abstraction or explicit UTC usage.

### Task 3.7: Replace DateTime.Now with UTC/IDateTimeService in UserService

Status: - [ ]
Description: Replace every `DateTime.Now` usage in `UserService` with UTC-based time so refresh token timestamps and related values are timezone-safe.
File(s): `UMS.Infrastructure/Identity/Services/UserService.cs`
Acceptance Criteria:

- [ ] `UserService.cs` contains no `DateTime.Now`.
- [ ] Refresh token timestamps are generated in UTC.
- [ ] The service uses a consistent time source.

### Task 3.8: Replace DateTime.Now with UTC/IDateTimeService in IdentityDbSeeder

Status: - [ ]
Description: Replace the seeded-user `DateTime.Now` assignments with UTC-based time so seed timestamps are timezone-safe and consistent with the rest of the application.
File(s): `UMS.Infrastructure/Identity/Seeds/IdentityDbSeeder.cs`
Acceptance Criteria:

- [ ] `IdentityDbSeeder.cs` contains no `DateTime.Now`.
- [ ] Seeded date fields use UTC values.
- [ ] The seeder uses a consistent time strategy throughout the file.

### Task 3.9: Replace case-lowering user search with normalization-friendly query

Status: - [ ]
Description: Remove the `ToLower()` based search pattern from `GetUsersPagedQueryAsync` and replace it with a database-friendly query pattern that does not force lowering both columns and search terms inside the query.
File(s): `UMS.Infrastructure/Identity/Services/UserService.cs`
Acceptance Criteria:

- [ ] `GetUsersPagedQueryAsync` contains no `u.FullName.ToLower()` or `u.Email.ToLower()` query predicates.
- [ ] Search logic no longer depends on lowercasing database columns inside the query.
- [ ] The method still supports searching by full name and email.

### Task 3.10: Use async migration inspection in IdentityDbSeeder

Status: - [ ]
Description: Replace the synchronous `_context.Database.GetPendingMigrations().Any()` call with the asynchronous API so the seeder does not block while checking migration state.
File(s): `UMS.Infrastructure/Identity/Seeds/IdentityDbSeeder.cs`
Acceptance Criteria:

- [ ] `IdentityDbSeeder.cs` contains no `GetPendingMigrations()` call.
- [ ] Migration inspection uses the async EF Core API.
- [ ] The seeder still applies pending migrations when needed.

## Phase 4: Testing & Cleanup

### Task 4.1: Add unit tests for validation pipeline mixed-pass mixed-fail scenario

Status: - [ ]
Description: Add an Application test that proves `ValidationPipelineBehavior` fails when one validator succeeds and another validator fails for the same request. This test must specifically guard against regression of the old `Any(vr => vr.IsValid)` bug.
File(s): `UMS.Application.Tests/Behaviors/ValidationPipelineBehaviorTests.cs`
Acceptance Criteria:

- [ ] A test exists that uses multiple validators with mixed outcomes.
- [ ] The test fails against the old logic and passes against the corrected logic.
- [ ] The test asserts that the pipeline returns a failed response containing the validation error message.

### Task 4.2: Add unit test for DeleteRoleCommand validator

Status: - [ ]
Description: Add Application-layer validator tests for the new `DeleteRoleCommandValidator` covering invalid and valid `RoleId` values.
File(s): `UMS.Application.Tests/Validation/Roles/DeleteRoleCommandValidatorTests.cs`
Acceptance Criteria:

- [ ] The test suite includes a failing case for `RoleId <= 0`.
- [ ] The test suite includes a passing case for `RoleId > 0`.
- [ ] The validator is instantiated and executed directly in the tests.

### Task 4.3: Add unit test proving UpdateUserRolesCommand now triggers validation

Status: - [ ]
Description: Add an Application test that verifies an invalid `UpdateUserRolesCommand` is rejected by the validation pipeline after implementing `IValidateMe`.
File(s): `UMS.Application.Tests/Validation/Users/UpdateUserRolesCommandPipelineTests.cs`
Acceptance Criteria:

- [ ] The test executes the validation pipeline for `UpdateUserRolesCommand`.
- [ ] The test confirms invalid payloads do not reach the handler.
- [ ] The test fails if `IValidateMe` is removed from the command.

### Task 4.4: Add unit test proving GetRefreshTokenQuery now triggers validation

Status: - [ ]
Description: Add an Application test that verifies an invalid `GetRefreshTokenQuery` is rejected by the validation pipeline after implementing `IValidateMe`.
File(s): `UMS.Application.Tests/Validation/Token/GetRefreshTokenQueryPipelineTests.cs`
Acceptance Criteria:

- [ ] The test executes the validation pipeline for `GetRefreshTokenQuery`.
- [ ] The test confirms empty token values are rejected before the handler runs.
- [ ] The test fails if `IValidateMe` is removed from the query.

### Task 4.5: Add infrastructure test for MailSenderService SSL configuration

Status: - [ ]
Description: Add an Infrastructure test that verifies the mail sender uses the configured `EnableSsl` value instead of forcing SSL on.
File(s): `UMS.Infrastructure.Tests/Services/MailSenderServiceTests.cs`
Acceptance Criteria:

- [ ] A test covers the configuration path where `EnableSsl` is `false`.
- [ ] A test covers the configuration path where `EnableSsl` is `true`.
- [ ] The tests prove the service behavior is driven by configuration rather than a hardcoded constant.

### Task 4.6: Add infrastructure test for LocalFileStorageService cancellation-aware copy

Status: - [ ]
Description: Add a test that exercises `SaveFileAsync` with cancellation-aware code paths and verifies the method uses the supplied cancellation token in both branches.
File(s): `UMS.Infrastructure.Tests/Services/LocalFileStorageServiceTests.cs`
Acceptance Criteria:

- [ ] The tests cover both `WebRootPath` present and fallback branches.
- [ ] The test code exercises `SaveFileAsync` with a non-default `CancellationToken`.
- [ ] The implementation path under test includes the cancellation-token overload of `CopyToAsync`.

### Task 4.7: Delete placeholder UnitTest1 file from API tests

Status: - [ ]
Description: Remove the empty placeholder test file that provides no behavioral coverage.
File(s): `UMS.API.Tests/UnitTest1.cs`
Acceptance Criteria:

- [ ] `UMS.API.Tests/UnitTest1.cs` is deleted.
- [ ] The API test project still builds and runs after deletion.

### Task 4.8: Delete placeholder UnitTest1 file from Application tests

Status: - [ ]
Description: Remove the empty placeholder test file that provides no behavioral coverage.
File(s): `UMS.Application.Tests/UnitTest1.cs`
Acceptance Criteria:

- [ ] `UMS.Application.Tests/UnitTest1.cs` is deleted.
- [ ] The Application test project still builds and runs after deletion.

### Task 4.9: Delete placeholder UnitTest1 file from Domain tests

Status: - [ ]
Description: Remove the empty placeholder test file that provides no behavioral coverage.
File(s): `UMS.Domain.Tests/UnitTest1.cs`
Acceptance Criteria:

- [ ] `UMS.Domain.Tests/UnitTest1.cs` is deleted.
- [ ] The Domain test project still builds and runs after deletion.

### Task 4.10: Delete placeholder UnitTest1 file from Infrastructure tests

Status: - [ ]
Description: Remove the empty placeholder test file that provides no behavioral coverage.
File(s): `UMS.Infrastructure.Tests/UnitTest1.cs`
Acceptance Criteria:

- [ ] `UMS.Infrastructure.Tests/UnitTest1.cs` is deleted.
- [ ] The Infrastructure test project still builds and runs after deletion.

### Task 4.11: Decide and enforce ownership of legacy UMS.Tests project

Status: - [ ]
Description: Choose one outcome for the legacy `UMS.Tests` project: either migrate all still-relevant tests into the active layer-specific test projects and remove the project, or repair the project and add it to the solution. Do not leave the project outside the solution while it remains failing.
File(s): `UMS.Tests/UMS.Tests.csproj`, `UMSSolution.slnx`
Acceptance Criteria:

- [ ] `UMS.Tests` is either added to `UMSSolution.slnx` or removed from the repository.
- [ ] There is no maintained legacy test project left outside the solution.
- [ ] The chosen path leaves the repository in a consistent state with no orphaned failing test project.

### Task 4.12: Decide and enforce ownership of legacy UMS.IntegrationTests project

Status: - [ ]
Description: Choose one outcome for the legacy `UMS.IntegrationTests` project: either migrate all still-relevant tests into the active API test suite and remove the project, or repair the project and add it to the solution. Do not leave the project outside the solution while it remains failing.
File(s): `UMS.IntegrationTests/UMS.IntegrationTests.csproj`, `UMSSolution.slnx`
Acceptance Criteria:

- [ ] `UMS.IntegrationTests` is either added to `UMSSolution.slnx` or removed from the repository.
- [ ] There is no maintained legacy integration test project left outside the solution.
- [ ] The chosen path leaves the repository in a consistent state with no orphaned failing test project.

### Task 4.13: Update testing strategy documentation to match actual test project structure

Status: - [ ]
Description: Rewrite the testing strategy document so it reflects the final maintained test project structure after legacy suite consolidation. Remove references to test layouts that no longer exist.
File(s): `docs/testing-strategy.md`
Acceptance Criteria:

- [ ] The document lists only the maintained test projects that exist in the repository.
- [ ] The described structure matches the actual solution layout after test consolidation.
- [ ] No deleted or abandoned test project is described as active.

### Task 4.14: Regenerate stale coverage audit documentation

Status: - [ ]
Description: Replace the stale `docs/test_coverage_audit.md` content with a current repository-aligned audit, encoded as clean UTF-8 text without garbled characters. The document must reflect the current maintained test surface only.
File(s): `docs/test_coverage_audit.md`
Acceptance Criteria:

- [ ] The file is UTF-8 clean and contains no garbled characters.
- [ ] The documented coverage state matches the final maintained test project set.
- [ ] The file does not describe removed or abandoned test projects as active coverage sources.

### Task 4.15: Run solution test suite after refactoring completion

Status: - [ ]
Description: Execute the maintained solution test suite after all refactoring tasks are complete and capture the final pass result as the proof that the changes did not break the active test surface.
File(s): `UMSSolution.slnx`
Acceptance Criteria:

- [ ] `dotnet test UMSSolution.slnx` completes successfully.
- [ ] All maintained test projects included in the solution pass.
- [ ] No failing test remains in the maintained solution test surface.
