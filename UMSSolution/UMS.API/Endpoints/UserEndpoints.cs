using Mediator;
using UMS.API.Extensions;
using UMS.Application.Dtos.Pagination;
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Users.Commands;
using UMS.Application.Features.Users.Models.Requests;
using UMS.Application.Features.Users.Models.Responses;
using UMS.Application.Features.Users.Queries;
using UMS.Infrastructure.Identity.Constants;

namespace WebApi.Endpoints;

public static class UserEndpoints
{
    public static IEndpointRouteBuilder MapUserEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("api/v{version:apiVersion}/users")
                       .WithTags("Users")
                       .RequireAuthorization();

        group.MapPost("register", async (UserRegistrationRequest userRegistration, ISender sender) =>
        {
            var response = await sender.Send(new UserRegistrationCommand { UserRegistration = userRegistration });
            return response.ToApiResult();
        }).RequireAuthorization(AppPermission.NameFor(AppService.Identity, AppFeature.Users, AppAction.Create))
          .Produces<IResponseWrapper>(StatusCodes.Status200OK)
          .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest);

        group.MapGet("{userId:int}", async (int userId, ISender sender) =>
        {
            var response = await sender.Send(new GetUserByIdQuery { UserId = userId });
            return response.IsSuccessful ? Results.Ok(response) : Results.NotFound(response);
        }).RequireAuthorization(AppPermission.NameFor(AppService.Identity, AppFeature.Users, AppAction.Read))
          .Produces<IResponseWrapper<UserResponse>>(StatusCodes.Status200OK)
          .Produces<IResponseWrapper>(StatusCodes.Status404NotFound);

        group.MapGet("all", async (ISender sender) =>
        {
            var response = await sender.Send(new GetAllUsersQuery());
            return response.IsSuccessful ? Results.Ok(response) : Results.NotFound(response);
        }).RequireAuthorization(AppPermission.NameFor(AppService.Identity, AppFeature.Users, AppAction.Read))
          .Produces<IResponseWrapper<List<UserResponse>>>(StatusCodes.Status200OK)
          .Produces<IResponseWrapper>(StatusCodes.Status404NotFound);

        group.MapGet("paged-list", async ([AsParameters] PagedFilterRequest query, ISender sender) =>
        {
            var response = await sender.Send(new GetUsersPagedQuery { PagedFilterRequest = query });
            return response.IsSuccessful ? Results.Ok(response) : Results.NotFound(response);
        }).RequireAuthorization(AppPermission.NameFor(AppService.Identity, AppFeature.Users, AppAction.Read))
          .Produces<IResponseWrapper<PagedResult<UserResponse>>>(StatusCodes.Status200OK)
          .Produces<IResponseWrapper>(StatusCodes.Status404NotFound);

        group.MapPut("update", async (UpdateUserRequest updateUser, ISender sender) =>
        {
            var response = await sender.Send(new UpdateUserCommand { UpdateUser = updateUser });
            return response.IsSuccessful ? Results.Ok(response) : Results.NotFound(response);
        }).RequireAuthorization(AppPermission.NameFor(AppService.Identity, AppFeature.Users, AppAction.Update))
          .Produces<IResponseWrapper>(StatusCodes.Status200OK)
          .Produces<IResponseWrapper>(StatusCodes.Status404NotFound);

        group.MapPut("change-password", async (ChangePasswordRequest changePassword, ISender sender) =>
        {
            var response = await sender.Send(new ChangeUserPasswordCommand { ChangePassword = changePassword });
            return response.IsSuccessful ? Results.Ok(response) : Results.NotFound(response);
        }).RequireAuthorization(AppPermission.NameFor(AppService.Identity, AppFeature.Users, AppAction.Update))
          .Produces<IResponseWrapper>(StatusCodes.Status200OK)
          .Produces<IResponseWrapper>(StatusCodes.Status404NotFound);

        group.MapPut("change-status", async (ChangeUserStatusRequest changeUserStatus, ISender sender) =>
        {
            var response = await sender.Send(new ChangeUserStatusCommand { ChangeUserStatus = changeUserStatus });
            return response.IsSuccessful ? Results.Ok(response) : Results.NotFound(response);
        }).RequireAuthorization(AppPermission.NameFor(AppService.Identity, AppFeature.Users, AppAction.Update))
          .Produces<IResponseWrapper>(StatusCodes.Status200OK)
          .Produces<IResponseWrapper>(StatusCodes.Status404NotFound);

        group.MapPut("user-roles", async (UpdateUserRolesRequest updateUserRoles, ISender sender) =>
        {
            var response = await sender.Send(new UpdateUserRolesCommand { UpdateUserRoles = updateUserRoles });
            return response.ToApiResult();
        }).RequireAuthorization(AppPermission.NameFor(AppService.Identity, AppFeature.Users, AppAction.Update))
          .Produces<IResponseWrapper>(StatusCodes.Status200OK)
          .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest);

        group.MapGet("roles/{userId:int}", async (int userId, ISender sender) =>
        {
            var response = await sender.Send(new GetUserRolesQuery { UserId = userId });
            return response.IsSuccessful ? Results.Ok(response) : Results.NotFound(response);
        }).RequireAuthorization(AppPermission.NameFor(AppService.Identity, AppFeature.Users, AppAction.Read))
          .Produces<IResponseWrapper<List<UserRoleViewModel>>>(StatusCodes.Status200OK)
          .Produces<IResponseWrapper>(StatusCodes.Status404NotFound);

        return app;
    }
}