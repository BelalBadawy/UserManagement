using FluentAssertions;
using NSubstitute;
using NUnit.Framework;
using UMS.Application.Features.Users;
using UMS.Application.Features.Users.Commands;
using UMS.Application.Features.Users.Models.Requests;
using UMS.Application.Dtos.Wrappers;

namespace UMS.Tests.Application.Features.Users.Commands
{
    [TestFixture]
    public class UserCommandHandlersTests
    {
        private IUserService _userService;

        [SetUp]
        public void SetUp()
        {
            _userService = Substitute.For<IUserService>();
        }

        [Test]
        public async Task UpdateUser_Should_ReturnSuccess_When_ServiceReturnsSuccess()
        {
            // Arrange
            var command = new UpdateUserCommand { UpdateUser = new UpdateUserRequest { UserId = 1, FullName = "Updated" } };
            _userService.UpdateUserAsync(command.UpdateUser).Returns(ResponseWrapper.Success());
            var handler = new UpdateUserCommandHandler(_userService);

            // Act
            var result = await handler.Handle(command, CancellationToken.None);

            // Assert
            result.IsSuccessful.Should().BeTrue();
            await _userService.Received(1).UpdateUserAsync(command.UpdateUser);
        }

        [Test]
        public async Task ChangePassword_Should_ReturnSuccess_When_ServiceReturnsSuccess()
        {
            // Arrange
            var command = new ChangeUserPasswordCommand { ChangePassword = new ChangePasswordRequest { CurrentPassword = "Old", NewPassword = "New", ConfirmedNewPassword = "New" } };
            _userService.ChangeUserPasswordAsync(command.ChangePassword).Returns(ResponseWrapper.Success());
            var handler = new ChangeUserPasswordCommandHandler(_userService);

            // Act
            var result = await handler.Handle(command, CancellationToken.None);

            // Assert
            result.IsSuccessful.Should().BeTrue();
            await _userService.Received(1).ChangeUserPasswordAsync(command.ChangePassword);
        }

        [Test]
        public async Task ChangeStatus_Should_ReturnSuccess_When_ServiceReturnsSuccess()
        {
            // Arrange
            var command = new ChangeUserStatusCommand { ChangeUserStatus = new ChangeUserStatusRequest { UserId = 1, ActivateOrDeactivate = true } };
            _userService.ChangeUserStatusAsync(command.ChangeUserStatus).Returns(ResponseWrapper.Success());
            var handler = new ChangeUserStatusCommandHandler(_userService);

            // Act
            var result = await handler.Handle(command, CancellationToken.None);

            // Assert
            result.IsSuccessful.Should().BeTrue();
            await _userService.Received(1).ChangeUserStatusAsync(command.ChangeUserStatus);
        }

        [Test]
        public async Task ForgotPassword_Should_ReturnSuccess_When_ServiceReturnsSuccess()
        {
            // Arrange
            var command = new ForgotPasswordCommand { Email = "test@test.com" };
            _userService.ForgotPasswordAsync("test@test.com").Returns(ResponseWrapper.Success());
            var handler = new ForgotPasswordCommandHandler(_userService);

            // Act
            var result = await handler.Handle(command, CancellationToken.None);

            // Assert
            result.IsSuccessful.Should().BeTrue();
            await _userService.Received(1).ForgotPasswordAsync("test@test.com");
        }

        [Test]
        public async Task UpdateUserRoles_Should_ReturnSuccess_When_ServiceReturnsSuccess()
        {
            // Arrange
            var command = new UpdateUserRolesCommand { UpdateUserRoles = new UpdateUserRolesRequest { UserId = 1, Roles = new() } };
            _userService.UpdateUserRolesAsync(command.UpdateUserRoles, Arg.Any<CancellationToken>()).Returns(ResponseWrapper.Success());
            var handler = new UpdateUserRolesCommandHandler(_userService);

            // Act
            var result = await handler.Handle(command, CancellationToken.None);

            // Assert
            result.IsSuccessful.Should().BeTrue();
            await _userService.Received(1).UpdateUserRolesAsync(command.UpdateUserRoles, Arg.Any<CancellationToken>());
        }

        [Test]
        public async Task ResetPassword_Should_ReturnSuccess_When_ServiceReturnsSuccess()
        {
            // Arrange
            var command = new ResetPasswordCommand { ResetPasswordRequest = new ResetPasswordRequest { Email = "test@test.com", Token = "token", Password = "New", ConfirmPassword = "New" } };
            _userService.ResetPasswordAsync(command.ResetPasswordRequest).Returns(ResponseWrapper.Success());
            var handler = new ResetPasswordCommandHandler(_userService);

            // Act
            var result = await handler.Handle(command, CancellationToken.None);

            // Assert
            result.IsSuccessful.Should().BeTrue();
            await _userService.Received(1).ResetPasswordAsync(command.ResetPasswordRequest);
        }
    }
}
