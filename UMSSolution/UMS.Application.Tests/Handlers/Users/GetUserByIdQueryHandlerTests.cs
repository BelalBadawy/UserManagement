using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Users;
using UMS.Application.Features.Users.Models.Responses;
using UMS.Application.Features.Users.Queries;
using UMS.Application.Tests.Fixtures;

namespace UMS.Application.Tests.Handlers.Users;

public class GetUserByIdQueryHandlerTests
{
    private readonly Mock<IUserService> _userService = new();

    [Fact]
    public async Task Handle_should_return_user_when_service_finds_match()
    {
        var user = TestData.UserResponse(15);
        var query = new GetUserByIdQuery { UserId = user.Id };
        var expected = ResponseWrapper<UserResponse>.Success(user);

        _userService
            .Setup(service => service.GetUserByIdAsync(user.Id))
            .ReturnsAsync(expected);

        var handler = new GetUserByIdQueryHandler(_userService.Object);

        var result = await handler.Handle(query, CancellationToken.None);

        result.IsSuccessful.Should().BeTrue();
        result.Data.Should().BeEquivalentTo(user);
        _userService.Verify(service => service.GetUserByIdAsync(user.Id), Times.Once);
    }

    [Fact]
    public async Task Handle_should_return_failure_when_service_cannot_find_user()
    {
        const int missingUserId = 404;
        var query = new GetUserByIdQuery { UserId = missingUserId };
        var expected = ResponseWrapper<UserResponse>.Fail("User not found.", 404);

        _userService
            .Setup(service => service.GetUserByIdAsync(missingUserId))
            .ReturnsAsync(expected);

        var handler = new GetUserByIdQueryHandler(_userService.Object);

        var result = await handler.Handle(query, CancellationToken.None);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().Contain("User not found.");
        result.StatusCode.Should().Be(404);
    }
}
