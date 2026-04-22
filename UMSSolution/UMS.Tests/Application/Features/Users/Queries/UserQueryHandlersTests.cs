using FluentAssertions;
using NSubstitute;
using NUnit.Framework;
using UMS.Application.Dtos.Pagination;
using UMS.Application.Features.Users;
using UMS.Application.Features.Users.Models.Responses;
using UMS.Application.Features.Users.Queries;
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Users.Models.Requests;

namespace UMS.Tests.Application.Features.Users.Queries
{
    [TestFixture]
    public class UserQueryHandlersTests
    {
        private IUserService _userService;

        [SetUp]
        public void SetUp()
        {
            _userService = Substitute.For<IUserService>();
        }

        [Test]
        public async Task GetAllUsers_Should_ReturnUsers_When_ServiceReturnsSuccess()
        {
            // Arrange
            var query = new GetAllUsersQuery();
            var users = new List<UserResponse> { new UserResponse { Id = 1, Email = "test@test.com" } };
            _userService.GetAllUsersAsync().Returns(ResponseWrapper<List<UserResponse>>.Success(users));
            var handler = new GetAllUsersQueryHandler(_userService);

            // Act
            var result = await handler.Handle(query, CancellationToken.None);

            // Assert
            result.IsSuccessful.Should().BeTrue();
            result.Data.Should().BeEquivalentTo(users);
        }

        [Test]
        public async Task GetUserById_Should_ReturnUser_When_Found()
        {
            // Arrange
            var query = new GetUserByIdQuery { UserId = 1 };
            var user = new UserResponse { Id = 1, Email = "test@test.com" };
            _userService.GetUserByIdAsync(1).Returns(ResponseWrapper<UserResponse>.Success(user));
            var handler = new GetUserByIdQueryHandler(_userService);

            // Act
            var result = await handler.Handle(query, CancellationToken.None);

            // Assert
            result.IsSuccessful.Should().BeTrue();
            result.Data.Should().Be(user);
        }

        [Test]
        public async Task GetUsersPaged_Should_ReturnPagedResult_When_ValidRequest()
        {
            // Arrange
            var query = new GetUsersPagedQuery { PagedFilterRequest = new PagedFilterRequest { PageNumber = 1, PageSize = 10 } };
            var pagedResult = PagedResult<UserResponse>.Create(new List<UserResponse>(), 0, 1, 10);
            _userService.GetUsersPagedQueryAsync(query.PagedFilterRequest, Arg.Any<CancellationToken>()).Returns(ResponseWrapper<PagedResult<UserResponse>>.Success(pagedResult));
            var handler = new GetUsersPagedQueryHandler(_userService);

            // Act
            var result = await handler.Handle(query, CancellationToken.None);

            // Assert
            result.IsSuccessful.Should().BeTrue();
            result.Data.Should().Be(pagedResult);
        }

        [Test]
        public async Task GetUserRoles_Should_ReturnRoles_When_Found()
        {
            // Arrange
            var query = new GetUserRolesQuery { UserId = 1 };
            var roles = new List<UserRoleViewModel> { new UserRoleViewModel { RoleName = "Admin", RoleDescription = "Admin Description" } };
            _userService.GetUserRolesAsync(1).Returns(ResponseWrapper<List<UserRoleViewModel>>.Success(roles));
            var handler = new GetUserRolesQueryHandler(_userService);

            // Act
            var result = await handler.Handle(query, CancellationToken.None);

            // Assert
            result.IsSuccessful.Should().BeTrue();
            result.Data.Should().BeEquivalentTo(roles);
        }
    }
}
