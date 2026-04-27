using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Token;
using UMS.Application.Features.Token.Queries;
using UMS.Application.Features.Token.Queries.LoginWith2FA;

namespace UMS.Application.Tests.Handlers.Token;

public class LoginWith2FAQueryHandlerTests
{
    private readonly Mock<ITokenService> _tokenService = new();

    [Fact]
    public async Task Handle_WhenCalled_CallsTokenServiceLoginWith2FAWithCorrectRequest()
    {
        var request = new TwoFactorLoginRequest
        {
            TwoFactorChallengeToken = "challenge-token",
            Code = "123456"
        };
        var query = new LoginWith2FAQuery { Request = request };

        _tokenService
            .Setup(s => s.LoginWith2FAAsync(request))
            .ReturnsAsync(ResponseWrapper<TokenResponse>.Success(new TokenResponse()));

        var handler = new LoginWith2FAQueryHandler(_tokenService.Object);
        await handler.Handle(query, CancellationToken.None);

        _tokenService.Verify(s => s.LoginWith2FAAsync(request), Times.Once);
    }

    [Fact]
    public async Task Handle_WhenCalled_PassesThroughServiceResult()
    {
        var request = new TwoFactorLoginRequest
        {
            TwoFactorChallengeToken = "challenge-token",
            Code = "123456"
        };
        var query = new LoginWith2FAQuery { Request = request };
        var expected = ResponseWrapper<TokenResponse>.Success(
            new TokenResponse { Token = "jwt", RefreshToken = "rt" });

        _tokenService
            .Setup(s => s.LoginWith2FAAsync(request))
            .ReturnsAsync(expected);

        var handler = new LoginWith2FAQueryHandler(_tokenService.Object);
        var result = await handler.Handle(query, CancellationToken.None);

        result.Should().BeSameAs(expected);
    }
}
