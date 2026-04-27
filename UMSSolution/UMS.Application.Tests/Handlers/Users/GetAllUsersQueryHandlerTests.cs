using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Users;
using UMS.Application.Features.Users.Models.Responses;
using UMS.Application.Features.Users.Queries;
using UMS.Application.Tests.Fixtures;

namespace UMS.Application.Tests.Handlers.Users;

public class GetAllUsersQueryHandlerTests
{
    private readonly Mock<IUserService> _userService = new();

    [Fact]
    public async Task Handle_should_return_users_when_service_finds_matches()
    {
        List<UserResponse> users =
        [
            TestData.UserResponse(1),
            TestData.UserResponse(2)
        ];
        var query = new GetAllUsersQuery();
        var expected = ResponseWrapper<List<UserResponse>>.Success(users);

        _userService
            .Setup(service => service.GetAllUsersAsync())
            .ReturnsAsync(expected);

        var handler = new GetAllUsersQueryHandler(_userService.Object);

        var result = await handler.Handle(query, CancellationToken.None);

        result.IsSuccessful.Should().BeTrue();
        result.Data.Should().BeEquivalentTo(users);
        _userService.Verify(service => service.GetAllUsersAsync(), Times.Once);
    }

    [Fact]
    public async Task Handle_should_return_failure_when_service_cannot_load_users()
    {
        var query = new GetAllUsersQuery();
        var expected = ResponseWrapper<List<UserResponse>>.Fail("Users not found.", 404);

        _userService
            .Setup(service => service.GetAllUsersAsync())
            .ReturnsAsync(expected);

        var handler = new GetAllUsersQueryHandler(_userService.Object);

        var result = await handler.Handle(query, CancellationToken.None);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().Contain("Users not found.");
        result.StatusCode.Should().Be(404);
    }
}
