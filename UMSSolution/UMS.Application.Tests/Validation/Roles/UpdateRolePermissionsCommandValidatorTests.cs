using UMS.Application.Features.Roles.Commands;
using UMS.Application.Tests.Fixtures;

namespace UMS.Application.Tests.Validation.Roles;

public class UpdateRolePermissionsCommandValidatorTests
{
    private readonly UpdateRolePermissionsCommandValidator _validator = new();

    [Fact]
    public void Validate_should_pass_for_well_formed_request()
    {
        var command = new UpdateRolePermissionsCommand
        {
            UpdateRoleClaims = TestData.UpdateRoleClaimsRequest()
        };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeTrue();
    }

    [Fact]
    public void Validate_should_fail_when_role_id_is_not_positive()
    {
        var request = TestData.UpdateRoleClaimsRequest(roleId: 0);
        var command = new UpdateRolePermissionsCommand { UpdateRoleClaims = request };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(error => error.PropertyName == "UpdateRoleClaims.RoleId");
    }

    [Fact]
    public void Validate_should_fail_when_role_claim_contains_missing_required_fields()
    {
        var request = TestData.UpdateRoleClaimsRequest();
        request.RoleClaims =
        [
            new() { ClaimType = string.Empty, ClaimValue = string.Empty, Description = string.Empty }
        ];
        var command = new UpdateRolePermissionsCommand { UpdateRoleClaims = request };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(error => error.PropertyName.StartsWith("UpdateRoleClaims.RoleClaims["));
    }
}
