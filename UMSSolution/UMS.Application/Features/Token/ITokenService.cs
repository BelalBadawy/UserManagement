using UMS.Application.Features.Token.Queries;

namespace UMS.Application.Features.Token
{
    public interface ITokenService
    {
        Task<IResponseWrapper<TokenResponse>> GetTokenAsync(TokenRequest tokenRequest);
        Task<IResponseWrapper<TokenResponse>> GetRefreshTokenAsync(RefreshTokenRequest refreshTokenRequest);
    }
}
