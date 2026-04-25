using UMS.Application.Dtos.Pagination;
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Users;
using UMS.Application.Features.Users.Models.Responses;
using UMS.Application.Features.Users.Queries;
using UMS.Application.Tests.Fixtures;

namespace UMS.Application.Tests.Handlers.Users;

public class GetUsersPagedQueryHandlerTests
{
    private readonly Mock<IUserService> _userService = new();

    [Fact]
    public async Task Handle_should_return_paged_users_when_service_finds_matches()
    {
        var request = TestData.PagedFilterRequest();
        var pagedUsers = PagedResult<UserResponse>.Create(
            [TestData.UserResponse(1), TestData.UserResponse(2)],
            totalCount: 8,
            pageNumber: request.PageNumber,
            pageSize: request.PageSize);
        var query = new GetUsersPagedQuery { PagedFilterRequest = request };
        var expected = ResponseWrapper<PagedResult<UserResponse>>.Success(pagedUsers);

        _userService
            .Setup(service => service.GetUsersPagedQueryAsync(request, It.IsAny<CancellationToken>()))
            .ReturnsAsync(expected);

        var handler = new GetUsersPagedQueryHandler(_userService.Object);

        var result = await handler.Handle(query, CancellationToken.None);

        result.IsSuccessful.Should().BeTrue();
        result.Data.Should().BeEquivalentTo(pagedUsers);
        _userService.Verify(service => service.GetUsersPagedQueryAsync(request, CancellationToken.None), Times.Once);
    }

    [Fact]
    public async Task Handle_should_return_failure_when_service_cannot_load_paged_users()
    {
        var request = TestData.PagedFilterRequest();
        var query = new GetUsersPagedQuery { PagedFilterRequest = request };
        var expected = ResponseWrapper<PagedResult<UserResponse>>.Fail("Users not found.", 404);

        _userService
            .Setup(service => service.GetUsersPagedQueryAsync(request, It.IsAny<CancellationToken>()))
            .ReturnsAsync(expected);

        var handler = new GetUsersPagedQueryHandler(_userService.Object);

        var result = await handler.Handle(query, CancellationToken.None);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().Contain("Users not found.");
        result.StatusCode.Should().Be(404);
        _userService.Verify(service => service.GetUsersPagedQueryAsync(request, CancellationToken.None), Times.Once);
    }
}
