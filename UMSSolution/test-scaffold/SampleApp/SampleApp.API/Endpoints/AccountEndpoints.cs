using Mediator;
using SampleApp.API.Extensions;
using SampleApp.Application.Dtos.Wrappers;
using SampleApp.Application.Features.Token.Queries;
using SampleApp.Application.Features.Token.Queries.LoginWith2FA;
using SampleApp.Application.Features.Users.Commands;
using SampleApp.Application.Features.Users.Commands.Logout;
using SampleApp.Application.Features.Users.Models.Responses;
using SampleApp.Application.Features.Users.Queries.GetMyProfile;

namespace SampleApp.API.Endpoints;

public record ForgotPasswordRequest(string Email);

public static class AccountEndpoints
{
    public static IEndpointRouteBuilder MapAccountEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("api/v{version:apiVersion}/account")
                       .WithTags("Account")
                       .AllowAnonymous();

        group.MapPost("login", async (TokenRequest tokenRequest, ISender sender, CancellationToken ct) =>
        {
            var response = await sender.Send(new GetTokenQuery { TokenRequest = tokenRequest }, ct);
            return response.ToApiResult();
        })
        .RequireRateLimiting("auth")
        .Produces<IResponseWrapper<TokenResponse>>(StatusCodes.Status200OK)
        .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest)
        .Produces(StatusCodes.Status429TooManyRequests);

        group.MapPost("refresh-token", async (RefreshTokenRequest refreshTokenRequest, ISender sender, CancellationToken ct) =>
        {
            var response = await sender.Send(new GetRefreshTokenQuery { RefreshTokenRequest = refreshTokenRequest }, ct);
            return response.ToApiResult();
        })
        .Produces<IResponseWrapper<TokenResponse>>(StatusCodes.Status200OK)
        .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest);

        group.MapPost("forgot-password", async ([AsParameters] ForgotPasswordRequest request, ISender sender, CancellationToken ct) =>
        {
            var response = await sender.Send(new ForgotPasswordCommand { Email = request.Email }, ct);
            return response.ToApiResult();
        })
        .RequireRateLimiting("auth")
        .Produces<IResponseWrapper>(StatusCodes.Status200OK)
        .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest)
        .Produces(StatusCodes.Status429TooManyRequests);

        group.MapPost("reset-password", async (ResetPasswordRequest request, ISender sender, CancellationToken ct) =>
        {
            var response = await sender.Send(new ResetPasswordCommand { ResetPasswordRequest = request }, ct);
            return response.ToApiResult();
        })
        .Produces<IResponseWrapper>(StatusCodes.Status200OK)
        .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest);

        group.MapPost("confirm-email", async (ConfirmEmailRequest request, ISender sender, CancellationToken ct) =>
        {
            var response = await sender.Send(new ConfirmEmailCommand { ConfirmEmail = request }, ct);
            return response.ToApiResult();
        })
        .Produces<IResponseWrapper>(StatusCodes.Status200OK)
        .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest);

        group.MapPost("confirm-email-change", async (ConfirmEmailChangeRequest request, ISender sender, CancellationToken ct) =>
        {
            var response = await sender.Send(new ConfirmEmailChangeCommand { ConfirmEmailChange = request }, ct);
            return response.ToApiResult();
        })
        .Produces<IResponseWrapper>(StatusCodes.Status200OK)
        .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest);

        group.MapPost("resend-confirmation-email", async (ResendConfirmationEmailRequest request, ISender sender, CancellationToken ct) =>
        {
            var response = await sender.Send(new ResendConfirmationEmailCommand { ResendConfirmation = request }, ct);
            return response.ToApiResult();
        })
        .Produces<IResponseWrapper>(StatusCodes.Status200OK)
        .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest);

        group.MapPost("login-2fa",
            async (TwoFactorLoginRequest request, ISender sender, CancellationToken ct) =>
            {
                var response = await sender.Send(
                    new LoginWith2FAQuery { Request = request }, ct);
                return response.ToApiResult();
            })
        .RequireRateLimiting("auth")
        .Produces<IResponseWrapper<TokenResponse>>(StatusCodes.Status200OK)
        .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest)
        .Produces<IResponseWrapper>(StatusCodes.Status401Unauthorized)
        .Produces(StatusCodes.Status429TooManyRequests);

        var authGroup = app
            .MapGroup("api/v{version:apiVersion}/account")
            .WithTags("Account")
            .RequireAuthorization();

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

        return app;
    }
}