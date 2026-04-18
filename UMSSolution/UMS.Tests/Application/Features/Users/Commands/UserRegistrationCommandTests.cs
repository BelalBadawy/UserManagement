using FluentAssertions;
using NSubstitute;
using NUnit.Framework;
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Users;
using UMS.Application.Features.Users.Commands;
using UMS.Application.Features.Users.Models.Responses;

namespace UMS.Tests.Application.Features.Users.Commands
{
    [TestFixture]
    public class UserRegistrationCommandTests
    {
        private IUserService _userService;
        private UserRegistrationCommandHandler _handler;

        [SetUp]
        public void SetUp()
        {
            _userService = Substitute.For<IUserService>();
            _handler = new UserRegistrationCommandHandler(_userService);
        }

        [Test]
        public async Task Handle_Should_ReturnSuccess_When_ValidRequest()
        {
            // Arrange
            var command = new UserRegistrationCommand
            {
                UserRegistration = new UserRegistrationRequest
                {
                    Email = "test@example.com",
                    FullName = "Test User",
                    Password = "Password123!",
                    ConfirmPassword = "Password123!",
                    PhoneNumber = "1234567890"
                }
            };

            var expectedResponse = await ResponseWrapper.SuccessAsync("User Registered Successfully");
            _userService.RegisterUserAsync(command.UserRegistration).Returns(expectedResponse);

            // Act
            var result = await _handler.Handle(command, CancellationToken.None);

            // Assert
            result.Should().NotBeNull();
            result.IsSuccessful.Should().BeTrue();
            await _userService.Received(1).RegisterUserAsync(Arg.Any<UserRegistrationRequest>());
        }

        [Test]
        public async Task Handle_Should_ReturnFail_When_EmailAlreadyExists()
        {
            // Arrange
            var command = new UserRegistrationCommand
            {
                UserRegistration = new UserRegistrationRequest
                {
                    Email = "existing@example.com",
                    FullName = "Test User",
                    Password = "Password123!",
                    ConfirmPassword = "Password123!",
                    PhoneNumber = "1234567890"
                }
            };

            var expectedResponse = await ResponseWrapper.FailAsync("Email already exists");
            _userService.RegisterUserAsync(command.UserRegistration).Returns(expectedResponse);

            // Act
            var result = await _handler.Handle(command, CancellationToken.None);

            // Assert
            result.Should().NotBeNull();
            result.IsSuccessful.Should().BeFalse();
            result.Messages.Should().Contain("Email already exists");
            await _userService.Received(1).RegisterUserAsync(Arg.Any<UserRegistrationRequest>());
        }
    }
}
