using UMS.Application.Dtos.Wrappers;
using UMS.Application.Behaviors;
using UMS.Application.Features.Token.Queries;

namespace UMS.Application.Tests.Validation.Token;

public class GetRefreshTokenQueryPipelineTests
{
    [Fact]
    public async Task Handle_should_reject_invalid_refresh_token_query_before_handler_runs()
    {
        var behavior = new ValidationPipelineBehavior<GetRefreshTokenQuery, IResponseWrapper<TokenResponse>>(
            [new GetRefreshTokenQueryValidator()]);
        var handlerWasCalled = false;
        var query = new GetRefreshTokenQuery
        {
            RefreshTokenRequest = new RefreshTokenRequest
            {
                Token = string.Empty,
                RefreshToken = string.Empty
            }
        };

        var result = await behavior.Handle(
            query,
            (_, _) =>
            {
                handlerWasCalled = true;
                return new ValueTask<IResponseWrapper<TokenResponse>>(
                    ResponseWrapper<TokenResponse>.Success(new TokenResponse()));
            },
            CancellationToken.None);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().Contain(message => !string.IsNullOrWhiteSpace(message));
        handlerWasCalled.Should().BeFalse();
    }
}
