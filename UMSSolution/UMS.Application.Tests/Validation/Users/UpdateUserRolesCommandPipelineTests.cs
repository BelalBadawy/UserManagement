using UMS.Application.Dtos.Wrappers;
using UMS.Application.Behaviors;
using UMS.Application.Features.Users.Commands;

namespace UMS.Application.Tests.Validation.Users;

public class UpdateUserRolesCommandPipelineTests
{
    [Fact]
    public async Task Handle_should_reject_invalid_update_user_roles_command_before_handler_runs()
    {
        var behavior = new ValidationPipelineBehavior<UpdateUserRolesCommand, IResponseWrapper>(
            [new UpdateUserRolesCommandValidator()]);
        var handlerWasCalled = false;
        var command = new UpdateUserRolesCommand
        {
            UpdateUserRoles = new UpdateUserRolesRequest
            {
                UserId = 0,
                Roles = []
            }
        };

        var result = await behavior.Handle(
            command,
            (_, _) =>
            {
                handlerWasCalled = true;
                return new ValueTask<IResponseWrapper>(ResponseWrapper.Success("Handler reached."));
            },
            CancellationToken.None);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().Contain("User ID is required.");
        result.Messages.Should().Contain("At least one role must be assigned.");
        handlerWasCalled.Should().BeFalse();
    }
}
