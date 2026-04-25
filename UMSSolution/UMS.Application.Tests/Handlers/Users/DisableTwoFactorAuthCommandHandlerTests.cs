using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Users;
using UMS.Application.Features.Users.Commands.DisableTwoFactorAuth;

namespace UMS.Application.Tests.Handlers.Users;

public class DisableTwoFactorAuthCommandHandlerTests
{
    private readonly Mock<IUserService> _userService = new();

    [Fact]
    public async Task Handle_WhenCalled_CallsUserServiceDisableWithCorrectRequest()
    {
        var request = new DisableTwoFactorAuthRequest { Password = "Pass@123" };
        var command = new DisableTwoFactorAuthCommand { Request = request };

        _userService
            .Setup(s => s.DisableTwoFactorAuthAsync(request))
            .ReturnsAsync(ResponseWrapper.Success("Two-factor authentication disabled."));

        var handler = new DisableTwoFactorAuthCommandHandler(_userService.Object);
        await handler.Handle(command, CancellationToken.None);

        _userService.Verify(s => s.DisableTwoFactorAuthAsync(request), Times.Once);
    }

    [Fact]
    public async Task Handle_WhenCalled_PassesThroughServiceResult()
    {
        var request = new DisableTwoFactorAuthRequest { Password = "Pass@123" };
        var command = new DisableTwoFactorAuthCommand { Request = request };
        var expected = ResponseWrapper.Success("Two-factor authentication disabled.");

        _userService
            .Setup(s => s.DisableTwoFactorAuthAsync(request))
            .ReturnsAsync(expected);

        var handler = new DisableTwoFactorAuthCommandHandler(_userService.Object);
        var result = await handler.Handle(command, CancellationToken.None);

        result.Should().BeSameAs(expected);
    }
}
