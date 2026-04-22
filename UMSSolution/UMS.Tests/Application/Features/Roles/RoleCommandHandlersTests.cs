using FluentAssertions;
using NSubstitute;
using NUnit.Framework;
using UMS.Application.Features.Roles;
using UMS.Application.Features.Roles.Commands;
using UMS.Application.Dtos.Wrappers;

namespace UMS.Tests.Application.Features.Roles
{
    [TestFixture]
    public class RoleCommandHandlersTests
    {
        private IRoleService _roleService;

        [SetUp]
        public void SetUp()
        {
            _roleService = Substitute.For<IRoleService>();
        }

        [Test]
        public async Task CreateRole_Should_ReturnSuccess_When_ServiceReturnsSuccess()
        {
            // Arrange
            var command = new CreateRoleCommand { CreateRole = new CreateRoleRequest { Name = "Admin" } };
            _roleService.CreateRoleAsync(command.CreateRole).Returns(ResponseWrapper.Success());
            var handler = new CreateRoleCommandHandler(_roleService);

            // Act
            var result = await handler.Handle(command, CancellationToken.None);

            // Assert
            result.IsSuccessful.Should().BeTrue();
            await _roleService.Received(1).CreateRoleAsync(command.CreateRole);
        }

        [Test]
        public async Task UpdateRole_Should_ReturnSuccess_When_ServiceReturnsSuccess()
        {
            // Arrange
            var command = new UpdateRoleCommand { UpdateRole = new UpdateRoleRequest { RoleId = 1, Name = "Admin" } };
            _roleService.UpdateRoleAsync(command.UpdateRole).Returns(ResponseWrapper.Success());
            var handler = new UpdateRoleCommandHandler(_roleService);

            // Act
            var result = await handler.Handle(command, CancellationToken.None);

            // Assert
            result.IsSuccessful.Should().BeTrue();
            await _roleService.Received(1).UpdateRoleAsync(command.UpdateRole);
        }

        [Test]
        public async Task DeleteRole_Should_ReturnSuccess_When_ServiceReturnsSuccess()
        {
            // Arrange
            var command = new DeleteRoleCommand { RoleId = 1 };
            _roleService.DeleteRoleAsync(1).Returns(ResponseWrapper.Success());
            var handler = new DeleteRoleCommandHandler(_roleService);

            // Act
            var result = await handler.Handle(command, CancellationToken.None);

            // Assert
            result.IsSuccessful.Should().BeTrue();
            await _roleService.Received(1).DeleteRoleAsync(1);
        }

        [Test]
        public async Task UpdateRolePermissions_Should_ReturnSuccess_When_ServiceReturnsSuccess()
        {
            // Arrange
            var command = new UpdateRolePermissionsCommand { UpdateRoleClaims = new UpdateRoleClaimsRequest { RoleId = 1, RoleClaims = new() } };
            _roleService.UpdateRolePermissionsAsync(command.UpdateRoleClaims).Returns(ResponseWrapper.Success());
            var handler = new UpdateRolePermissionsCommandHandler(_roleService);

            // Act
            var result = await handler.Handle(command, CancellationToken.None);

            // Assert
            result.IsSuccessful.Should().BeTrue();
            await _roleService.Received(1).UpdateRolePermissionsAsync(command.UpdateRoleClaims);
        }
    }
}
