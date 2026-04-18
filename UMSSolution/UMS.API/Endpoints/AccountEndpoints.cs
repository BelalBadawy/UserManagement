using Mediator;
using UMS.API.Extensions;
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Token.Queries;
using UMS.Application.Features.Users.Commands;

namespace UMS.API.Endpoints;

public static class AccountEndpoints
{
    public static IEndpointRouteBuilder MapAccountEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("api/v{version:apiVersion}/account")
                       .WithTags("Account")
                       .AllowAnonymous();
        
        group.MapPost("login", async (TokenRequest tokenRequest, ISender sender) =>
        {
            var response = await sender.Send(new GetTokenQuery { TokenRequest = tokenRequest });
            return response.ToApiResult();
        })
        .Produces<IResponseWrapper<TokenResponse>>(StatusCodes.Status200OK)
        .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest);

        group.MapPost("refresh-token", async (RefreshTokenRequest refreshTokenRequest, ISender sender) =>
        {
            var response = await sender.Send(new GetRefreshTokenQuery { RefreshTokenRequest = refreshTokenRequest });
            return response.ToApiResult();
        })
        .Produces<IResponseWrapper<TokenResponse>>(StatusCodes.Status200OK)
        .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest);

        group.MapPost("forgot-password", async (string email, ISender sender) =>
        {
            var response = await sender.Send(new ForgotPasswordCommand { Email = email });
            return response.ToApiResult();
        })
        .Produces<IResponseWrapper>(StatusCodes.Status200OK)
        .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest);

        group.MapPost("reset-password", async (ResetPasswordRequest request, ISender sender) =>
        {
            var response = await sender.Send(new ResetPasswordCommand { ResetPasswordRequest = request });
            return response.ToApiResult();
        })
        .Produces<IResponseWrapper>(StatusCodes.Status200OK)
        .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest);

        return app;
    }
}