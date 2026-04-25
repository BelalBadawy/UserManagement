using Mapster;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Options;
using System.Web;
using UMS.Application.Dtos.Common;
using UMS.Application.Dtos.Email;
using UMS.Application.Dtos.Pagination;
using UMS.Application.Dtos.TwoFactor;
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Users;
using UMS.Application.Features.Users.Commands;
using UMS.Application.Features.Users.Commands.DisableTwoFactorAuth;
using UMS.Application.Features.Users.Commands.Logout;
using UMS.Application.Features.Users.Models.Requests;
using UMS.Application.Features.Users.Models.Responses;
using UMS.Application.Interfaces.Common;
using UMS.Infrastructure.Identity.Configurations;

namespace UMS.Infrastructure.Identity.Services
{
    public class UserService : IUserService
    {
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly RoleManager<ApplicationRole> _roleManager;
        private readonly IEmailService _emailService;
        private readonly IHttpContextAccessor _httpContextAccessor;
        private readonly SeedUsersConfiguration _seedUsersConfiguration;
        private readonly IDateTimeService _dateTimeService;
        private readonly ICurrentUserService _currentUserService;
        private readonly TwoFactorOptions _twoFactorOptions;

        public UserService(
            UserManager<ApplicationUser> userManager,
            RoleManager<ApplicationRole> roleManager,
            IEmailService emailService,
            IHttpContextAccessor contextAccessor,
            IOptions<SeedUsersConfiguration> seedUsersConfiguration,
            IDateTimeService dateTimeService,
            ICurrentUserService currentUserService,
            IOptions<TwoFactorOptions> twoFactorOptions)
        {
            _userManager = userManager;
            _roleManager = roleManager;
            _emailService = emailService;
            _httpContextAccessor = contextAccessor;
            _seedUsersConfiguration = seedUsersConfiguration.Value;
            _dateTimeService = dateTimeService;
            _currentUserService = currentUserService;
            _twoFactorOptions = twoFactorOptions.Value;
        }

        public async Task<IResponseWrapper> RegisterUserAsync(UserRegistrationRequest userRegistration)
        {
            var userWithSameEmail = await _userManager.FindByEmailAsync(userRegistration.Email);
            if (userWithSameEmail is not null)
                return ResponseWrapper.Fail("Email address already taken.");

            var newUser = new ApplicationUser
            {
                FullName = userRegistration.FullName,
                Email = userRegistration.Email,
                UserName = userRegistration.Email,
                PhoneNumber = userRegistration.PhoneNumber,
                IsActive = userRegistration.ActivateUser,
                EmailConfirmed = userRegistration.AutoConfirmEmail,
                RefreshToken = _dateTimeService.NowUtc.Ticks.ToString(),
                RefreshTokenExpiryDate = _dateTimeService.NowUtc.AddDays(1)
            };

            var identityUserResult = await _userManager.CreateAsync(newUser, userRegistration.Password);

            if (identityUserResult.Succeeded)
            {
                var identityRoleResult = await _userManager.AddToRoleAsync(newUser, AppRoles.Basic);

                if (identityRoleResult.Succeeded)
                {
                    if (!userRegistration.AutoConfirmEmail)
                    {
                        var httpRequest = _httpContextAccessor.HttpContext?.Request;
                        var baseUrl     = $"{httpRequest?.Scheme}://{httpRequest?.Host}{httpRequest?.PathBase}";
                        var emailToken  = await _userManager.GenerateEmailConfirmationTokenAsync(newUser);
                        var callbackUrl = $"{baseUrl}/Account/ConfirmEmail" +
                                          $"?userId={newUser.Id}" +
                                          $"&token={HttpUtility.UrlEncode(emailToken)}";

                        await _emailService.SendAsync(new SendEmailDto
                        {
                            Subject     = "Confirm Your Email",
                            MailTo      = newUser.Email,
                            MessageBody = $"<p>Hello: {newUser.FullName}</p>" +
                                          "<p>Please confirm your email by clicking the link below.</p>" +
                                          $"<p><a href=\"{callbackUrl}\">Confirm Email</a></p>"
                        });
                    }

                    return ResponseWrapper.Success("User registered successfully.");
                }

                return ResponseWrapper.Fail(GetIdentityResultErrorDescriptions(identityRoleResult));
            }

            return ResponseWrapper.Fail(GetIdentityResultErrorDescriptions(identityUserResult));
        }

        public async Task<IResponseWrapper> UpdateUserAsync(UpdateUserRequest userUpdate)
        {
            var userInDb = await _userManager.FindByIdAsync(userUpdate.UserId.ToString());

            if (userInDb is not null)
            {
                userInDb.FullName = userUpdate.FullName;
                userInDb.PhoneNumber = userUpdate.PhoneNumber;

                var identityResult = await _userManager.UpdateAsync(userInDb);

                if (identityResult.Succeeded)
                {
                    return ResponseWrapper.Success("User updated successfully.");
                }

                return ResponseWrapper.Fail(GetIdentityResultErrorDescriptions(identityResult));
            }

            return ResponseWrapper.Fail("User does not exists.");
        }

        #region Private Helpers
        private static List<string> GetIdentityResultErrorDescriptions(IdentityResult identityResult)
        {
            var errorDescriptions = new List<string>();
            foreach (var error in identityResult.Errors)
            {
                errorDescriptions.Add(error.Description);
            }

            return errorDescriptions;
        }
        #endregion

        public async Task<IResponseWrapper<UserResponse>> GetUserByIdAsync(int userId)
        {
            var userInDb = await _userManager.FindByIdAsync(userId.ToString());
            if (userInDb is not null)
            {
                var mappedUser = userInDb.Adapt<UserResponse>();

                return ResponseWrapper<UserResponse>.Success(data: mappedUser);
            }

            return ResponseWrapper<UserResponse>.Fail("User does not exists.");
        }

        public async Task<IResponseWrapper<List<UserResponse>>> GetAllUsersAsync()
        {
            var usersInDb = await _userManager
                .Users
                .ToListAsync();

            if (usersInDb.Count > 0)
            {
                var mappedUsers = usersInDb.Adapt<List<UserResponse>>();

                return ResponseWrapper<List<UserResponse>>.Success(data: mappedUsers);
            }

            return ResponseWrapper<List<UserResponse>>.Fail("No Users were found.");
        }

        public async Task<IResponseWrapper<PagedResult<UserResponse>>> GetUsersPagedQueryAsync(
            PagedFilterRequest pagedFilterRequest,
            CancellationToken ct)
        {
            var usersQuery = _userManager.Users.AsQueryable();

            if (!string.IsNullOrWhiteSpace(pagedFilterRequest.SearchTerm))
            {
                var term = pagedFilterRequest.SearchTerm.Trim();
                var searchPattern = $"%{term}%";

                usersQuery = usersQuery.Where(u =>
                    EF.Functions.Like(u.FullName, searchPattern) ||
                    EF.Functions.Like(u.Email, searchPattern)
                );
            }

            usersQuery = pagedFilterRequest.SortBy?.ToLower() switch
            {
                "email" => pagedFilterRequest.SortDirection == "desc"
                    ? usersQuery.OrderByDescending(u => u.Email)
                    : usersQuery.OrderBy(u => u.Email),

                "id" => pagedFilterRequest.SortDirection == "desc"
                    ? usersQuery.OrderByDescending(u => u.Id)
                    : usersQuery.OrderBy(u => u.Id),

                "fullname" or _ => pagedFilterRequest.SortDirection == "desc"
                    ? usersQuery.OrderByDescending(u => u.FullName)
                    : usersQuery.OrderBy(u => u.FullName),
            };

            var totalRecords = await usersQuery.CountAsync(ct);

            var users = await usersQuery
                .Skip((pagedFilterRequest.PageNumber - 1) * pagedFilterRequest.PageSize)
                .Take(pagedFilterRequest.PageSize)
                .Select(o => new UserResponse
                {
                    FullName = o.FullName,
                    Email = o.Email,
                    Id = o.Id,
                    IsActive = o.IsActive,
                    PhoneNumber = o.PhoneNumber,
                    UserName = o.UserName,
                    EmailConfirmed = o.EmailConfirmed
                })
                .ToListAsync(ct);

            var data = new PagedResult<UserResponse>
            {
                Data = users,
                TotalCount = totalRecords,
                CurrentPage = pagedFilterRequest.PageNumber,
                PageSize = pagedFilterRequest.PageSize,
            };

            return ResponseWrapper<PagedResult<UserResponse>>.Success(data: data);
        }

        public async Task<IResponseWrapper> ChangeUserPasswordAsync(ChangePasswordRequest changePassword)
        {
            var userInDb = await _userManager.FindByIdAsync(changePassword.UserId.ToString());
            if (userInDb is not null)
            {
                var identityResult = await _userManager.ChangePasswordAsync(
                    userInDb,
                    changePassword.CurrentPassword,
                    changePassword.NewPassword);

                if (identityResult.Succeeded)
                {
                    return ResponseWrapper.Success(message: "User password updated.");
                }

                return ResponseWrapper.Fail(GetIdentityResultErrorDescriptions(identityResult));
            }

            return ResponseWrapper.Fail("User does not exist.");
        }

        public async Task<IResponseWrapper> ChangeUserStatusAsync(ChangeUserStatusRequest changeUserStatus)
        {
            var userInDb = await _userManager.FindByIdAsync(changeUserStatus.UserId.ToString());
            if (userInDb is not null)
            {
                userInDb.IsActive = changeUserStatus.ActivateOrDeactivate;

                var identityResult = await _userManager.UpdateAsync(userInDb);

                if (identityResult.Succeeded)
                {
                    return ResponseWrapper
                        .Success(changeUserStatus.ActivateOrDeactivate
                            ? "User activated successfully."
                            : "User de-activated successfully");
                }

                return ResponseWrapper.Fail(GetIdentityResultErrorDescriptions(identityResult));
            }

            return ResponseWrapper.Fail("User does not exist.");
        }

        public async Task<IResponseWrapper<List<UserRoleViewModel>>> GetUserRolesAsync(int userId)
        {
            var userRolesViewModel = new List<UserRoleViewModel>();
            var userInDb = await _userManager.FindByIdAsync(userId.ToString());

            if (userInDb is not null)
            {
                var allRoles = await _roleManager.Roles.ToListAsync();

                foreach (var role in allRoles)
                {
                    var userRoleViewModel = new UserRoleViewModel
                    {
                        RoleName = role.Name,
                        RoleDescription = role.Description
                    };

                    if (await _userManager.IsInRoleAsync(userInDb, role.Name))
                    {
                        userRolesViewModel.Add(userRoleViewModel);
                    }
                }

                return ResponseWrapper<List<UserRoleViewModel>>.Success(userRolesViewModel);
            }

            return ResponseWrapper<List<UserRoleViewModel>>.Fail("User does not exist.");
        }

        public async Task<IResponseWrapper> UpdateUserRolesAsync(UpdateUserRolesRequest request, CancellationToken ct)
        {
            var user = await _userManager.Users
                .FirstOrDefaultAsync(u => u.Id == request.UserId, ct);

            if (user is null)
                return ResponseWrapper.Fail("User does not exist.");

            if (string.Equals(user.Email, _seedUsersConfiguration.Admin.Email, StringComparison.OrdinalIgnoreCase))
                return ResponseWrapper.Fail("User roles update not permitted.");

            var rolesToAssign = request.Roles.ToList();

            foreach (var roleName in rolesToAssign)
            {
                if (!await _roleManager.RoleExistsAsync(roleName))
                    return ResponseWrapper.Fail($"Role '{roleName}' does not exist.");
            }

            var currentRoles = await _userManager.GetRolesAsync(user);

            var removeResult = await _userManager.RemoveFromRolesAsync(user, currentRoles);
            if (!removeResult.Succeeded)
                return ResponseWrapper.Fail(GetIdentityResultErrorDescriptions(removeResult));

            var addResult = await _userManager.AddToRolesAsync(user, rolesToAssign);
            if (!addResult.Succeeded)
                return ResponseWrapper.Fail(GetIdentityResultErrorDescriptions(addResult));

            return ResponseWrapper.Success("Updated user roles successfully.");
        }

        public async Task<IResponseWrapper> ForgotPasswordAsync(string email)
        {
            var user = await _userManager.FindByEmailAsync(email);
            if (user is null)
                return ResponseWrapper.Fail("This email doesn't exist.");

            if (!user.EmailConfirmed)
                return ResponseWrapper.Fail("This email is not confirmed.");

            var request = _httpContextAccessor.HttpContext?.Request;
            var baseUrl = $"{request.Scheme}://{request.Host}{request.PathBase}";
            var code = await _userManager.GeneratePasswordResetTokenAsync(user);
            var callbackUrl =
                $"{baseUrl}/Account/ResetPassword?email={HttpUtility.UrlEncode(user.Email)}&code={HttpUtility.UrlEncode(code)}";

            var emailModel = new SendEmailDto
            {
                Subject = "Reset Password",
                MailTo = user.Email,
                MessageBody = $"<p>Hello: {user.FullName}</p>" +
                $"<p>Username: {user.UserName}.</p>" +
                "<p>In order to reset your password, please click on the following link.</p>" +
                $"<p><a href=\"{callbackUrl}\">Click here</a></p>" +
                "<p>Thank you,</p>"
            };

            try
            {
                var result = await _emailService.SendAsync(emailModel);

                if (string.IsNullOrEmpty(result))
                    return ResponseWrapper.Success("Reset password email sent successfully.");

                return ResponseWrapper.Fail(result);
            }
            catch (Exception ex)
            {
                return ResponseWrapper.Fail(ex.Message);
            }
        }

        public async Task<IResponseWrapper> ResetPasswordAsync(ResetPasswordRequest request)
        {
            var user = await _userManager.FindByEmailAsync(request.Email);
            if (user is null)
                return ResponseWrapper.Fail("This email doesn't exist.");

            if (!user.EmailConfirmed)
                return ResponseWrapper.Fail("This email is not confirmed.");

            try
            {
                var result = await _userManager.ResetPasswordAsync(user, request.Token, request.Password);

                if (result.Succeeded)
                {
                    await _userManager.UpdateSecurityStampAsync(user);
                    return ResponseWrapper.Success("Your password has changed successfully.");
                }

                return ResponseWrapper.Fail(GetIdentityResultErrorDescriptions(result));
            }
            catch (Exception)
            {
                return ResponseWrapper.Fail(SD.ErrorOccured);
            }
        }

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

        public async Task<IResponseWrapper> ConfirmEmailChangeAsync(int userId, string newEmail, string token)
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

        public async Task<IResponseWrapper> ResendConfirmationEmailAsync(string email)
        {
            var user = await _userManager.FindByEmailAsync(email);
            if (user is null)
                return ResponseWrapper.Fail("This email doesn't exist.");

            if (user.EmailConfirmed)
                return ResponseWrapper.Fail("Email is already confirmed.");

            var httpRequest = _httpContextAccessor.HttpContext?.Request;
            var baseUrl     = $"{httpRequest?.Scheme}://{httpRequest?.Host}{httpRequest?.PathBase}";
            var token       = await _userManager.GenerateEmailConfirmationTokenAsync(user);
            var callbackUrl = $"{baseUrl}/Account/ConfirmEmail" +
                              $"?userId={user.Id}" +
                              $"&token={HttpUtility.UrlEncode(token)}";

            await _emailService.SendAsync(new SendEmailDto
            {
                Subject     = "Confirm Your Email",
                MailTo      = user.Email,
                MessageBody = $"<p>Hello: {user.FullName}</p>" +
                              "<p>Please confirm your email by clicking the link below.</p>" +
                              $"<p><a href=\"{callbackUrl}\">Confirm Email</a></p>"
            });

            return ResponseWrapper.Success("Confirmation email sent. Please check your inbox.");
        }

        public async Task<IResponseWrapper> GenerateChangeEmailTokenAsync(string newEmail)
        {
            var userId = _currentUserService.GetUserId();
            var user   = await _userManager.FindByIdAsync(userId?.ToString());
            if (user is null)
                return ResponseWrapper.Fail("User does not exist.");

            if (string.Equals(user.Email, newEmail, StringComparison.OrdinalIgnoreCase))
                return ResponseWrapper.Fail("New email must be different from your current email.");

            var httpRequest = _httpContextAccessor.HttpContext?.Request;
            var baseUrl     = $"{httpRequest?.Scheme}://{httpRequest?.Host}{httpRequest?.PathBase}";
            var token       = await _userManager.GenerateChangeEmailTokenAsync(user, newEmail);
            var callbackUrl = $"{baseUrl}/Account/ConfirmEmailChange" +
                              $"?userId={user.Id}" +
                              $"&newEmail={HttpUtility.UrlEncode(newEmail)}" +
                              $"&token={HttpUtility.UrlEncode(token)}";

            await _emailService.SendAsync(new SendEmailDto
            {
                Subject     = "Confirm Your Email Change",
                MailTo      = user.Email,
                MessageBody = $"<p>Hello: {user.FullName}</p>" +
                              "<p>Click the link below to confirm your email change.</p>" +
                              $"<p><a href=\"{callbackUrl}\">Confirm Email Change</a></p>"
            });

            return ResponseWrapper.Success("Email change confirmation sent. Please check your inbox.");
        }

        public async Task<IResponseWrapper<List<string>>> GenerateNew2FARecoveryCodesAsync()
        {
            var userId = _currentUserService.GetUserId();
            var user   = await _userManager.FindByIdAsync(userId?.ToString());
            if (user is null)
                return ResponseWrapper<List<string>>.Fail("User does not exist.");

            if (!user.TwoFactorEnabled)
                return ResponseWrapper<List<string>>.Fail("Two-factor authentication is not enabled.");

            var codes = await _userManager.GenerateNewTwoFactorRecoveryCodesAsync(user, 10);
            return ResponseWrapper<List<string>>.Success(codes!.ToList(), "New recovery codes generated.");
        }

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

        public async Task<IResponseWrapper> UnlockUserAsync(int userId)
        {
            var user = await _userManager.FindByIdAsync(userId.ToString());
            if (user is null)
                return ResponseWrapper.Fail("User does not exist.");

            await _userManager.SetLockoutEndDateAsync(user, DateTimeOffset.UtcNow);
            await _userManager.ResetAccessFailedCountAsync(user);

            return ResponseWrapper.Success("User unlocked successfully.");
        }

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

            user.RefreshToken           = string.Empty;
            user.RefreshTokenExpiryDate = _dateTimeService.NowUtc.AddDays(-1);
            await _userManager.UpdateAsync(user);

            return ResponseWrapper.Success("Logged out successfully.");
        }

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

        public async Task<IResponseWrapper> DisableTwoFactorAuthAsync(
            DisableTwoFactorAuthRequest request)
        {
            var userId = _currentUserService.GetUserId();
            var user   = await _userManager.FindByIdAsync(userId?.ToString());
            if (user is null)
                return ResponseWrapper.Fail("User not found.");

            if (!user.TwoFactorEnabled)
                return ResponseWrapper.Fail("Two-factor authentication is not enabled.");

            var passwordValid = await _userManager.CheckPasswordAsync(user, request.Password);
            if (!passwordValid)
            {
                await _userManager.AccessFailedAsync(user);
                if (await _userManager.IsLockedOutAsync(user))
                    return ResponseWrapper.Fail("Account locked due to multiple failed attempts.");
                return ResponseWrapper.Fail("Invalid password.");
            }

            if (!string.IsNullOrEmpty(request.Code))
            {
                var codeValid = await _userManager.VerifyTwoFactorTokenAsync(
                    user,
                    _userManager.Options.Tokens.AuthenticatorTokenProvider,
                    request.Code);

                if (!codeValid)
                    return ResponseWrapper.Fail("Invalid authenticator code.");
            }

            await _userManager.ResetAccessFailedCountAsync(user);
            await _userManager.SetTwoFactorEnabledAsync(user, false);

            return ResponseWrapper.Success("Two-factor authentication disabled.");
        }
    }
}
