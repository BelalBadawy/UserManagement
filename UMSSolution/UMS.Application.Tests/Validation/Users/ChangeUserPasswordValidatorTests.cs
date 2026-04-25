using UMS.Application.Features.Users.Commands;
using UMS.Application.Tests.Fixtures;

namespace UMS.Application.Tests.Validation.Users;

public class ChangeUserPasswordValidatorTests
{
    private readonly ChangeUserPasswordValidator _validator = new();

    [Fact]
    public void Validate_should_pass_for_well_formed_request()
    {
        var command = new ChangeUserPasswordCommand
        {
            ChangePassword = TestData.ChangePasswordRequest()
        };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeTrue();
    }

    [Fact]
    public void Validate_should_fail_when_user_id_is_missing()
    {
        var request = TestData.ChangePasswordRequest(userId: 0);
        var command = new ChangeUserPasswordCommand { ChangePassword = request };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(error => error.PropertyName == "ChangePassword.UserId");
    }

    [Fact]
    public void Validate_should_fail_when_confirmed_password_does_not_match()
    {
        var request = TestData.ChangePasswordRequest();
        request.ConfirmedNewPassword = "Different@123";
        var command = new ChangeUserPasswordCommand { ChangePassword = request };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(error => error.PropertyName == "ChangePassword.ConfirmedNewPassword");
    }
}
