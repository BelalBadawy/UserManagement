using Mediator;
using UMS.API.Extensions;
using UMS.Application.Authorization;
using UMS.Application.Dtos.Pagination;
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Users.Commands;
using UMS.Application.Features.Users.Commands.ConfirmTwoFactorAuth;
using UMS.Application.Features.Users.Commands.DisableTwoFactorAuth;
using UMS.Application.Features.Users.Commands.EnableTwoFactorAuth;
using UMS.Application.Features.Users.Commands.SetupTwoFactorAuth;
using UMS.Application.Features.Users.Models.Requests;
using UMS.Application.Features.Users.Models.Responses;
using UMS.Application.Features.Users.Queries;

namespace WebApi.Endpoints;

public static class UserEndpoints
{
    public static IEndpointRouteBuilder MapUserEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("api/v{version:apiVersion}/users")
                       .WithTags("Users")
                       .RequireAuthorization();

        group.MapPost("register", async (UserRegistrationRequest userRegistration, ISender sender, CancellationToken ct) =>
        {
            var response = await sender.Send(new UserRegistrationCommand { UserRegistration = userRegistration }, ct);
            return response.ToApiResult();
        }).RequireAuthorization(AppPermission.NameFor(AppService.Identity, AppFeature.Users, AppAction.Create))
          .Produces<IResponseWrapper>(StatusCodes.Status200OK)
          .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest);

        group.MapGet("{userId:int}", async (int userId, ISender sender, CancellationToken ct) =>
        {
            var response = await sender.Send(new GetUserByIdQuery { UserId = userId }, ct);
            return response.IsSuccessful ? Results.Ok(response) : Results.NotFound(response);
        }).RequireAuthorization(AppPermission.NameFor(AppService.Identity, AppFeature.Users, AppAction.Read))
          .Produces<IResponseWrapper<UserResponse>>(StatusCodes.Status200OK)
          .Produces<IResponseWrapper>(StatusCodes.Status404NotFound);

        group.MapGet("paged-list", async ([AsParameters] PagedFilterRequest query, ISender sender, CancellationToken ct) =>
        {
            var response = await sender.Send(new GetUsersPagedQuery { PagedFilterRequest = query }, ct);
            return response.IsSuccessful ? Results.Ok(response) : Results.NotFound(response);
        }).RequireAuthorization(AppPermission.NameFor(AppService.Identity, AppFeature.Users, AppAction.Read))
          .Produces<IResponseWrapper<PagedResult<UserResponse>>>(StatusCodes.Status200OK)
          .Produces<IResponseWrapper>(StatusCodes.Status404NotFound);

        group.MapPut("update", async (UpdateUserRequest updateUser, ISender sender, CancellationToken ct) =>
        {
            var response = await sender.Send(new UpdateUserCommand { UpdateUser = updateUser }, ct);
            return response.IsSuccessful ? Results.Ok(response) : Results.NotFound(response);
        }).RequireAuthorization(AppPermission.NameFor(AppService.Identity, AppFeature.Users, AppAction.Update))
          .Produces<IResponseWrapper>(StatusCodes.Status200OK)
          .Produces<IResponseWrapper>(StatusCodes.Status404NotFound);

        group.MapPut("change-password", async (ChangePasswordRequest changePassword, ISender sender, CancellationToken ct) =>
        {
            var response = await sender.Send(new ChangeUserPasswordCommand { ChangePassword = changePassword }, ct);
            return response.IsSuccessful ? Results.Ok(response) : Results.NotFound(response);
        }).Produces<IResponseWrapper>(StatusCodes.Status200OK)
          .Produces<IResponseWrapper>(StatusCodes.Status404NotFound);

        group.MapPut("change-status", async (ChangeUserStatusRequest changeUserStatus, ISender sender, CancellationToken ct) =>
        {
            var response = await sender.Send(new ChangeUserStatusCommand { ChangeUserStatus = changeUserStatus }, ct);
            return response.IsSuccessful ? Results.Ok(response) : Results.NotFound(response);
        }).RequireAuthorization(AppPermission.NameFor(AppService.Identity, AppFeature.Users, AppAction.Update))
          .Produces<IResponseWrapper>(StatusCodes.Status200OK)
          .Produces<IResponseWrapper>(StatusCodes.Status404NotFound);

        group.MapPut("user-roles", async (UpdateUserRolesRequest updateUserRoles, ISender sender, CancellationToken ct) =>
        {
            var response = await sender.Send(new UpdateUserRolesCommand { UpdateUserRoles = updateUserRoles }, ct);
            return response.ToApiResult();
        }).RequireAuthorization(AppPermission.NameFor(AppService.Identity, AppFeature.Users, AppAction.Update))
          .Produces<IResponseWrapper>(StatusCodes.Status200OK)
          .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest);

        group.MapGet("roles/{userId:int}", async (int userId, ISender sender, CancellationToken ct) =>
        {
            var response = await sender.Send(new GetUserRolesQuery { UserId = userId }, ct);
            return response.IsSuccessful ? Results.Ok(response) : Results.NotFound(response);
        }).RequireAuthorization(AppPermission.NameFor(AppService.Identity, AppFeature.Users, AppAction.Read))
          .Produces<IResponseWrapper<List<UserRoleViewModel>>>(StatusCodes.Status200OK)
          .Produces<IResponseWrapper>(StatusCodes.Status404NotFound);

        group.MapPost("generate-change-email-token", async (GenerateChangeEmailTokenRequest request, ISender sender, CancellationToken ct) =>
        {
            var response = await sender.Send(new GenerateChangeEmailTokenCommand { GenerateChangeEmailToken = request }, ct);
            return response.ToApiResult();
        })
        .RequireAuthorization(AppPermission.NameFor(AppService.Identity, AppFeature.Users, AppAction.ChangeEmail))
        .Produces<IResponseWrapper>(StatusCodes.Status200OK)
        .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest);

        group.MapPost("generate-2fa-recovery-codes", async (ISender sender, CancellationToken ct) =>
        {
            var response = await sender.Send(new GenerateNew2FARecoveryCodesCommand(), ct);
            return response.ToApiResult();
        })
        .RequireAuthorization(AppPermission.NameFor(AppService.Identity, AppFeature.Users, AppAction.Manage2FA))
        .Produces<IResponseWrapper<List<string>>>(StatusCodes.Status200OK)
        .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest);

        group.MapPut("lock-user", async (LockUserRequest request, ISender sender, CancellationToken ct) =>
        {
            var response = await sender.Send(new LockUserCommand { LockUser = request }, ct);
            return response.ToApiResult();
        })
        .RequireAuthorization(AppPermission.NameFor(AppService.Identity, AppFeature.Users, AppAction.Lock))
        .Produces<IResponseWrapper>(StatusCodes.Status200OK)
        .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest);

        group.MapPut("unlock-user", async (UnlockUserRequest request, ISender sender, CancellationToken ct) =>
        {
            var response = await sender.Send(new UnlockUserCommand { UnlockUser = request }, ct);
            return response.ToApiResult();
        })
        .RequireAuthorization(AppPermission.NameFor(AppService.Identity, AppFeature.Users, AppAction.Unlock))
        .Produces<IResponseWrapper>(StatusCodes.Status200OK)
        .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest);

        group.MapPost("setup-2fa",
            async (ISender sender, CancellationToken ct) =>
            {
                var response = await sender.Send(new SetupTwoFactorAuthCommand(), ct);
                return response.ToApiResult();
            })
        .Produces<IResponseWrapper<TwoFactorAuthViewModel>>(StatusCodes.Status200OK)
        .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest);

        group.MapPost("confirm-2fa",
            async (TwoFactorCodeRequest request, ISender sender, CancellationToken ct) =>
            {
                var response = await sender.Send(
                    new ConfirmTwoFactorAuthCommand { Request = request }, ct);
                return response.ToApiResult();
            })
        .Produces<IResponseWrapper>(StatusCodes.Status200OK)
        .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest);

        group.MapPut("enable-2fa",
            async (TwoFactorCodeRequest request, ISender sender, CancellationToken ct) =>
            {
                var response = await sender.Send(
                    new EnableTwoFactorAuthCommand { Request = request }, ct);
                return response.ToApiResult();
            })
        .Produces<IResponseWrapper<List<string>>>(StatusCodes.Status200OK)
        .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest);

        group.MapPut("disable-2fa",
            async (DisableTwoFactorAuthRequest request, ISender sender, CancellationToken ct) =>
            {
                var response = await sender.Send(
                    new DisableTwoFactorAuthCommand { Request = request }, ct);
                return response.ToApiResult();
            })
        .Produces<IResponseWrapper>(StatusCodes.Status200OK)
        .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest);

        return app;
    }
}
