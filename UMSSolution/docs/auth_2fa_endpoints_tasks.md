# Auth & 2FA Endpoints — Development Tasks

> **Scope:** 7 new endpoints (LoginWith2FA, Logout, Profile, Setup / Confirm / Enable / Disable 2FA) plus a security-critical modification to `GetTokenAsync`.
> **Out of scope:** `GenerateRecoveryCodes` — already implemented as `POST /api/v{v}/users/generate-2fa-recovery-codes`.

---

## Table of Contents

1. [Section 0 — Prerequisites & Notes](#section-0--prerequisites--notes)
2. [Section 1 — Configuration](#section-1--configuration)
3. [Section 2 — Application: Modify Existing Models](#section-2--application-modify-existing-models)
4. [Section 3 — Application: New DTOs](#section-3--application-new-dtos)
5. [Section 4 — Application: New Queries & Commands](#section-4--application-new-queries--commands)
6. [Section 5 — Application: Service Interface Extensions](#section-5--application-service-interface-extensions)
7. [Section 6 — Infrastructure: TokenService](#section-6--infrastructure-tokenservice)
8. [Section 7 — Infrastructure: UserService](#section-7--infrastructure-userservice)
9. [Section 8 — Infrastructure: DI Registration](#section-8--infrastructure-di-registration)
10. [Section 9 — API: AccountEndpoints](#section-9--api-accountendpoints)
11. [Section 10 — API: UserEndpoints](#section-10--api-userendpoints)
12. [Section 11 — Tests: Application Layer](#section-11--tests-application-layer)
13. [Section 12 — Tests: Infrastructure Layer](#section-12--tests-infrastructure-layer)
14. [Section 13 — Tests: API Layer](#section-13--tests-api-layer)

---

## Section 0 — Prerequisites & Notes

### Security Decisions Baked into This Task List

| Decision | Rule |
|---|---|
| Phase 1 / Phase 2 login | `/login` returns a challenge token when 2FA is enabled. Real tokens are issued only after TOTP verification in `/login-2fa`. |
| Challenge token signing | Same `Secret` as access tokens; distinct `Issuer` (`{MainIssuer}:2fa-challenge`) and `Audience` (`2fa-challenge`). |
| Replay prevention | Used `jti` values are stored in `IMemoryCache` with TTL = `TwoFactorChallengeTokenExpiryInMinutes`. |
| `AccessFailedAsync` policy | Called on: wrong password (login, disable-2fa), wrong TOTP (login-2fa, confirm-2fa, enable-2fa). **Not** called for wrong TOTP on disable-2fa. |
| `ResetAccessFailedCountAsync` timing | Called in Phase 2 (after TOTP success), never in Phase 1. |
| Authenticator key on disable | Key is **preserved** — not reset. A future `/reset-authenticator` endpoint is explicitly deferred. |
| `UpdateSecurityStampAsync` on disable | **Skipped** — no-op in this JWT-only API (stamp is not included in JWT claims). |
| Logout token mismatch | Return error and revoke nothing. Expired-but-matching tokens are cleared as cleanup. |
| `IMemoryCache` | Must be explicitly registered — not registered by default. |

---

## Section 1 — Configuration

### 1.1 — Extend JwtConfiguration POCO

- [ ] Open `UMS.Application/Dtos/JWT/JwtConfiguration.cs`.
- [ ] Add the following property:
  ```csharp
  public int TwoFactorChallengeTokenExpiryInMinutes { get; set; }
  ```

### 1.2 — Create TwoFactorOptions POCO

- [ ] Create file `UMS.Application/Dtos/TwoFactor/TwoFactorOptions.cs`.
- [ ] Implement the class:
  ```csharp
  namespace UMS.Application.Dtos.TwoFactor;

  public class TwoFactorOptions
  {
      public string Issuer { get; set; } = string.Empty;
  }
  ```
  > `Issuer` is the user-facing app name displayed inside Google Authenticator / Authy.

### 1.3 — Update appsettings.json

- [ ] Open `UMS.API/appsettings.json`.
- [ ] Inside the `"JwtConfiguration"` object, add:
  ```json
  "TwoFactorChallengeTokenExpiryInMinutes": 5
  ```
- [ ] Add a new root-level section:
  ```json
  "TwoFactor": {
    "Issuer": "YOUR_APP_NAME"
  }
  ```
  > Replace `"YOUR_APP_NAME"` with the real application display name before deploying.

- [ ] If `appsettings.Development.json` exists, mirror the same two additions there.

---

## Section 2 — Application: Modify Existing Models

### 2.1 — Modify TokenResponse

- [ ] Open `UMS.Application/Features/Token/Queries/GetToken/TokenResponse.cs`.
- [ ] Add `using System.Text.Json.Serialization;` at the top.
- [ ] Change `Token` from `string` to `string?`.
- [ ] Change `RefreshToken` from `string` to `string?`.
- [ ] Change `RefreshTokenExpiryTime` from `DateTime` to `DateTime?`.
- [ ] Add the following two new properties:
  ```csharp
  public bool RequiresTwoFactor { get; set; }

  [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
  public string? TwoFactorChallengeToken { get; set; }
  ```
  > Final shape when 2FA is required: `Token=null`, `RefreshToken=null`, `RefreshTokenExpiryTime=null`, `RequiresTwoFactor=true`, `TwoFactorChallengeToken="<jwt>"`.
  > Final shape on normal login: `Token="<jwt>"`, `RefreshToken="<token>"`, `RefreshTokenExpiryTime=<date>`, `RequiresTwoFactor=false`, `TwoFactorChallengeToken` omitted from JSON.

---

## Section 3 — Application: New DTOs

### 3.1 — TwoFactorLoginRequest

- [ ] Create file `UMS.Application/Features/Token/Queries/LoginWith2FA/TwoFactorLoginRequest.cs`.
- [ ] Implement:
  ```csharp
  namespace UMS.Application.Features.Token.Queries.LoginWith2FA;

  public class TwoFactorLoginRequest
  {
      public string TwoFactorChallengeToken { get; set; } = string.Empty;
      public string Code { get; set; } = string.Empty; // Accepts TOTP or recovery code
  }
  ```

### 3.2 — TwoFactorAuthViewModel

- [ ] Create file `UMS.Application/Features/Users/Models/Responses/TwoFactorAuthViewModel.cs`.
- [ ] Implement:
  ```csharp
  using System.Text.Json.Serialization;

  namespace UMS.Application.Features.Users.Models.Responses;

  public class TwoFactorAuthViewModel
  {
      public string? KeySecret { get; set; }
      public string? CodeQR { get; set; }  // raw otpauth:// URI — client renders the QR image

      [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
      public string? VerificationCode { get; set; }  // always null in server response
  }
  ```

### 3.3 — ProfileResponse

- [ ] Create file `UMS.Application/Features/Users/Models/Responses/ProfileResponse.cs`.
- [ ] Implement:
  ```csharp
  namespace UMS.Application.Features.Users.Models.Responses;

  public class ProfileResponse
  {
      public int Id { get; set; }
      public string FullName { get; set; } = string.Empty;
      public string Email { get; set; } = string.Empty;
      public string UserName { get; set; } = string.Empty;
      public bool IsActive { get; set; }
      public bool EmailConfirmed { get; set; }
      public string? PhoneNumber { get; set; }
      public bool TwoFactorEnabled { get; set; }
      public DateTime CreatedDate { get; set; }
      public List<string> Roles { get; set; } = [];
      public List<string> Permissions { get; set; } = []; // flat claim values, deduplicated
  }
  ```

### 3.4 — TwoFactorCodeRequest (Shared)

- [ ] Create file `UMS.Application/Features/Users/Models/Requests/TwoFactorCodeRequest.cs`.
- [ ] Implement:
  ```csharp
  namespace UMS.Application.Features.Users.Models.Requests;

  public class TwoFactorCodeRequest
  {
      public string Code { get; set; } = string.Empty; // 6-digit TOTP only
  }
  ```
  > Used by both `ConfirmTwoFactorAuthCommand` and `EnableTwoFactorAuthCommand`.

### 3.5 — DisableTwoFactorAuthRequest

- [ ] Create file `UMS.Application/Features/Users/Commands/DisableTwoFactorAuth/DisableTwoFactorAuthRequest.cs`.
- [ ] Implement:
  ```csharp
  namespace UMS.Application.Features.Users.Commands.DisableTwoFactorAuth;

  public class DisableTwoFactorAuthRequest
  {
      public string Password { get; set; } = string.Empty;
      public string? Code { get; set; }  // optional TOTP; if provided, must be correct
  }
  ```

### 3.6 — LogoutRequest

- [ ] Create file `UMS.Application/Features/Users/Commands/Logout/LogoutRequest.cs`.
- [ ] Implement:
  ```csharp
  namespace UMS.Application.Features.Users.Commands.Logout;

  public class LogoutRequest
  {
      public string RefreshToken { get; set; } = string.Empty;
  }
  ```

---

## Section 4 — Application: New Queries & Commands

> **Convention:** Every file in this section lives in `UMS.Application`. Handler method signature is `ValueTask<T> Handle(TRequest request, CancellationToken ct)`. All commands/queries that carry input implement `IValidateMe` and have a paired `*Validator.cs` file.

---

### 4.1 — LoginWith2FAQuery + Handler

- [ ] Create file `UMS.Application/Features/Token/Queries/LoginWith2FA/LoginWith2FAQuery.cs`.
- [ ] Implement query and handler:
  ```csharp
  public class LoginWith2FAQuery
      : IRequest<IResponseWrapper<TokenResponse>>, IValidateMe
  {
      public TwoFactorLoginRequest Request { get; set; } = null!;
  }

  public class LoginWith2FAQueryHandler
      : IRequestHandler<LoginWith2FAQuery, IResponseWrapper<TokenResponse>>
  {
      private readonly ITokenService _tokenService;

      public LoginWith2FAQueryHandler(ITokenService tokenService)
          => _tokenService = tokenService;

      public async ValueTask<IResponseWrapper<TokenResponse>> Handle(
          LoginWith2FAQuery request, CancellationToken ct)
          => await _tokenService.LoginWith2FAAsync(request.Request);
  }
  ```

### 4.2 — LoginWith2FAQueryValidator

- [ ] Create file `UMS.Application/Features/Token/Queries/LoginWith2FA/LoginWith2FAQueryValidator.cs`.
- [ ] Implement:
  ```csharp
  public class LoginWith2FAQueryValidator : AbstractValidator<LoginWith2FAQuery>
  {
      public LoginWith2FAQueryValidator()
      {
          RuleFor(x => x.Request.TwoFactorChallengeToken).NotEmpty();
          RuleFor(x => x.Request.Code).NotEmpty();
      }
  }
  ```

### 4.3 — GetMyProfileQuery + Handler

- [ ] Create file `UMS.Application/Features/Users/Queries/GetMyProfile/GetMyProfileQuery.cs`.
- [ ] Implement:
  ```csharp
  public class GetMyProfileQuery : IRequest<IResponseWrapper<ProfileResponse>> { }

  public class GetMyProfileQueryHandler
      : IRequestHandler<GetMyProfileQuery, IResponseWrapper<ProfileResponse>>
  {
      private readonly IUserService _userService;

      public GetMyProfileQueryHandler(IUserService userService)
          => _userService = userService;

      public async ValueTask<IResponseWrapper<ProfileResponse>> Handle(
          GetMyProfileQuery request, CancellationToken ct)
          => await _userService.GetMyProfileAsync();
  }
  ```
  > No input. No validator needed.

### 4.4 — LogoutCommand + Handler

- [ ] Create file `UMS.Application/Features/Users/Commands/Logout/LogoutCommand.cs`.
- [ ] Implement:
  ```csharp
  public class LogoutCommand : IRequest<IResponseWrapper>, IValidateMe
  {
      public LogoutRequest Request { get; set; } = null!;
  }

  public class LogoutCommandHandler : IRequestHandler<LogoutCommand, IResponseWrapper>
  {
      private readonly IUserService _userService;

      public LogoutCommandHandler(IUserService userService)
          => _userService = userService;

      public async ValueTask<IResponseWrapper> Handle(
          LogoutCommand request, CancellationToken ct)
          => await _userService.LogoutAsync(request.Request);
  }
  ```

### 4.5 — LogoutCommandValidator

- [ ] Create file `UMS.Application/Features/Users/Commands/Logout/LogoutCommandValidator.cs`.
- [ ] Implement:
  ```csharp
  public class LogoutCommandValidator : AbstractValidator<LogoutCommand>
  {
      public LogoutCommandValidator()
      {
          RuleFor(x => x.Request.RefreshToken).NotEmpty();
      }
  }
  ```

### 4.6 — SetupTwoFactorAuthCommand + Handler

- [ ] Create file `UMS.Application/Features/Users/Commands/SetupTwoFactorAuth/SetupTwoFactorAuthCommand.cs`.
- [ ] Implement:
  ```csharp
  public class SetupTwoFactorAuthCommand
      : IRequest<IResponseWrapper<TwoFactorAuthViewModel>> { }

  public class SetupTwoFactorAuthCommandHandler
      : IRequestHandler<SetupTwoFactorAuthCommand, IResponseWrapper<TwoFactorAuthViewModel>>
  {
      private readonly IUserService _userService;

      public SetupTwoFactorAuthCommandHandler(IUserService userService)
          => _userService = userService;

      public async ValueTask<IResponseWrapper<TwoFactorAuthViewModel>> Handle(
          SetupTwoFactorAuthCommand request, CancellationToken ct)
          => await _userService.SetupTwoFactorAuthAsync();
  }
  ```
  > No input. No validator needed.

### 4.7 — ConfirmTwoFactorAuthCommand + Handler

- [ ] Create file `UMS.Application/Features/Users/Commands/ConfirmTwoFactorAuth/ConfirmTwoFactorAuthCommand.cs`.
- [ ] Implement:
  ```csharp
  public class ConfirmTwoFactorAuthCommand : IRequest<IResponseWrapper>, IValidateMe
  {
      public TwoFactorCodeRequest Request { get; set; } = null!;
  }

  public class ConfirmTwoFactorAuthCommandHandler
      : IRequestHandler<ConfirmTwoFactorAuthCommand, IResponseWrapper>
  {
      private readonly IUserService _userService;

      public ConfirmTwoFactorAuthCommandHandler(IUserService userService)
          => _userService = userService;

      public async ValueTask<IResponseWrapper> Handle(
          ConfirmTwoFactorAuthCommand request, CancellationToken ct)
          => await _userService.ConfirmTwoFactorAuthAsync(request.Request);
  }
  ```

### 4.8 — ConfirmTwoFactorAuthValidator

- [ ] Create file `UMS.Application/Features/Users/Commands/ConfirmTwoFactorAuth/ConfirmTwoFactorAuthValidator.cs`.
- [ ] Implement:
  ```csharp
  public class ConfirmTwoFactorAuthValidator
      : AbstractValidator<ConfirmTwoFactorAuthCommand>
  {
      public ConfirmTwoFactorAuthValidator()
      {
          RuleFor(x => x.Request.Code)
              .NotEmpty()
              .Matches(@"^\d{6}$")
              .WithMessage("Code must be exactly 6 digits.");
      }
  }
  ```
  > `confirm-2fa` accepts TOTP codes only (6 digits). Recovery codes are explicitly rejected.

### 4.9 — EnableTwoFactorAuthCommand + Handler

- [ ] Create file `UMS.Application/Features/Users/Commands/EnableTwoFactorAuth/EnableTwoFactorAuthCommand.cs`.
- [ ] Implement:
  ```csharp
  public class EnableTwoFactorAuthCommand
      : IRequest<IResponseWrapper<List<string>>>, IValidateMe
  {
      public TwoFactorCodeRequest Request { get; set; } = null!;
  }

  public class EnableTwoFactorAuthCommandHandler
      : IRequestHandler<EnableTwoFactorAuthCommand, IResponseWrapper<List<string>>>
  {
      private readonly IUserService _userService;

      public EnableTwoFactorAuthCommandHandler(IUserService userService)
          => _userService = userService;

      public async ValueTask<IResponseWrapper<List<string>>> Handle(
          EnableTwoFactorAuthCommand request, CancellationToken ct)
          => await _userService.EnableTwoFactorAuthAsync(request.Request);
  }
  ```

### 4.10 — EnableTwoFactorAuthValidator

- [ ] Create file `UMS.Application/Features/Users/Commands/EnableTwoFactorAuth/EnableTwoFactorAuthValidator.cs`.
- [ ] Implement:
  ```csharp
  public class EnableTwoFactorAuthValidator
      : AbstractValidator<EnableTwoFactorAuthCommand>
  {
      public EnableTwoFactorAuthValidator()
      {
          RuleFor(x => x.Request.Code)
              .NotEmpty()
              .Matches(@"^\d{6}$")
              .WithMessage("Code must be exactly 6 digits.");
      }
  }
  ```

### 4.11 — DisableTwoFactorAuthCommand + Handler

- [ ] Create file `UMS.Application/Features/Users/Commands/DisableTwoFactorAuth/DisableTwoFactorAuthCommand.cs`.
- [ ] Implement:
  ```csharp
  public class DisableTwoFactorAuthCommand : IRequest<IResponseWrapper>, IValidateMe
  {
      public DisableTwoFactorAuthRequest Request { get; set; } = null!;
  }

  public class DisableTwoFactorAuthCommandHandler
      : IRequestHandler<DisableTwoFactorAuthCommand, IResponseWrapper>
  {
      private readonly IUserService _userService;

      public DisableTwoFactorAuthCommandHandler(IUserService userService)
          => _userService = userService;

      public async ValueTask<IResponseWrapper> Handle(
          DisableTwoFactorAuthCommand request, CancellationToken ct)
          => await _userService.DisableTwoFactorAuthAsync(request.Request);
  }
  ```

### 4.12 — DisableTwoFactorAuthValidator

- [ ] Create file `UMS.Application/Features/Users/Commands/DisableTwoFactorAuth/DisableTwoFactorAuthValidator.cs`.
- [ ] Implement:
  ```csharp
  public class DisableTwoFactorAuthValidator
      : AbstractValidator<DisableTwoFactorAuthCommand>
  {
      public DisableTwoFactorAuthValidator()
      {
          RuleFor(x => x.Request.Password).NotEmpty();

          When(x => !string.IsNullOrEmpty(x.Request.Code), () =>
          {
              RuleFor(x => x.Request.Code)
                  .Matches(@"^\d{6}$")
                  .WithMessage("Code must be exactly 6 digits.");
          });
      }
  }
  ```
  > `Password` is always required. `Code` is optional; if provided it must be a valid 6-digit TOTP.

---

## Section 5 — Application: Service Interface Extensions

### 5.1 — Extend ITokenService

- [ ] Open `UMS.Application/Features/Token/ITokenService.cs`.
- [ ] Add the following method signature:
  ```csharp
  Task<IResponseWrapper<TokenResponse>> LoginWith2FAAsync(TwoFactorLoginRequest request);
  ```

### 5.2 — Extend IUserService

- [ ] Open `UMS.Application/Features/Users/IUserService.cs`.
- [ ] Add the following six method signatures:
  ```csharp
  Task<IResponseWrapper<ProfileResponse>> GetMyProfileAsync();

  Task<IResponseWrapper> LogoutAsync(LogoutRequest request);

  Task<IResponseWrapper<TwoFactorAuthViewModel>> SetupTwoFactorAuthAsync();

  Task<IResponseWrapper> ConfirmTwoFactorAuthAsync(TwoFactorCodeRequest request);

  Task<IResponseWrapper<List<string>>> EnableTwoFactorAuthAsync(TwoFactorCodeRequest request);

  Task<IResponseWrapper> DisableTwoFactorAuthAsync(DisableTwoFactorAuthRequest request);
  ```

---

## Section 6 — Infrastructure: TokenService

> File: `UMS.Infrastructure/Identity/Services/TokenService.cs`

### 6.1 — Inject IMemoryCache

- [ ] Add `IMemoryCache _cache` as a constructor parameter and field.
- [ ] Add `using Microsoft.Extensions.Caching.Memory;` if not already present.

### 6.2 — Add Private Challenge Token Constants

- [ ] Add the following private members inside `TokenService`:
  ```csharp
  private string ChallengeIssuer   => $"{_tokenSettings.Issuer}:2fa-challenge";
  private const string ChallengeAudience = "2fa-challenge";
  private const string ChallengeClaim    = "2fa_challenge";
  ```

### 6.3 — Modify GetTokenAsync — Insert 2FA Branch

- [ ] Locate the block in `GetTokenAsync` that begins after the lockout check and before `ResetAccessFailedCountAsync`.
- [ ] Insert the following branch **before** the reset + token generation:
  ```csharp
  if (userInDb.TwoFactorEnabled)
  {
      var jti       = Guid.NewGuid().ToString();
      var challenge = GenerateChallengeToken(userInDb, jti);
      return ResponseWrapper<TokenResponse>.Success(
          new TokenResponse
          {
              RequiresTwoFactor       = true,
              TwoFactorChallengeToken = challenge
          },
          "Two-factor authentication required.");
      // ResetAccessFailedCountAsync is intentionally deferred to Phase 2
  }
  ```
  > The existing `ResetAccessFailedCountAsync` call and token-generation block execute only for non-2FA users.

### 6.4 — Add Private GenerateChallengeToken Method

- [ ] Add the following private method to `TokenService`:
  ```csharp
  private string GenerateChallengeToken(ApplicationUser user, string jti)
  {
      var claims = new List<Claim>
      {
          new(ClaimTypes.NameIdentifier, user.Id.ToString()),
          new(ChallengeClaim, "true"),
          new(JwtRegisteredClaimNames.Jti, jti)
      };

      var token = new JwtSecurityToken(
          issuer:             ChallengeIssuer,
          audience:           ChallengeAudience,
          claims:             claims,
          expires:            _dateTimeService.NowUtc.AddMinutes(
                                  _tokenSettings.TwoFactorChallengeTokenExpiryInMinutes),
          signingCredentials: GetSigningCredentials());

      return new JwtSecurityTokenHandler().WriteToken(token);
  }
  ```

### 6.5 — Implement LoginWith2FAAsync

- [ ] Add the public `LoginWith2FAAsync(TwoFactorLoginRequest request)` method.
- [ ] Implement in this exact order:

  **Step A — Validate the challenge token:**
  ```csharp
  var validationParams = new TokenValidationParameters
  {
      ValidateIssuerSigningKey = true,
      ValidateIssuer           = true,
      ValidateAudience         = true,
      ValidateLifetime         = true,
      ValidIssuer              = ChallengeIssuer,
      ValidAudience            = ChallengeAudience,
      IssuerSigningKey         = new SymmetricSecurityKey(
                                     Encoding.UTF8.GetBytes(_tokenSettings.Secret)),
      ClockSkew = TimeSpan.Zero
  };

  ClaimsPrincipal principal;
  try
  {
      principal = new JwtSecurityTokenHandler()
          .ValidateToken(request.TwoFactorChallengeToken, validationParams, out _);
  }
  catch (SecurityTokenException)
  {
      return ResponseWrapper<TokenResponse>.Fail("Invalid or expired challenge token.");
  }
  ```

  **Step B — Verify the 2fa_challenge claim is present:**
  ```csharp
  if (principal.FindFirstValue(ChallengeClaim) is null)
      return ResponseWrapper<TokenResponse>.Fail("Invalid or expired challenge token.");
  ```

  **Step C — Replay check:**
  ```csharp
  var jti = principal.FindFirstValue(JwtRegisteredClaimNames.Jti);
  if (_cache.TryGetValue($"2fa_jti:{jti}", out _))
      return ResponseWrapper<TokenResponse>.Fail("Challenge token has already been used.");
  ```

  **Step D — Load and validate user:**
  ```csharp
  var userId = principal.FindFirstValue(ClaimTypes.NameIdentifier);
  var user   = await _userManager.FindByIdAsync(userId);

  if (user is null || !user.IsActive)
      return ResponseWrapper<TokenResponse>.Fail("Invalid credentials.");
  if (!user.EmailConfirmed)
      return ResponseWrapper<TokenResponse>.Fail("Email not confirmed.");
  if (await _userManager.IsLockedOutAsync(user))
      return ResponseWrapper<TokenResponse>.Fail("Account is locked. Please try again later.");
  if (!user.TwoFactorEnabled)
      return ResponseWrapper<TokenResponse>.Fail("Two-factor authentication is not enabled.");
  ```

  **Step E — Verify the code (TOTP first, then recovery code):**
  ```csharp
  bool success = await _userManager.VerifyTwoFactorTokenAsync(
      user,
      _userManager.Options.Tokens.AuthenticatorTokenProvider,
      request.Code);

  if (!success)
  {
      var recoveryResult = await _userManager.RedeemTwoFactorRecoveryCodeAsync(
          user, request.Code);
      success = recoveryResult.Succeeded;
  }
  ```

  **Step F — Handle failure:**
  ```csharp
  if (!success)
  {
      await _userManager.AccessFailedAsync(user);
      if (await _userManager.IsLockedOutAsync(user))
          return ResponseWrapper<TokenResponse>.Fail(
              "Account locked due to multiple failed attempts.");
      return ResponseWrapper<TokenResponse>.Fail("Invalid authenticator code.");
  }
  ```

  **Step G — Handle success (Phase 2 complete):**
  ```csharp
  await _userManager.ResetAccessFailedCountAsync(user);

  _cache.Set(
      $"2fa_jti:{jti}",
      true,
      new MemoryCacheEntryOptions
      {
          AbsoluteExpirationRelativeToNow =
              TimeSpan.FromMinutes(_tokenSettings.TwoFactorChallengeTokenExpiryInMinutes)
      });

  user.RefreshToken           = GenerateRefreshToken();
  user.RefreshTokenExpiryDate = _dateTimeService.NowUtc
                                    .AddDays(_tokenSettings.RefreshTokenExpiryInDays);
  await _userManager.UpdateAsync(user);

  var token = await GenerateJwtAsync(user);

  return ResponseWrapper<TokenResponse>.Success(new TokenResponse
  {
      Token                  = token,
      RefreshToken           = user.RefreshToken,
      RefreshTokenExpiryTime = user.RefreshTokenExpiryDate
  });
  ```

---

## Section 7 — Infrastructure: UserService

> File: `UMS.Infrastructure/Identity/Services/UserService.cs`

### 7.1 — Inject TwoFactorOptions

- [ ] Add `IOptions<TwoFactorOptions> twoFactorOptions` to the constructor signature.
- [ ] Store as `private readonly TwoFactorOptions _twoFactorOptions = twoFactorOptions.Value;`.
- [ ] Add `using Microsoft.Extensions.Options;` and `using UMS.Application.Dtos.TwoFactor;` if not present.

### 7.2 — Implement GetMyProfileAsync

- [ ] Add the method:
  ```csharp
  public async Task<IResponseWrapper<ProfileResponse>> GetMyProfileAsync()
  {
      var userId = _currentUserService.GetUserId();
      var user   = await _userManager.FindByIdAsync(userId?.ToString());
      if (user is null)
          return ResponseWrapper<ProfileResponse>.Fail("User not found.");

      var roles = (await _userManager.GetRolesAsync(user)).ToList();

      var permissionsSet = new HashSet<string>();
      foreach (var roleName in roles)
      {
          var role   = await _roleManager.FindByNameAsync(roleName);
          var claims = await _roleManager.GetClaimsAsync(role);
          foreach (var claim in claims)
              permissionsSet.Add(claim.Value);
      }

      return ResponseWrapper<ProfileResponse>.Success(new ProfileResponse
      {
          Id               = user.Id,
          FullName         = user.FullName,
          Email            = user.Email,
          UserName         = user.UserName,
          IsActive         = user.IsActive,
          EmailConfirmed   = user.EmailConfirmed,
          PhoneNumber      = user.PhoneNumber,
          TwoFactorEnabled = user.TwoFactorEnabled,
          CreatedDate      = user.CreatedDate,
          Roles            = roles,
          Permissions      = [.. permissionsSet]
      });
  }
  ```

### 7.3 — Implement LogoutAsync

- [ ] Add the method:
  ```csharp
  public async Task<IResponseWrapper> LogoutAsync(LogoutRequest request)
  {
      var userId = _currentUserService.GetUserId();
      var user   = await _userManager.FindByIdAsync(userId?.ToString());
      if (user is null)
          return ResponseWrapper.Fail("User not found.");

      if (string.IsNullOrEmpty(request.RefreshToken))
          return ResponseWrapper.Fail("Refresh token is required.");

      if (user.RefreshToken != request.RefreshToken)
          return ResponseWrapper.Fail("Invalid refresh token.");

      // Expired-but-matching tokens are cleared as cleanup.
      user.RefreshToken           = string.Empty;
      user.RefreshTokenExpiryDate = _dateTimeService.NowUtc.AddDays(-1);
      await _userManager.UpdateAsync(user);

      return ResponseWrapper.Success("Logged out successfully.");
  }
  ```

### 7.4 — Implement SetupTwoFactorAuthAsync

- [ ] Add the method:
  ```csharp
  public async Task<IResponseWrapper<TwoFactorAuthViewModel>> SetupTwoFactorAuthAsync()
  {
      var userId = _currentUserService.GetUserId();
      var user   = await _userManager.FindByIdAsync(userId?.ToString());
      if (user is null)
          return ResponseWrapper<TwoFactorAuthViewModel>.Fail("User not found.");

      if (user.TwoFactorEnabled)
          return ResponseWrapper<TwoFactorAuthViewModel>.Fail(
              "Two-factor authentication is already enabled. Disable it first to reconfigure.");

      var key = await _userManager.GetAuthenticatorKeyAsync(user);
      if (string.IsNullOrEmpty(key))
      {
          await _userManager.ResetAuthenticatorKeyAsync(user);
          key = await _userManager.GetAuthenticatorKeyAsync(user);
      }

      var issuer = Uri.EscapeDataString(_twoFactorOptions.Issuer);
      var email  = Uri.EscapeDataString(user.Email);
      var codeQR = $"otpauth://totp/{issuer}:{email}?secret={key}&issuer={issuer}";

      return ResponseWrapper<TwoFactorAuthViewModel>.Success(
          new TwoFactorAuthViewModel { KeySecret = key, CodeQR = codeQR });
  }
  ```
  > If the user calls `setup-2fa` again before enabling, the existing key is returned (not reset).

### 7.5 — Implement ConfirmTwoFactorAuthAsync

- [ ] Add the method:
  ```csharp
  public async Task<IResponseWrapper> ConfirmTwoFactorAuthAsync(TwoFactorCodeRequest request)
  {
      var userId = _currentUserService.GetUserId();
      var user   = await _userManager.FindByIdAsync(userId?.ToString());
      if (user is null)
          return ResponseWrapper.Fail("User not found.");

      var key = await _userManager.GetAuthenticatorKeyAsync(user);
      if (string.IsNullOrEmpty(key))
          return ResponseWrapper.Fail(
              "No authenticator configured. Please call setup-2fa first.");

      var valid = await _userManager.VerifyTwoFactorTokenAsync(
          user,
          _userManager.Options.Tokens.AuthenticatorTokenProvider,
          request.Code);

      if (!valid)
      {
          await _userManager.AccessFailedAsync(user);
          return ResponseWrapper.Fail("Invalid verification code.");
      }

      await _userManager.ResetAccessFailedCountAsync(user);
      return ResponseWrapper.Success("Verification code is valid.");
  }
  ```
  > Works for both pending setup (`TwoFactorEnabled=false`) and active users testing their authenticator (`TwoFactorEnabled=true`).
  > Accepts TOTP only — the validator enforces 6 digits before this method is reached.

### 7.6 — Implement EnableTwoFactorAuthAsync

- [ ] Add the method:
  ```csharp
  public async Task<IResponseWrapper<List<string>>> EnableTwoFactorAuthAsync(
      TwoFactorCodeRequest request)
  {
      var userId = _currentUserService.GetUserId();
      var user   = await _userManager.FindByIdAsync(userId?.ToString());
      if (user is null)
          return ResponseWrapper<List<string>>.Fail("User not found.");

      if (user.TwoFactorEnabled)
          return ResponseWrapper<List<string>>.Fail(
              "Two-factor authentication is already enabled.");

      var key = await _userManager.GetAuthenticatorKeyAsync(user);
      if (string.IsNullOrEmpty(key))
          return ResponseWrapper<List<string>>.Fail(
              "No authenticator configured. Please call setup-2fa first.");

      var valid = await _userManager.VerifyTwoFactorTokenAsync(
          user,
          _userManager.Options.Tokens.AuthenticatorTokenProvider,
          request.Code);

      if (!valid)
      {
          await _userManager.AccessFailedAsync(user);
          if (await _userManager.IsLockedOutAsync(user))
              return ResponseWrapper<List<string>>.Fail(
                  "Account locked due to multiple failed attempts.");
          return ResponseWrapper<List<string>>.Fail("Invalid authenticator code.");
      }

      await _userManager.ResetAccessFailedCountAsync(user);
      await _userManager.SetTwoFactorEnabledAsync(user, true);

      var codes = await _userManager.GenerateNewTwoFactorRecoveryCodesAsync(user, 10);

      return ResponseWrapper<List<string>>.Success(
          codes!.ToList(),
          "Two-factor authentication enabled. Store your recovery codes safely.");
  }
  ```

### 7.7 — Implement DisableTwoFactorAuthAsync

- [ ] Add the method:
  ```csharp
  public async Task<IResponseWrapper> DisableTwoFactorAuthAsync(
      DisableTwoFactorAuthRequest request)
  {
      var userId = _currentUserService.GetUserId();
      var user   = await _userManager.FindByIdAsync(userId?.ToString());
      if (user is null)
          return ResponseWrapper.Fail("User not found.");

      if (!user.TwoFactorEnabled)
          return ResponseWrapper.Fail("Two-factor authentication is not enabled.");

      // Always verify password
      var passwordValid = await _userManager.CheckPasswordAsync(user, request.Password);
      if (!passwordValid)
      {
          await _userManager.AccessFailedAsync(user); // Lockout protection on password brute-force
          if (await _userManager.IsLockedOutAsync(user))
              return ResponseWrapper.Fail("Account locked due to multiple failed attempts.");
          return ResponseWrapper.Fail("Invalid password.");
      }

      // Verify TOTP only if provided
      if (!string.IsNullOrEmpty(request.Code))
      {
          var codeValid = await _userManager.VerifyTwoFactorTokenAsync(
              user,
              _userManager.Options.Tokens.AuthenticatorTokenProvider,
              request.Code);

          if (!codeValid)
              // Wrong TOTP: block the request but do NOT increment AccessFailedAsync
              return ResponseWrapper.Fail("Invalid authenticator code.");
      }

      await _userManager.ResetAccessFailedCountAsync(user);
      await _userManager.SetTwoFactorEnabledAsync(user, false);
      // Authenticator key is intentionally preserved (re-enable works without new QR scan)
      // UpdateSecurityStampAsync is intentionally skipped (no-op in this JWT-only API)

      return ResponseWrapper.Success("Two-factor authentication disabled.");
  }
  ```

---

## Section 8 — Infrastructure: DI Registration

> File: `UMS.API/Program.cs` or the service-registration extension file.

### 8.1 — Register IMemoryCache

- [ ] Add the following line to the service registration block:
  ```csharp
  builder.Services.AddMemoryCache();
  ```
  > `IMemoryCache` is **not** registered by default — this call is mandatory.

### 8.2 — Register TwoFactorOptions

- [ ] Add the following line:
  ```csharp
  builder.Services.Configure<TwoFactorOptions>(
      builder.Configuration.GetSection("TwoFactor"));
  ```
  > Requires `using UMS.Application.Dtos.TwoFactor;`.

---

## Section 9 — API: AccountEndpoints

> File: `UMS.API/Endpoints/AccountEndpoints.cs`

### 9.1 — Add login-2fa to the Existing Anonymous Group

- [ ] Inside `MapAccountEndpoints`, append the following endpoint to the existing `group` (the anonymous group):
  ```csharp
  group.MapPost("login-2fa",
      async (TwoFactorLoginRequest request, ISender sender, CancellationToken ct) =>
      {
          var response = await sender.Send(
              new LoginWith2FAQuery { Request = request }, ct);
          return response.ToApiResult();
      })
  .Produces<IResponseWrapper<TokenResponse>>(StatusCodes.Status200OK)
  .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest)
  .Produces<IResponseWrapper>(StatusCodes.Status401Unauthorized);
  ```

### 9.2 — Add Authenticated Group for logout + profile

- [ ] Create a **second** `MapGroup` call with the **same route prefix** but `RequireAuthorization()`:
  ```csharp
  var authGroup = app
      .MapGroup("api/v{version:apiVersion}/account")
      .WithTags("Account")
      .RequireAuthorization();
  ```
  > A separate group object is required because the existing group has `AllowAnonymous()` applied at group level, which would suppress any `RequireAuthorization()` added to individual endpoints within that same group.

### 9.3 — Add logout Endpoint

- [ ] Append to `authGroup`:
  ```csharp
  authGroup.MapPost("logout",
      async (LogoutRequest request, ISender sender, CancellationToken ct) =>
      {
          var response = await sender.Send(
              new LogoutCommand { Request = request }, ct);
          return response.ToApiResult();
      })
  .Produces<IResponseWrapper>(StatusCodes.Status200OK)
  .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest)
  .Produces<IResponseWrapper>(StatusCodes.Status401Unauthorized);
  ```

### 9.4 — Add profile Endpoint

- [ ] Append to `authGroup`:
  ```csharp
  authGroup.MapGet("profile",
      async (ISender sender, CancellationToken ct) =>
      {
          var response = await sender.Send(new GetMyProfileQuery(), ct);
          return response.IsSuccessful
              ? Results.Ok(response)
              : Results.NotFound(response);
      })
  .Produces<IResponseWrapper<ProfileResponse>>(StatusCodes.Status200OK)
  .Produces<IResponseWrapper>(StatusCodes.Status401Unauthorized);
  ```

### 9.5 — Verify return statement

- [ ] Ensure `return app;` is the last statement in `MapAccountEndpoints` and is after both group definitions.

---

## Section 10 — API: UserEndpoints

> File: `UMS.API/Endpoints/UserEndpoints.cs`
> All four endpoints are appended to the **existing** `group` (which already calls `.RequireAuthorization()`).
> No per-endpoint permission is added — all are self-service.

### 10.1 — Add setup-2fa Endpoint

- [ ] Append to the existing `group`:
  ```csharp
  group.MapPost("setup-2fa",
      async (ISender sender, CancellationToken ct) =>
      {
          var response = await sender.Send(new SetupTwoFactorAuthCommand(), ct);
          return response.ToApiResult();
      })
  .Produces<IResponseWrapper<TwoFactorAuthViewModel>>(StatusCodes.Status200OK)
  .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest);
  ```

### 10.2 — Add confirm-2fa Endpoint

- [ ] Append to the existing `group`:
  ```csharp
  group.MapPost("confirm-2fa",
      async (TwoFactorCodeRequest request, ISender sender, CancellationToken ct) =>
      {
          var response = await sender.Send(
              new ConfirmTwoFactorAuthCommand { Request = request }, ct);
          return response.ToApiResult();
      })
  .Produces<IResponseWrapper>(StatusCodes.Status200OK)
  .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest);
  ```

### 10.3 — Add enable-2fa Endpoint

- [ ] Append to the existing `group`:
  ```csharp
  group.MapPut("enable-2fa",
      async (TwoFactorCodeRequest request, ISender sender, CancellationToken ct) =>
      {
          var response = await sender.Send(
              new EnableTwoFactorAuthCommand { Request = request }, ct);
          return response.ToApiResult();
      })
  .Produces<IResponseWrapper<List<string>>>(StatusCodes.Status200OK)
  .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest);
  ```

### 10.4 — Add disable-2fa Endpoint

- [ ] Append to the existing `group`:
  ```csharp
  group.MapPut("disable-2fa",
      async (DisableTwoFactorAuthRequest request, ISender sender, CancellationToken ct) =>
      {
          var response = await sender.Send(
              new DisableTwoFactorAuthCommand { Request = request }, ct);
          return response.ToApiResult();
      })
  .Produces<IResponseWrapper>(StatusCodes.Status200OK)
  .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest);
  ```

---

## Section 11 — Tests: Application Layer

> Project: `UMS.Application.Tests`
> Convention: xUnit + FluentAssertions + Moq. Arrange / Act / Assert. `MethodName_Scenario_ExpectedResult`.
> All handlers in this feature are pass-through (delegate to service). Test dependency invocation and result passthrough.

### 11.1 — LoginWith2FAQueryHandler Tests

- [ ] Create `Features/Token/Queries/LoginWith2FAQueryHandlerTests.cs`.
- [ ] Implement:
  - [ ] `Handle_WhenCalled_CallsTokenServiceLoginWith2FAWithCorrectRequest`
  - [ ] `Handle_WhenCalled_PassesThroughServiceResult`

### 11.2 — GetMyProfileQueryHandler Tests

- [ ] Create `Features/Users/Queries/GetMyProfileQueryHandlerTests.cs`.
- [ ] Implement:
  - [ ] `Handle_WhenCalled_CallsUserServiceGetMyProfile`
  - [ ] `Handle_WhenCalled_PassesThroughProfileResult`

### 11.3 — LogoutCommandHandler Tests

- [ ] Create `Features/Users/Commands/LogoutCommandHandlerTests.cs`.
- [ ] Implement:
  - [ ] `Handle_WhenCalled_CallsUserServiceLogoutWithCorrectRequest`
  - [ ] `Handle_WhenCalled_PassesThroughServiceResult`

### 11.4 — SetupTwoFactorAuthCommandHandler Tests

- [ ] Create `Features/Users/Commands/SetupTwoFactorAuthCommandHandlerTests.cs`.
- [ ] Implement:
  - [ ] `Handle_WhenCalled_CallsUserServiceSetupTwoFactorAuth`
  - [ ] `Handle_WhenCalled_PassesThroughViewModelResult`

### 11.5 — ConfirmTwoFactorAuthCommandHandler Tests

- [ ] Create `Features/Users/Commands/ConfirmTwoFactorAuthCommandHandlerTests.cs`.
- [ ] Implement:
  - [ ] `Handle_WhenCalled_CallsUserServiceConfirmWithCorrectRequest`
  - [ ] `Handle_WhenCalled_PassesThroughServiceResult`

### 11.6 — EnableTwoFactorAuthCommandHandler Tests

- [ ] Create `Features/Users/Commands/EnableTwoFactorAuthCommandHandlerTests.cs`.
- [ ] Implement:
  - [ ] `Handle_WhenCalled_CallsUserServiceEnableWithCorrectRequest`
  - [ ] `Handle_WhenCalled_PassesThroughRecoveryCodesList`

### 11.7 — DisableTwoFactorAuthCommandHandler Tests

- [ ] Create `Features/Users/Commands/DisableTwoFactorAuthCommandHandlerTests.cs`.
- [ ] Implement:
  - [ ] `Handle_WhenCalled_CallsUserServiceDisableWithCorrectRequest`
  - [ ] `Handle_WhenCalled_PassesThroughServiceResult`

### 11.8 — LoginWith2FAQueryValidator Tests

- [ ] Create `Features/Token/Queries/LoginWith2FAQueryValidatorTests.cs`.
- [ ] Implement:
  - [ ] `Validate_EmptyChallengeToken_ReturnsValidationFailure`
  - [ ] `Validate_EmptyCode_ReturnsValidationFailure`
  - [ ] `Validate_BothFieldsPopulated_PassesValidation`

### 11.9 — LogoutCommandValidator Tests

- [ ] Create `Features/Users/Commands/LogoutCommandValidatorTests.cs`.
- [ ] Implement:
  - [ ] `Validate_EmptyRefreshToken_ReturnsValidationFailure`
  - [ ] `Validate_NonEmptyRefreshToken_PassesValidation`

### 11.10 — ConfirmTwoFactorAuthValidator Tests

- [ ] Create `Features/Users/Commands/ConfirmTwoFactorAuthValidatorTests.cs`.
- [ ] Implement:
  - [ ] `Validate_EmptyCode_ReturnsValidationFailure`
  - [ ] `Validate_NonNumericCode_ReturnsValidationFailure`
  - [ ] `Validate_CodeShorterThanSixDigits_ReturnsValidationFailure`
  - [ ] `Validate_SixDigitNumericCode_PassesValidation`

### 11.11 — EnableTwoFactorAuthValidator Tests

- [ ] Create `Features/Users/Commands/EnableTwoFactorAuthValidatorTests.cs`.
- [ ] Implement (same four cases as 11.10):
  - [ ] `Validate_EmptyCode_ReturnsValidationFailure`
  - [ ] `Validate_NonNumericCode_ReturnsValidationFailure`
  - [ ] `Validate_CodeShorterThanSixDigits_ReturnsValidationFailure`
  - [ ] `Validate_SixDigitNumericCode_PassesValidation`

### 11.12 — DisableTwoFactorAuthValidator Tests

- [ ] Create `Features/Users/Commands/DisableTwoFactorAuthValidatorTests.cs`.
- [ ] Implement:
  - [ ] `Validate_EmptyPassword_ReturnsValidationFailure`
  - [ ] `Validate_PasswordPresentAndCodeNull_PassesValidation`
  - [ ] `Validate_PasswordPresentAndSixDigitCode_PassesValidation`
  - [ ] `Validate_PasswordPresentAndNonNumericCode_ReturnsValidationFailure`

---

## Section 12 — Tests: Infrastructure Layer

> Project: `UMS.Infrastructure.Tests`
> Convention: xUnit + FluentAssertions + Moq. Strict branch coverage. Decode JWT claims where relevant.

### 12.1 — TokenService: GetTokenAsync Modification Tests

- [ ] In `Identity/Services/TokenServiceTests.cs` (create or extend):
  - [ ] `GetTokenAsync_UserNotFound_ReturnsFail`
  - [ ] `GetTokenAsync_WrongPassword_ReturnsFailAndCallsAccessFailed`
  - [ ] `GetTokenAsync_InactiveUser_ReturnsFail`
  - [ ] `GetTokenAsync_EmailNotConfirmed_ReturnsFail`
  - [ ] `GetTokenAsync_LockedOutUser_ReturnsFail`
  - [ ] `GetTokenAsync_TwoFactorEnabled_ReturnsRequiresTwoFactorTrue`
  - [ ] `GetTokenAsync_TwoFactorEnabled_ReturnsChallengeTokenWithCorrectIssuerAndAudience`
  - [ ] `GetTokenAsync_TwoFactorEnabled_ChallengeTokenExpiresAfterConfiguredMinutes`
  - [ ] `GetTokenAsync_TwoFactorEnabled_DoesNotCallResetAccessFailedCount`
  - [ ] `GetTokenAsync_TwoFactorDisabled_ReturnsRealTokensWithRequiresTwoFactorFalse`

### 12.2 — TokenService: LoginWith2FAAsync Tests

- [ ] In `Identity/Services/TokenServiceTests.cs`:
  - [ ] `LoginWith2FAAsync_InvalidChallengeTokenSignature_ReturnsFail`
  - [ ] `LoginWith2FAAsync_ExpiredChallengeToken_ReturnsFail`
  - [ ] `LoginWith2FAAsync_MissingChallengeClaim_ReturnsFail`
  - [ ] `LoginWith2FAAsync_JtiAlreadyInCache_ReturnsFail`
  - [ ] `LoginWith2FAAsync_UserLockedOut_ReturnsFail`
  - [ ] `LoginWith2FAAsync_TwoFactorNotEnabledOnAccount_ReturnsFail`
  - [ ] `LoginWith2FAAsync_BothTOTPAndRecoveryCodeFail_ReturnsFailAndCallsAccessFailed`
  - [ ] `LoginWith2FAAsync_WrongCodeExceedsThreshold_ReturnsLockedOutMessage`
  - [ ] `LoginWith2FAAsync_ValidTOTPCode_ReturnsRealTokens`
  - [ ] `LoginWith2FAAsync_ValidTOTPCode_StoresJtiInCacheWithCorrectTTL`
  - [ ] `LoginWith2FAAsync_ValidTOTPCode_CallsResetAccessFailedCount`
  - [ ] `LoginWith2FAAsync_ValidRecoveryCode_ReturnsRealTokens`

### 12.3 — UserService: LogoutAsync Tests

- [ ] In `Identity/Services/UserServiceAuthTests.cs` (create or extend):
  - [ ] `LogoutAsync_EmptyRefreshToken_ReturnsFail`
  - [ ] `LogoutAsync_RefreshTokenDoesNotMatchStored_ReturnsFail`
  - [ ] `LogoutAsync_ExpiredButMatchingToken_ClearsTokenAndReturnsSuccess`
  - [ ] `LogoutAsync_ValidToken_ClearsRefreshTokenAndSetsExpiryToThePast`

### 12.4 — UserService: GetMyProfileAsync Tests

- [ ] In `Identity/Services/UserServiceAuthTests.cs`:
  - [ ] `GetMyProfileAsync_ReturnsProfileWithCorrectUserFields`
  - [ ] `GetMyProfileAsync_ReturnsDeduplicatedPermissionsFromAllRoles`
  - [ ] `GetMyProfileAsync_ReturnsFlatPermissionClaimValues`

### 12.5 — UserService: SetupTwoFactorAuthAsync Tests

- [ ] In `Identity/Services/UserServiceAuthTests.cs`:
  - [ ] `SetupTwoFactorAuthAsync_TwoFactorAlreadyEnabled_ReturnsFail`
  - [ ] `SetupTwoFactorAuthAsync_ExistingKeyPresent_ReturnsExistingKeyWithoutCallingReset`
  - [ ] `SetupTwoFactorAuthAsync_NoKeyPresent_GeneratesAndReturnsNewKey`
  - [ ] `SetupTwoFactorAuthAsync_ReturnedCodeQRIsValidOtpauthUri`
  - [ ] `SetupTwoFactorAuthAsync_OtpauthUriContainsEncodedIssuerAndEmail`

### 12.6 — UserService: ConfirmTwoFactorAuthAsync Tests

- [ ] In `Identity/Services/UserServiceAuthTests.cs`:
  - [ ] `ConfirmTwoFactorAuthAsync_NoAuthenticatorKeyExists_ReturnsFail`
  - [ ] `ConfirmTwoFactorAuthAsync_WrongCode_ReturnsFailAndCallsAccessFailed`
  - [ ] `ConfirmTwoFactorAuthAsync_ValidCode_ReturnsSuccessAndCallsResetAccessFailed`
  - [ ] `ConfirmTwoFactorAuthAsync_WorksWhenTwoFactorIsAlreadyEnabled`

### 12.7 — UserService: EnableTwoFactorAuthAsync Tests

- [ ] In `Identity/Services/UserServiceAuthTests.cs`:
  - [ ] `EnableTwoFactorAuthAsync_AlreadyEnabled_ReturnsFail`
  - [ ] `EnableTwoFactorAuthAsync_NoAuthenticatorKey_ReturnsFail`
  - [ ] `EnableTwoFactorAuthAsync_WrongCode_ReturnsFailAndCallsAccessFailed`
  - [ ] `EnableTwoFactorAuthAsync_WrongCodeExceedsThreshold_ReturnsLockedOutMessage`
  - [ ] `EnableTwoFactorAuthAsync_ValidCode_SetsTwoFactorEnabledTrue`
  - [ ] `EnableTwoFactorAuthAsync_ValidCode_ReturnsTenRecoveryCodes`

### 12.8 — UserService: DisableTwoFactorAuthAsync Tests

- [ ] In `Identity/Services/UserServiceAuthTests.cs`:
  - [ ] `DisableTwoFactorAuthAsync_TwoFactorNotEnabled_ReturnsFail`
  - [ ] `DisableTwoFactorAuthAsync_WrongPassword_ReturnsFailAndCallsAccessFailed`
  - [ ] `DisableTwoFactorAuthAsync_WrongPasswordExceedsThreshold_ReturnsLockedOutMessage`
  - [ ] `DisableTwoFactorAuthAsync_WrongTOTPCode_ReturnsFailWithoutCallingAccessFailed`
  - [ ] `DisableTwoFactorAuthAsync_ValidPasswordNoCode_SetsTwoFactorEnabledFalse`
  - [ ] `DisableTwoFactorAuthAsync_ValidPasswordValidCode_SetsTwoFactorEnabledFalse`
  - [ ] `DisableTwoFactorAuthAsync_DoesNotCallResetAuthenticatorKey`

---

## Section 13 — Tests: API Layer

> Project: `UMS.API.Tests`
> Convention: xUnit + FluentAssertions. Read `references/api-testing.md` before writing.
> Self-service endpoints (no specific permission) use a **2-row Theory**: anonymous → 401, authenticated → 2xx.
> Response-shape assertions: assert field presence and key values, not only status codes.

### 13.1 — login-2fa Endpoint Tests

- [ ] Create `Endpoints/Account/LoginWith2FAEndpointTests.cs`.
- [ ] Implement:
  - [ ] `LoginWith2FA_MissingBody_Returns400`
  - [ ] `LoginWith2FA_InvalidChallengeToken_Returns400`
  - [ ] `LoginWith2FA_ValidTwoStepFlow_Returns200WithAccessTokenAndRefreshToken`
    > Full happy-path integration test: call `/login` first to get the challenge token, then call `/login-2fa` with a valid TOTP code and assert real tokens are returned.

### 13.2 — logout Endpoint Tests

- [ ] Create `Endpoints/Account/LogoutEndpointTests.cs`.
- [ ] Implement:
  - [ ] `Logout_Anonymous_Returns401`
  - [ ] `Logout_Authenticated_ValidRefreshToken_Returns200`
  - [ ] `Logout_Authenticated_MismatchedRefreshToken_Returns400`

### 13.3 — profile Endpoint Tests

- [ ] Create `Endpoints/Account/ProfileEndpointTests.cs`.
- [ ] Implement:
  - [ ] `GetProfile_Anonymous_Returns401`
  - [ ] `GetProfile_Authenticated_Returns200`
  - [ ] `GetProfile_Authenticated_ResponseContainsExpectedFields`
    > Assert: `id`, `email`, `twoFactorEnabled`, `roles`, `permissions` are present in the response body.

### 13.4 — setup-2fa Endpoint Tests

- [ ] Create `Endpoints/Users/SetupTwoFactorAuthEndpointTests.cs`.
- [ ] Implement:
  - [ ] `SetupTwoFactorAuth_Anonymous_Returns401`
  - [ ] `SetupTwoFactorAuth_Authenticated_TwoFactorNotEnabled_Returns200WithKeySecretAndCodeQR`
  - [ ] `SetupTwoFactorAuth_Authenticated_CalledTwiceBeforeEnable_ReturnsSameKey`
  - [ ] `SetupTwoFactorAuth_Authenticated_TwoFactorAlreadyEnabled_Returns400`

### 13.5 — confirm-2fa Endpoint Tests

- [ ] Create `Endpoints/Users/ConfirmTwoFactorAuthEndpointTests.cs`.
- [ ] Implement:
  - [ ] `ConfirmTwoFactorAuth_Anonymous_Returns401`
  - [ ] `ConfirmTwoFactorAuth_Authenticated_NoSetupPerformed_Returns400`
  - [ ] `ConfirmTwoFactorAuth_Authenticated_ValidCode_Returns200`
  - [ ] `ConfirmTwoFactorAuth_Authenticated_InvalidCode_Returns400`

### 13.6 — enable-2fa Endpoint Tests

- [ ] Create `Endpoints/Users/EnableTwoFactorAuthEndpointTests.cs`.
- [ ] Implement:
  - [ ] `EnableTwoFactorAuth_Anonymous_Returns401`
  - [ ] `EnableTwoFactorAuth_Authenticated_ValidCode_Returns200WithRecoveryCodes`
    > Assert response body contains a list of 10 recovery code strings.
  - [ ] `EnableTwoFactorAuth_Authenticated_AlreadyEnabled_Returns400`
  - [ ] `EnableTwoFactorAuth_Authenticated_InvalidCode_Returns400`

### 13.7 — disable-2fa Endpoint Tests

- [ ] Create `Endpoints/Users/DisableTwoFactorAuthEndpointTests.cs`.
- [ ] Implement:
  - [ ] `DisableTwoFactorAuth_Anonymous_Returns401`
  - [ ] `DisableTwoFactorAuth_Authenticated_ValidPassword_Returns200`
  - [ ] `DisableTwoFactorAuth_Authenticated_ValidPasswordAndValidCode_Returns200`
  - [ ] `DisableTwoFactorAuth_Authenticated_WrongPassword_Returns400`
  - [ ] `DisableTwoFactorAuth_Authenticated_WrongTOTPCode_Returns400`
  - [ ] `DisableTwoFactorAuth_Authenticated_TwoFactorNotEnabled_Returns400`

---

## Completion Checklist

| Section | Area | Tasks |
|---|---|---|
| 0 | Prerequisites | Review security decisions table before starting |
| 1 | Configuration | 1.1 → 1.3 |
| 2 | Application — Modify Models | 2.1 |
| 3 | Application — New DTOs | 3.1 → 3.6 |
| 4 | Application — Queries & Commands | 4.1 → 4.12 |
| 5 | Application — Interfaces | 5.1 → 5.2 |
| 6 | Infrastructure — TokenService | 6.1 → 6.5 |
| 7 | Infrastructure — UserService | 7.1 → 7.7 |
| 8 | Infrastructure — DI | 8.1 → 8.2 |
| 9 | API — AccountEndpoints | 9.1 → 9.5 |
| 10 | API — UserEndpoints | 10.1 → 10.4 |
| 11 | Tests — Application | 11.1 → 11.12 |
| 12 | Tests — Infrastructure | 12.1 → 12.8 |
| 13 | Tests — API | 13.1 → 13.7 |

> **Total tracked tasks: 150+**
> Mark each checkbox `[x]` as tasks are completed. Do not mark a task complete if its tests are failing or its implementation is partial.
