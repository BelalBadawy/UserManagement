# Tasks: User Account Management Endpoints

**Feature scope:** `ConfirmEmail`, `ConfirmEmailChange`, `ResendConfirmationEmail`,
`GenerateChangeEmailToken`, `GenerateNew2FARecoveryCodes`, `LockUser`, `UnlockUser`

**Execution order:** Complete each phase in sequence. Within a phase, tasks are
ordered by dependency. Do not start Phase E (API) before Phase A and C are done.
Do not start Phase F–H (Tests) before the production code they target is complete.

---

## Phase A — Authorization & Permissions

> **File:** `UMS.Application/Authorization/AppPermissions.cs`

### A.1 — Add new `AppAction` constants

- [x] Open `AppPermissions.cs` and locate the `AppAction` static class.
- [x] Add the following four constants after `Delete`:
  ```csharp
  public const string Lock        = nameof(Lock);
  public const string Unlock      = nameof(Unlock);
  public const string ChangeEmail = nameof(ChangeEmail);
  public const string Manage2FA   = nameof(Manage2FA);
  ```

### A.2 — Register new permission entries

- [x] Locate the `private static readonly AppPermission[] All` array inside `AppPermissions`.
- [x] Append four new entries at the end of the array:
  ```csharp
  new(AppService.Identity, AppFeature.Users, AppAction.Lock,
      "Lock Users"),
  new(AppService.Identity, AppFeature.Users, AppAction.Unlock,
      "Unlock Users"),
  new(AppService.Identity, AppFeature.Users, AppAction.ChangeEmail,
      "Change User Email"),
  new(AppService.Identity, AppFeature.Users, AppAction.Manage2FA,
      "Manage User 2FA"),
  ```
- [x] Verify `AppPermissions.AllPermissions` now contains 20 entries (16 existing + 4 new).

---

## Phase B — Application Layer: `IUserService` Interface

> **File:** `UMS.Application/Features/Users/IUserService.cs`

### B.1 — Add 7 new method signatures

- [x] Add the following signatures to the `IUserService` interface:
  ```csharp
  Task<IResponseWrapper> ConfirmEmailAsync(int userId, string token);
  Task<IResponseWrapper> ConfirmEmailChangeAsync(int userId, string newEmail, string token);
  Task<IResponseWrapper> ResendConfirmationEmailAsync(string email);
  Task<IResponseWrapper> GenerateChangeEmailTokenAsync(string newEmail);
  Task<IResponseWrapper<List<string>>> GenerateNew2FARecoveryCodesAsync();
  Task<IResponseWrapper> LockUserAsync(int userId);
  Task<IResponseWrapper> UnlockUserAsync(int userId);
  ```

---

## Phase C — Application Layer: Commands, Handlers & Validators

Each sub-section below maps to one folder under
`UMS.Application/Features/Users/Commands/`.
Every command follows the established pattern:
- **Request DTO** — plain properties, no logic.
- **Command** — `IRequest<IResponseWrapper[<T>]>`, `IValidateMe` (where applicable),
  wraps the Request DTO as a required property. Handler class is in the same file.
- **Validator** — `AbstractValidator<TCommand>`, rules on the nested request DTO path.

---

### C.1 — `ConfirmEmail`

> **Folder:** `UMS.Application/Features/Users/Commands/ConfirmEmail/`

- [x] **Create `ConfirmEmailRequest.cs`**
  ```csharp
  namespace UMS.Application.Features.Users.Commands
  {
      public class ConfirmEmailRequest
      {
          public int UserId { get; set; }
          public string Token { get; set; } = string.Empty;
      }
  }
  ```

- [x] **Create `ConfirmEmailCommand.cs`** containing both the command and its handler:
  - Command class: `ConfirmEmailCommand : IRequest<IResponseWrapper>, IValidateMe`
    with property `required ConfirmEmailRequest ConfirmEmail { get; set; }`.
  - Handler class: `ConfirmEmailCommandHandler : IRequestHandler<ConfirmEmailCommand, IResponseWrapper>`
    — injects `IUserService`; `Handle` returns:
    ```csharp
    return await _userService.ConfirmEmailAsync(
        request.ConfirmEmail.UserId, request.ConfirmEmail.Token);
    ```

- [x] **Create `ConfirmEmailValidator.cs`**
  - `RuleFor(x => x.ConfirmEmail.UserId).NotEqual(0).WithMessage("User Id is required.")`
  - `RuleFor(x => x.ConfirmEmail.Token).NotEmpty().WithMessage("Token is required.")`

---

### C.2 — `ConfirmEmailChange`

> **Folder:** `UMS.Application/Features/Users/Commands/ConfirmEmailChange/`

- [x] **Create `ConfirmEmailChangeRequest.cs`**
  ```csharp
  public class ConfirmEmailChangeRequest
  {
      public int    UserId   { get; set; }
      public string NewEmail { get; set; } = string.Empty;
      public string Token    { get; set; } = string.Empty;
  }
  ```

- [x] **Create `ConfirmEmailChangeCommand.cs`**
  - Command: `ConfirmEmailChangeCommand : IRequest<IResponseWrapper>, IValidateMe`
    with property `required ConfirmEmailChangeRequest ConfirmEmailChange { get; set; }`.
  - Handler: calls
    ```csharp
    return await _userService.ConfirmEmailChangeAsync(
        request.ConfirmEmailChange.UserId,
        request.ConfirmEmailChange.NewEmail,
        request.ConfirmEmailChange.Token);
    ```

- [x] **Create `ConfirmEmailChangeValidator.cs`**
  - `UserId.NotEqual(0).WithMessage("User Id is required.")`
  - `NewEmail.NotEmpty().WithMessage("New email is required.")`
  - `NewEmail.EmailAddress().WithMessage("A valid email address is required.")`
  - `Token.NotEmpty().WithMessage("Token is required.")`

---

### C.3 — `ResendConfirmationEmail`

> **Folder:** `UMS.Application/Features/Users/Commands/ResendConfirmationEmail/`

- [x] **Create `ResendConfirmationEmailRequest.cs`**
  ```csharp
  public class ResendConfirmationEmailRequest
  {
      public string Email { get; set; } = string.Empty;
  }
  ```

- [x] **Create `ResendConfirmationEmailCommand.cs`**
  - Command: `ResendConfirmationEmailCommand : IRequest<IResponseWrapper>, IValidateMe`
    with property `required ResendConfirmationEmailRequest ResendConfirmation { get; set; }`.
  - Handler: calls
    ```csharp
    return await _userService.ResendConfirmationEmailAsync(
        request.ResendConfirmation.Email);
    ```

- [x] **Create `ResendConfirmationEmailValidator.cs`**
  - `Email.NotEmpty().WithMessage("Email address is required.")`
  - `Email.EmailAddress().WithMessage("A valid email address is required.")`

---

### C.4 — `GenerateChangeEmailToken`

> **Folder:** `UMS.Application/Features/Users/Commands/GenerateChangeEmailToken/`

- [x] **Create `GenerateChangeEmailTokenRequest.cs`**
  ```csharp
  public class GenerateChangeEmailTokenRequest
  {
      public string NewEmail { get; set; } = string.Empty;
  }
  ```

- [x] **Create `GenerateChangeEmailTokenCommand.cs`**
  - Command: `GenerateChangeEmailTokenCommand : IRequest<IResponseWrapper>, IValidateMe`
    with property `required GenerateChangeEmailTokenRequest GenerateChangeEmailToken { get; set; }`.
  - Handler: calls
    ```csharp
    return await _userService.GenerateChangeEmailTokenAsync(
        request.GenerateChangeEmailToken.NewEmail);
    ```

- [x] **Create `GenerateChangeEmailTokenValidator.cs`**
  - `NewEmail.NotEmpty().WithMessage("New email address is required.")`
  - `NewEmail.EmailAddress().WithMessage("A valid email address is required.")`

---

### C.5 — `GenerateNew2FARecoveryCodes`

> **Folder:** `UMS.Application/Features/Users/Commands/GenerateNew2FARecoveryCodes/`
> No Request DTO. No validator. `userId` is resolved inside `UserService` via `ICurrentUserService`.

- [x] **Create `GenerateNew2FARecoveryCodesCommand.cs`**
  - Command: `GenerateNew2FARecoveryCodesCommand : IRequest<IResponseWrapper<List<string>>>`
    — no `IValidateMe`, no properties.
  - Handler: calls
    ```csharp
    return await _userService.GenerateNew2FARecoveryCodesAsync();
    ```

---

### C.6 — `LockUser`

> **Folder:** `UMS.Application/Features/Users/Commands/LockUser/`

- [x] **Create `LockUserRequest.cs`**
  ```csharp
  public class LockUserRequest
  {
      public int UserId { get; set; }
  }
  ```

- [x] **Create `LockUserCommand.cs`**
  - Command: `LockUserCommand : IRequest<IResponseWrapper>, IValidateMe`
    with property `required LockUserRequest LockUser { get; set; }`.
  - Handler: calls
    ```csharp
    return await _userService.LockUserAsync(request.LockUser.UserId);
    ```

- [x] **Create `LockUserValidator.cs`**
  - `UserId.NotEqual(0).WithMessage("User Id is required.")`

---

### C.7 — `UnlockUser`

> **Folder:** `UMS.Application/Features/Users/Commands/UnlockUser/`

- [x] **Create `UnlockUserRequest.cs`**
  ```csharp
  public class UnlockUserRequest
  {
      public int UserId { get; set; }
  }
  ```

- [x] **Create `UnlockUserCommand.cs`**
  - Command: `UnlockUserCommand : IRequest<IResponseWrapper>, IValidateMe`
    with property `required UnlockUserRequest UnlockUser { get; set; }`.
  - Handler: calls
    ```csharp
    return await _userService.UnlockUserAsync(request.UnlockUser.UserId);
    ```

- [x] **Create `UnlockUserValidator.cs`**
  - `UserId.NotEqual(0).WithMessage("User Id is required.")`

---

## Phase D — Infrastructure Layer: `UserService` Implementation

> **File:** `UMS.Infrastructure/Identity/Services/UserService.cs`
> All Identity calls use `_userManager`. URL building uses `_httpContextAccessor`.
> Tokens are URL-encoded with `HttpUtility.UrlEncode`. Errors returned via
> the existing `GetIdentityResultErrorDescriptions(IdentityResult)` helper.

### D.1 — Modify `RegisterUserAsync`

- [x] Locate the success branch where both `identityUserResult.Succeeded`
  **and** `identityRoleResult.Succeeded` are true.
- [x] Wrap the final `return ResponseWrapper.Success(...)` in a conditional:
  ```csharp
  if (!userRegistration.AutoConfirmEmail)
  {
      var request  = _httpContextAccessor.HttpContext!.Request;
      var baseUrl  = $"{request.Scheme}://{request.Host}{request.PathBase}";
      var token    = await _userManager.GenerateEmailConfirmationTokenAsync(newUser);
      var callback = $"{baseUrl}/Account/ConfirmEmail" +
                     $"?userId={newUser.Id}" +
                     $"&token={HttpUtility.UrlEncode(token)}";

      await _emailService.SendAsync(new SendEmailDto
      {
          Subject     = "Confirm Your Email",
          MailTo      = newUser.Email,
          MessageBody = $"<p>Hello: {newUser.FullName}</p>" +
                        "<p>Please confirm your email by clicking the link below.</p>" +
                        $"<p><a href=\"{callback}\">Confirm Email</a></p>"
      });
  }
  return ResponseWrapper.Success("User registered successfully.");
  ```

---

### D.2 — Implement `ConfirmEmailAsync`

- [x] Add the method:
  ```csharp
  public async Task<IResponseWrapper> ConfirmEmailAsync(int userId, string token)
  {
      var user = await _userManager.FindByIdAsync(userId.ToString());
      if (user is null)
          return ResponseWrapper.Fail("User does not exist.");

      if (user.EmailConfirmed)
          return ResponseWrapper.Success("Email is already confirmed.");

      var result = await _userManager.ConfirmEmailAsync(user, token);
      if (!result.Succeeded)
          return ResponseWrapper.Fail(GetIdentityResultErrorDescriptions(result));

      return ResponseWrapper.Success("Email confirmed successfully.");
  }
  ```
  **Key rule:** Already-confirmed users return `Success` silently (idempotent).

---

### D.3 — Implement `ConfirmEmailChangeAsync`

- [x] Add the method:
  ```csharp
  public async Task<IResponseWrapper> ConfirmEmailChangeAsync(
      int userId, string newEmail, string token)
  {
      var user = await _userManager.FindByIdAsync(userId.ToString());
      if (user is null)
          return ResponseWrapper.Fail("User does not exist.");

      var result = await _userManager.ChangeEmailAsync(user, newEmail, token);
      if (!result.Succeeded)
          return ResponseWrapper.Fail(GetIdentityResultErrorDescriptions(result));

      await _userManager.SetUserNameAsync(user, newEmail);
      return ResponseWrapper.Success("Email changed successfully.");
  }
  ```
  **Key rule:** `SetUserNameAsync` is called after `ChangeEmailAsync` to keep
  `UserName` in sync with the new `Email` (this system uses email-as-username).

---

### D.4 — Implement `ResendConfirmationEmailAsync`

- [x] Add the method:
  ```csharp
  public async Task<IResponseWrapper> ResendConfirmationEmailAsync(string email)
  {
      var user = await _userManager.FindByEmailAsync(email);
      if (user is null)
          return ResponseWrapper.Fail("This email doesn't exist.");

      if (user.EmailConfirmed)
          return ResponseWrapper.Fail("Email is already confirmed.");

      var request  = _httpContextAccessor.HttpContext!.Request;
      var baseUrl  = $"{request.Scheme}://{request.Host}{request.PathBase}";
      var token    = await _userManager.GenerateEmailConfirmationTokenAsync(user);
      var callback = $"{baseUrl}/Account/ConfirmEmail" +
                     $"?userId={user.Id}" +
                     $"&token={HttpUtility.UrlEncode(token)}";

      await _emailService.SendAsync(new SendEmailDto
      {
          Subject     = "Confirm Your Email",
          MailTo      = user.Email,
          MessageBody = $"<p>Hello: {user.FullName}</p>" +
                        "<p>Please confirm your email by clicking the link below.</p>" +
                        $"<p><a href=\"{callback}\">Confirm Email</a></p>"
      });

      return ResponseWrapper.Success("Confirmation email sent. Please check your inbox.");
  }
  ```

---

### D.5 — Implement `GenerateChangeEmailTokenAsync`

- [x] Add the method (`userId` is resolved internally from `ICurrentUserService`):
  ```csharp
  public async Task<IResponseWrapper> GenerateChangeEmailTokenAsync(string newEmail)
  {
      var userId = _currentUserService.GetUserId();
      var user   = await _userManager.FindByIdAsync(userId.ToString());
      if (user is null)
          return ResponseWrapper.Fail("User does not exist.");

      if (string.Equals(user.Email, newEmail, StringComparison.OrdinalIgnoreCase))
          return ResponseWrapper.Fail(
              "New email must be different from your current email.");

      var request  = _httpContextAccessor.HttpContext!.Request;
      var baseUrl  = $"{request.Scheme}://{request.Host}{request.PathBase}";
      var token    = await _userManager.GenerateChangeEmailTokenAsync(user, newEmail);
      var callback = $"{baseUrl}/Account/ConfirmEmailChange" +
                     $"?userId={user.Id}" +
                     $"&newEmail={HttpUtility.UrlEncode(newEmail)}" +
                     $"&token={HttpUtility.UrlEncode(token)}";

      await _emailService.SendAsync(new SendEmailDto
      {
          Subject     = "Confirm Your Email Change",
          MailTo      = user.Email,
          MessageBody = $"<p>Hello: {user.FullName}</p>" +
                        "<p>Click the link below to confirm your email change.</p>" +
                        $"<p><a href=\"{callback}\">Confirm Email Change</a></p>"
      });

      return ResponseWrapper.Success(
          "Email change confirmation sent. Please check your inbox.");
  }
  ```
  **Key rule:** The callback URL includes `newEmail` as a query parameter so the
  frontend can supply it when calling the `confirm-email-change` endpoint.

---

### D.6 — Implement `GenerateNew2FARecoveryCodesAsync`

- [x] Add the method (`userId` resolved internally):
  ```csharp
  public async Task<IResponseWrapper<List<string>>> GenerateNew2FARecoveryCodesAsync()
  {
      var userId = _currentUserService.GetUserId();
      var user   = await _userManager.FindByIdAsync(userId.ToString());
      if (user is null)
          return ResponseWrapper<List<string>>.Fail("User does not exist.");

      if (!user.TwoFactorEnabled)
          return ResponseWrapper<List<string>>.Fail(
              "Two-factor authentication is not enabled.");

      var codes = await _userManager
          .GenerateNewTwoFactorRecoveryCodesAsync(user, 10);

      return ResponseWrapper<List<string>>.Success(
          codes!.ToList(), "New recovery codes generated.");
  }
  ```
  **Key rule:** `TwoFactorEnabled` must be `true` before generating codes;
  always generates exactly 10 codes (Identity default).

---

### D.7 — Implement `LockUserAsync`

- [x] Add the method:
  ```csharp
  public async Task<IResponseWrapper> LockUserAsync(int userId)
  {
      var user = await _userManager.FindByIdAsync(userId.ToString());
      if (user is null)
          return ResponseWrapper.Fail("User does not exist.");

      if (string.Equals(user.Email, _seedUsersConfiguration.Admin.Email,
              StringComparison.OrdinalIgnoreCase))
          return ResponseWrapper.Fail("Cannot lock the system administrator.");

      await _userManager.SetLockoutEnabledAsync(user, true);
      await _userManager.SetLockoutEndDateAsync(user, DateTimeOffset.MaxValue);

      user.RefreshTokenExpiryDate = _dateTimeService.NowUtc.AddDays(-1);
      await _userManager.UpdateAsync(user);

      return ResponseWrapper.Success("User locked successfully.");
  }
  ```
  **Key rules:**
  - Lock is indefinite (`DateTimeOffset.MaxValue`); only reversed by `UnlockUserAsync`.
  - Refresh token is invalidated immediately by back-dating `RefreshTokenExpiryDate`.
  - Seeded admin is protected by an explicit guard.
  - Calling on an already-locked user succeeds silently (idempotent).

---

### D.8 — Implement `UnlockUserAsync`

- [x] Add the method:
  ```csharp
  public async Task<IResponseWrapper> UnlockUserAsync(int userId)
  {
      var user = await _userManager.FindByIdAsync(userId.ToString());
      if (user is null)
          return ResponseWrapper.Fail("User does not exist.");

      await _userManager.SetLockoutEndDateAsync(user, DateTimeOffset.UtcNow);
      await _userManager.ResetAccessFailedCountAsync(user);

      return ResponseWrapper.Success("User unlocked successfully.");
  }
  ```
  **Key rules:**
  - Sets `LockoutEnd` to `UtcNow` (not `null`) to release the lock.
  - Resets `AccessFailedCount` to 0 so the user starts fresh.
  - Calling on a user who is not locked succeeds silently (idempotent).

---

## Phase E — API Layer: Endpoint Registration

### E.1 — Add 3 anonymous routes to `AccountEndpoints`

> **File:** `UMS.API/Endpoints/AccountEndpoints.cs`
> Add inside the existing `AllowAnonymous()` group, after the `reset-password` block.

- [x] **`POST account/confirm-email`**
  ```csharp
  group.MapPost("confirm-email",
      async (ConfirmEmailRequest request, ISender sender, CancellationToken ct) =>
      {
          var response = await sender.Send(
              new ConfirmEmailCommand { ConfirmEmail = request }, ct);
          return response.ToApiResult();
      })
      .Produces<IResponseWrapper>(StatusCodes.Status200OK)
      .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest);
  ```

- [x] **`POST account/confirm-email-change`**
  ```csharp
  group.MapPost("confirm-email-change",
      async (ConfirmEmailChangeRequest request, ISender sender, CancellationToken ct) =>
      {
          var response = await sender.Send(
              new ConfirmEmailChangeCommand { ConfirmEmailChange = request }, ct);
          return response.ToApiResult();
      })
      .Produces<IResponseWrapper>(StatusCodes.Status200OK)
      .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest);
  ```

- [x] **`POST account/resend-confirmation-email`**
  ```csharp
  group.MapPost("resend-confirmation-email",
      async (ResendConfirmationEmailRequest request, ISender sender, CancellationToken ct) =>
      {
          var response = await sender.Send(
              new ResendConfirmationEmailCommand { ResendConfirmation = request }, ct);
          return response.ToApiResult();
      })
      .Produces<IResponseWrapper>(StatusCodes.Status200OK)
      .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest);
  ```

- [x] Add `using UMS.Application.Features.Users.Commands;` to the using block
  if not already present (needed for the new request/command types).

---

### E.2 — Add 4 authenticated routes to `UserEndpoints`

> **File:** `UMS.API/Endpoints/UserEndpoints.cs`
> Add inside the existing `RequireAuthorization()` group, after the `roles/{userId:int}` block.
> The group already applies `.RequireAuthorization()` — no extra call needed for the
> two self-service endpoints; only LockUser and UnlockUser add a specific permission.

- [x] **`POST users/generate-change-email-token`**
  *(no specific permission — group-level auth is sufficient)*
  ```csharp
  group.MapPost("generate-change-email-token",
      async (GenerateChangeEmailTokenRequest request, ISender sender, CancellationToken ct) =>
      {
          var response = await sender.Send(
              new GenerateChangeEmailTokenCommand { GenerateChangeEmailToken = request }, ct);
          return response.ToApiResult();
      })
      .Produces<IResponseWrapper>(StatusCodes.Status200OK)
      .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest);
  ```

- [x] **`POST users/generate-2fa-recovery-codes`**
  *(no request body; no specific permission — group-level auth is sufficient)*
  ```csharp
  group.MapPost("generate-2fa-recovery-codes",
      async (ISender sender, CancellationToken ct) =>
      {
          var response = await sender.Send(
              new GenerateNew2FARecoveryCodesCommand(), ct);
          return response.ToApiResult();
      })
      .Produces<IResponseWrapper<List<string>>>(StatusCodes.Status200OK)
      .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest);
  ```

- [x] **`PUT users/lock-user`**
  ```csharp
  group.MapPut("lock-user",
      async (LockUserRequest request, ISender sender, CancellationToken ct) =>
      {
          var response = await sender.Send(
              new LockUserCommand { LockUser = request }, ct);
          return response.ToApiResult();
      })
      .RequireAuthorization(AppPermission.NameFor(
          AppService.Identity, AppFeature.Users, AppAction.Lock))
      .Produces<IResponseWrapper>(StatusCodes.Status200OK)
      .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest);
  ```

- [x] **`PUT users/unlock-user`**
  ```csharp
  group.MapPut("unlock-user",
      async (UnlockUserRequest request, ISender sender, CancellationToken ct) =>
      {
          var response = await sender.Send(
              new UnlockUserCommand { UnlockUser = request }, ct);
          return response.ToApiResult();
      })
      .RequireAuthorization(AppPermission.NameFor(
          AppService.Identity, AppFeature.Users, AppAction.Unlock))
      .Produces<IResponseWrapper>(StatusCodes.Status200OK)
      .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest);
  ```

---

## Phase F — Tests: Application Layer

> **Projects:** `UMS.Application.Tests`
> **Conventions:** xUnit · FluentAssertions · Moq · Arrange/Act/Assert
> **Naming:** `MethodName_Scenario_ExpectedResult`

### F.1 — Handler pass-through tests

> **Folder:** `UMS.Application.Tests/Handlers/Users/`
> Each handler is a pure pass-through to `IUserService`. One test per handler
> is sufficient: mock the service, call the handler, assert result is propagated.

- [x] **`ConfirmEmailCommandHandlerTests.cs`**
  - `Handle_Always_DelegatesToUserServiceAndPropagatesResult`

- [x] **`ConfirmEmailChangeCommandHandlerTests.cs`**
  - `Handle_Always_DelegatesToUserServiceAndPropagatesResult`

- [x] **`ResendConfirmationEmailCommandHandlerTests.cs`**
  - `Handle_Always_DelegatesToUserServiceAndPropagatesResult`

- [x] **`GenerateChangeEmailTokenCommandHandlerTests.cs`**
  - `Handle_Always_DelegatesToUserServiceAndPropagatesResult`

- [x] **`GenerateNew2FARecoveryCodesCommandHandlerTests.cs`**
  - `Handle_Always_DelegatesToUserServiceAndPropagatesResult`

- [x] **`LockUserCommandHandlerTests.cs`**
  - `Handle_Always_DelegatesToUserServiceAndPropagatesResult`

- [x] **`UnlockUserCommandHandlerTests.cs`**
  - `Handle_Always_DelegatesToUserServiceAndPropagatesResult`

---

### F.2 — Validator tests

> **Folder:** `UMS.Application.Tests/Validation/Users/`
> Test valid inputs pass and each broken rule produces the correct message.

- [x] **`ConfirmEmailValidatorTests.cs`**
  - `Validate_should_fail_when_user_id_is_zero`
  - `Validate_should_fail_when_token_is_empty`
  - `Validate_should_pass_for_well_formed_request`

- [x] **`ConfirmEmailChangeValidatorTests.cs`**
  - `Validate_should_fail_when_user_id_is_zero`
  - `Validate_should_fail_when_new_email_is_empty`
  - `Validate_should_fail_when_new_email_is_invalid_format`
  - `Validate_should_fail_when_token_is_empty`
  - `Validate_should_pass_for_well_formed_request`

- [x] **`ResendConfirmationEmailValidatorTests.cs`**
  - `Validate_should_fail_when_email_is_empty`
  - `Validate_should_fail_when_email_is_invalid_format`
  - `Validate_should_pass_for_well_formed_request`

- [x] **`GenerateChangeEmailTokenValidatorTests.cs`**
  - `Validate_should_fail_when_new_email_is_empty`
  - `Validate_should_fail_when_new_email_is_invalid_format`
  - `Validate_should_pass_for_well_formed_request`

- [x] **`LockUserValidatorTests.cs`**
  - `Validate_should_fail_when_user_id_is_zero`
  - `Validate_should_pass_for_well_formed_request`

- [x] **`UnlockUserValidatorTests.cs`**
  - `Validate_should_fail_when_user_id_is_zero`
  - `Validate_should_pass_for_well_formed_request`

- [x] Run `dotnet test UMS.Application.Tests` — **170 passed, 0 failed**.

---

## Phase G — Tests: Infrastructure Layer

> **File:** `UMS.Infrastructure.Tests/Identity/Services/UserServiceTests.cs`
> Extend the existing file. Use `IdentityMockFactory`, fixed `DateTime`,
> `Mock<IEmailService>`, `Mock<ICurrentUserService>`, `Mock<IHttpContextAccessor>`.

### G.1 — `RegisterUserAsync` modification tests

- [x] `RegisterUserAsync_WhenAutoConfirmEmailFalse_SendsConfirmationEmail`
- [x] `RegisterUserAsync_WhenAutoConfirmEmailTrue_DoesNotSendEmail`

---

### G.2 — `ConfirmEmailAsync` tests

- [x] `ConfirmEmailAsync_WhenUserNotFound_ReturnsFail`
- [x] `ConfirmEmailAsync_WhenAlreadyConfirmed_ReturnsSuccessSilently`
- [x] `ConfirmEmailAsync_WhenTokenInvalid_ReturnsFail`
- [x] `ConfirmEmailAsync_WhenSuccessful_ReturnsSuccess`

---

### G.3 — `ConfirmEmailChangeAsync` tests

- [x] `ConfirmEmailChangeAsync_WhenUserNotFound_ReturnsFail`
- [x] `ConfirmEmailChangeAsync_WhenTokenInvalid_ReturnsFail`
- [x] `ConfirmEmailChangeAsync_WhenSuccessful_SyncsUserNameAndReturnsSuccess`

---

### G.4 — `ResendConfirmationEmailAsync` tests

- [x] `ResendConfirmationEmailAsync_WhenUserNotFound_ReturnsFail`
- [x] `ResendConfirmationEmailAsync_WhenAlreadyConfirmed_ReturnsFail`
- [x] `ResendConfirmationEmailAsync_WhenUnconfirmed_SendsEmailAndReturnsSuccess`

---

### G.5 — `GenerateChangeEmailTokenAsync` tests

- [x] `GenerateChangeEmailTokenAsync_WhenUserNotFound_ReturnsFail`
- [x] `GenerateChangeEmailTokenAsync_WhenSameEmail_ReturnsFail`
- [x] `GenerateChangeEmailTokenAsync_WhenSuccessful_SendsEmailAndReturnsSuccess`

---

### G.6 — `GenerateNew2FARecoveryCodesAsync` tests

- [x] `GenerateNew2FARecoveryCodesAsync_WhenUserNotFound_ReturnsFail`
- [x] `GenerateNew2FARecoveryCodesAsync_WhenTwoFactorNotEnabled_ReturnsFail`
- [x] `GenerateNew2FARecoveryCodesAsync_WhenSuccessful_ReturnsTenCodes`

---

### G.7 — `LockUserAsync` tests

- [x] `LockUserAsync_WhenUserNotFound_ReturnsFail`
- [x] `LockUserAsync_WhenSeedAdmin_ReturnsFail`
- [x] `LockUserAsync_WhenSuccessful_InvalidatesRefreshTokenAndReturnsSuccess`

---

### G.8 — `UnlockUserAsync` tests

- [x] `UnlockUserAsync_WhenUserNotFound_ReturnsFail`
- [x] `UnlockUserAsync_WhenSuccessful_ResetsFailedCountAndReturnsSuccess`

- [x] Run `dotnet test UMS.Infrastructure.Tests` — **126 passed, 0 failed**.

---

## Phase H — Tests: API Integration Layer

> **Project:** `UMS.API.Tests`

### H.1 — `AccountEndpoints` tests (anonymous routes)

> **File:** `UMS.API.Tests/Endpoints/AccountEndpointsTests.cs` (extend existing)

- [x] `ConfirmEmail_UnknownUser_ReturnsUnsuccessfulPayload`
- [x] `ConfirmEmail_ValidToken_ConfirmsEmailSuccessfully`

- [x] `ConfirmEmailChange_UnknownUser_ReturnsUnsuccessfulPayload`
- [x] `ConfirmEmailChange_InvalidToken_ReturnsUnsuccessfulPayload`

- [x] `ResendConfirmationEmail_UnknownEmail_ReturnsUnsuccessfulPayload`
- [x] `ResendConfirmationEmail_AlreadyConfirmedEmail_ReturnsUnsuccessfulPayload`
- [x] `ResendConfirmationEmail_UnconfirmedEmail_SendsEmailAndReturnsSuccess`

---

### H.2 — `UserEndpoints` tests (authenticated routes)

> **File:** `UMS.API.Tests/Endpoints/UserEndpointsTests.cs` (extend existing)

- [x] `Generate_change_email_token_returns_unauthorized_when_anonymous`
- [x] `Generate_change_email_token_returns_error_when_authenticated_user_not_in_db`

- [x] `Generate_2fa_recovery_codes_returns_unauthorized_when_anonymous`
- [x] `Generate_2fa_recovery_codes_returns_error_when_authenticated_user_not_in_db`

- [x] `Lock_user_should_follow_authorization_matrix` (Theory: anonymous/401, low-privilege/403, privileged/200)
- [x] `Unlock_user_should_follow_authorization_matrix` (Theory: anonymous/401, low-privilege/403, privileged/200)

- [x] Run `dotnet test UMS.API.Tests` — **77 passed, 0 failed**.

---

## Phase I — Verification & Documentation

### I.1 — Full solution build

- [x] Run `dotnet build UMSSolution.slnx` — **0 errors, 0 warnings**.

### I.2 — Full test suite

- [x] Run `dotnet test UMSSolution.slnx`.
- [x] Confirm **0 failures**.
- [x] New total: **376 tests** (was 304 — +72).

### I.3 — Update `docs/test_coverage_audit.md`

- [x] Updated `## Current verified test counts`: Domain 3, Application 170, Infrastructure 126, API 77, Total 376.
- [x] Updated `## Areas covered now` to include all 7 new service methods and 7 new endpoint routes.
- [x] Updated `Total maintained tests` to 376.

---

## Quick Reference: New Routes Summary

| Method | Route | Auth | Permission |
|--------|-------|------|------------|
| POST | `api/v{v}/account/confirm-email` | Anonymous | — |
| POST | `api/v{v}/account/confirm-email-change` | Anonymous | — |
| POST | `api/v{v}/account/resend-confirmation-email` | Anonymous | — |
| POST | `api/v{v}/users/generate-change-email-token` | Bearer JWT | None (authenticated only) |
| POST | `api/v{v}/users/generate-2fa-recovery-codes` | Bearer JWT | None (authenticated only) |
| PUT  | `api/v{v}/users/lock-user` | Bearer JWT | `Permission.Identity.Users.Lock` |
| PUT  | `api/v{v}/users/unlock-user` | Bearer JWT | `Permission.Identity.Users.Unlock` |

## Quick Reference: New Service Methods

| Method | Guard conditions |
|--------|-----------------|
| `ConfirmEmailAsync` | User not found → Fail; already confirmed → Success (idempotent) |
| `ConfirmEmailChangeAsync` | User not found → Fail; Identity failure → Fail |
| `ResendConfirmationEmailAsync` | User not found → Fail; already confirmed → Fail |
| `GenerateChangeEmailTokenAsync` | User not found → Fail; same email → Fail |
| `GenerateNew2FARecoveryCodesAsync` | User not found → Fail; 2FA disabled → Fail |
| `LockUserAsync` | User not found → Fail; seed admin → Fail; already locked → Success (idempotent) |
| `UnlockUserAsync` | User not found → Fail; already unlocked → Success (idempotent) |
