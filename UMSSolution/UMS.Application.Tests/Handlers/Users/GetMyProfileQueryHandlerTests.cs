using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Users;
using UMS.Application.Features.Users.Models.Responses;
using UMS.Application.Features.Users.Queries.GetMyProfile;

namespace UMS.Application.Tests.Handlers.Users;

public class GetMyProfileQueryHandlerTests
{
    private readonly Mock<IUserService> _userService = new();

    [Fact]
    public async Task Handle_WhenCalled_CallsUserServiceGetMyProfile()
    {
        _userService
            .Setup(s => s.GetMyProfileAsync())
            .ReturnsAsync(ResponseWrapper<ProfileResponse>.Success(new ProfileResponse()));

        var handler = new GetMyProfileQueryHandler(_userService.Object);
        await handler.Handle(new GetMyProfileQuery(), CancellationToken.None);

        _userService.Verify(s => s.GetMyProfileAsync(), Times.Once);
    }

    [Fact]
    public async Task Handle_WhenCalled_PassesThroughProfileResult()
    {
        var profile = new ProfileResponse { Id = 1, Email = "user@test.com" };
        var expected = ResponseWrapper<ProfileResponse>.Success(profile);

        _userService
            .Setup(s => s.GetMyProfileAsync())
            .ReturnsAsync(expected);

        var handler = new GetMyProfileQueryHandler(_userService.Object);
        var result = await handler.Handle(new GetMyProfileQuery(), CancellationToken.None);

        result.Should().BeSameAs(expected);
    }
}
