using System.Security.Claims;
using System.Text.Encodings.Web;
using Microsoft.AspNetCore.Authentication;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;
using Microsoft.Extensions.Logging;
using UMS.Infrastructure.Identity.Constants;

namespace UMS.API.Tests.Support;

public sealed class ApiTestAuthenticationHandler : AuthenticationHandler<AuthenticationSchemeOptions>
{
    public const string SchemeName = "ApiTest";
    public const string AuthModeHeaderName = "X-Test-Auth-Mode";
    public const string RequiredPermissionHeaderName = "X-Test-Required-Permission";
    private const string AnonymousMode = "anonymous";
    private const string LowPrivilegeMode = "low-privilege";
    private const string PrivilegedMode = "privileged";

    public ApiTestAuthenticationHandler(
        IOptionsMonitor<AuthenticationSchemeOptions> options,
        ILoggerFactory logger,
        UrlEncoder encoder)
        : base(options, logger, encoder)
    {
    }

    protected override Task<AuthenticateResult> HandleAuthenticateAsync()
    {
        if (!Request.Headers.TryGetValue(AuthModeHeaderName, out var authModeValues))
        {
            return Task.FromResult(AuthenticateResult.NoResult());
        }

        var authMode = authModeValues.ToString();
        if (string.Equals(authMode, AnonymousMode, StringComparison.OrdinalIgnoreCase))
        {
            return Task.FromResult(AuthenticateResult.NoResult());
        }

        var requiredPermission = Request.Headers[RequiredPermissionHeaderName].ToString();
        if (string.IsNullOrWhiteSpace(requiredPermission))
        {
            return Task.FromResult(AuthenticateResult.Fail(
                $"{RequiredPermissionHeaderName} header is required for authenticated API test clients."));
        }

        var jwtIssuer = Context.RequestServices
            .GetRequiredService<IConfiguration>()
            .GetSection("JwtConfiguration")
            .GetValue<string>("Issuer")
            ?? throw new InvalidOperationException("JwtConfiguration:Issuer is required for API test authentication.");

        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, "999001", ClaimValueTypes.String, jwtIssuer),
            new(ClaimTypes.Email, "api-tests@example.com", ClaimValueTypes.String, jwtIssuer),
            new(ClaimTypes.Name, "API Test User", ClaimValueTypes.String, jwtIssuer),
            new(ClaimTypes.Role, "Basic", ClaimValueTypes.String, jwtIssuer)
        };

        if (string.Equals(authMode, PrivilegedMode, StringComparison.OrdinalIgnoreCase))
        {
            claims.Add(new Claim(AppClaim.Permission, requiredPermission, ClaimValueTypes.String, jwtIssuer));
        }
        else if (string.Equals(authMode, LowPrivilegeMode, StringComparison.OrdinalIgnoreCase))
        {
            claims.Add(new Claim(
                AppClaim.Permission,
                ApiPermissionHelper.GetWrongPermission(requiredPermission),
                ClaimValueTypes.String,
                jwtIssuer));
        }
        else
        {
            return Task.FromResult(AuthenticateResult.Fail($"Unsupported API test auth mode '{authMode}'."));
        }

        var identity = new ClaimsIdentity(claims, SchemeName, ClaimTypes.Name, ClaimTypes.Role);
        var principal = new ClaimsPrincipal(identity);
        var ticket = new AuthenticationTicket(principal, SchemeName);

        return Task.FromResult(AuthenticateResult.Success(ticket));
    }
}
