using Mapster;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Options;
using UMS.Application.Dtos.Common;
using UMS.Application.Dtos.Email;
using UMS.Application.Dtos.Pagination;
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Users;
using UMS.Application.Features.Users.Commands;
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

        public UserService(
            UserManager<ApplicationUser> userManager,
            RoleManager<ApplicationRole> roleManager,
            IEmailService emailService,
            IHttpContextAccessor contextAccessor,
            IOptions<SeedUsersConfiguration> seedUsersConfiguration,
            IDateTimeService dateTimeService)
        {
            _userManager = userManager;
            _roleManager = roleManager;
            _emailService = emailService;
            _httpContextAccessor = contextAccessor;
            _seedUsersConfiguration = seedUsersConfiguration.Value;
            _dateTimeService = dateTimeService;
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
            var callbackUrl = $"{baseUrl}/Account/ResetPassword?email={user.Email}&code={code}";

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
    }
}
