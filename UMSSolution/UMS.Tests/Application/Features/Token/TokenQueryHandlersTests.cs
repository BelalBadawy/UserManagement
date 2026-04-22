using FluentAssertions;
using NSubstitute;
using NUnit.Framework;
using UMS.Application.Features.Token;
using UMS.Application.Features.Token.Queries;
using UMS.Application.Dtos.Wrappers;

namespace UMS.Tests.Application.Features.Token
{
    [TestFixture]
    public class TokenQueryHandlersTests
    {
        private ITokenService _tokenService;

        [SetUp]
        public void SetUp()
        {
            _tokenService = Substitute.For<ITokenService>();
        }

        [Test]
        public async Task GetToken_Should_ReturnToken_When_ValidRequest()
        {
            // Arrange
            var query = new GetTokenQuery { TokenRequest = new TokenRequest { Email = "user", Password = "pass" } };
            var token = "access";
            var refreshToken = "refresh";
            var expiry = DateTime.Now.AddDays(7);
            var tokenResponse = new TokenResponse { Token = token, RefreshToken = refreshToken, RefreshTokenExpiryTime = expiry };
            var response = ResponseWrapper<TokenResponse>.Success(tokenResponse);
            _tokenService.GetTokenAsync(query.TokenRequest).Returns(response);
            var handler = new GetTokenQueryHandler(_tokenService);

            // Act
            var result = await handler.Handle(query, CancellationToken.None);

            // Assert
            result.IsSuccessful.Should().BeTrue();
            result.Data.Should().Be(tokenResponse);
            await _tokenService.Received(1).GetTokenAsync(query.TokenRequest);
        }

        [Test]
        public async Task GetRefreshToken_Should_ReturnNewToken_When_ValidRequest()
        {
            // Arrange
            var query = new GetRefreshTokenQuery { RefreshTokenRequest = new RefreshTokenRequest { Token = "access", RefreshToken = "refresh" } };
            var token = "new-access";
            var refreshToken = "new-refresh";
            var expiry = DateTime.Now.AddDays(7);
            var tokenResponse = new TokenResponse { Token = token, RefreshToken = refreshToken, RefreshTokenExpiryTime = expiry };
            var response = ResponseWrapper<TokenResponse>.Success(tokenResponse);
            _tokenService.GetRefreshTokenAsync(query.RefreshTokenRequest).Returns(response);
            var handler = new GetRefreshTokenQueryHandler(_tokenService);

            // Act
            var result = await handler.Handle(query, CancellationToken.None);

            // Assert
            result.IsSuccessful.Should().BeTrue();
            result.Data.Should().Be(response);
            await _tokenService.Received(1).GetRefreshTokenAsync(query.RefreshTokenRequest);
        }
    }
}
