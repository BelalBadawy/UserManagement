using FluentAssertions;
using NSubstitute;
using NUnit.Framework;
using UMS.Application.Features.Roles;
using UMS.Application.Features.Roles.Queries;
using UMS.Application.Dtos.Wrappers;

namespace UMS.Tests.Application.Features.Roles
{
    [TestFixture]
    public class RoleQueryHandlersTests
    {
        private IRoleService _roleService;

        [SetUp]
        public void SetUp()
        {
            _roleService = Substitute.For<IRoleService>();
        }

        [Test]
        public async Task GetRoles_Should_ReturnRoles_When_ServiceReturnsSuccess()
        {
            // Arrange
            var query = new GetRolesQuery();
            var roles = new List<RoleResponse> { new RoleResponse { Id = 1, Name = "Admin", Description = "Description" } };
            _roleService.GetRolesAsync().Returns(ResponseWrapper<List<RoleResponse>>.Success(roles));
            var handler = new GetRolesQueryHandler(_roleService);

            // Act
            var result = await handler.Handle(query, CancellationToken.None);

            // Assert
            result.IsSuccessful.Should().BeTrue();
            result.Data.Should().BeEquivalentTo(roles);
        }

        [Test]
        public async Task GetRoleById_Should_ReturnRole_When_Found()
        {
            // Arrange
            var query = new GetRoleByIdQuery { RoleId = 1 };
            var role = new RoleResponse { Id = 1, Name = "Admin", Description = "Description" };
            _roleService.GetRoleByIdAsync(1).Returns(ResponseWrapper<RoleResponse>.Success(role));
            var handler = new GetRoleByIdQueryHandler(_roleService);

            // Act
            var result = await handler.Handle(query, CancellationToken.None);

            // Assert
            result.IsSuccessful.Should().BeTrue();
            result.Data.Should().Be(role);
        }

        [Test]
        public async Task GetPermissions_Should_ReturnPermissions_When_Found()
        {
            // Arrange
            var query = new GetPermissionsQuery { RoleId = 1 };
            var permissions = new RoleClaimResponse 
            { 
                Role = new RoleResponse { Id = 1, Name = "Admin" },
                RoleClaims = new List<RoleClaimViewModel> { new RoleClaimViewModel { ClaimType = "Permission", ClaimValue = "Permission1" } }
            };
            _roleService.GetPermissionsAsync(1).Returns(ResponseWrapper<RoleClaimResponse>.Success(permissions));
            var handler = new GetPermissionsQueryHandler(_roleService);

            // Act
            var result = await handler.Handle(query, CancellationToken.None);

            // Assert
            result.IsSuccessful.Should().BeTrue();
            result.Data.Should().Be(permissions);
        }
    }
}
