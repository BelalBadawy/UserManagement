using SampleApp.Application.Features.Token.Queries;
using SampleApp.Application.Features.Token.Queries.LoginWith2FA;

namespace SampleApp.Application.Features.Token
{
    public interface ITokenService
    {
        Task<IResponseWrapper<TokenResponse>> GetTokenAsync(TokenRequest tokenRequest);
        Task<IResponseWrapper<TokenResponse>> GetRefreshTokenAsync(RefreshTokenRequest refreshTokenRequest);
        Task<IResponseWrapper<TokenResponse>> LoginWith2FAAsync(TwoFactorLoginRequest request, CancellationToken ct = default);
    }
}