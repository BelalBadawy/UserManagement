using FluentValidation;
using Mediator;
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Behaviors;
using UMS.Application.Interfaces.Common;

namespace UMS.Application.Tests.Behaviors;

public class ValidationPipelineBehaviorTests
{
    [Fact]
    public async Task Handle_should_fail_when_any_validator_fails_even_if_another_validator_passes()
    {
        var validators = new IValidator<PipelineTestRequest>[]
        {
            new PassingPipelineTestValidator(),
            new FailingPipelineTestValidator()
        };
        var behavior = new ValidationPipelineBehavior<PipelineTestRequest, IResponseWrapper>(validators);
        var handlerWasCalled = false;

        var result = await behavior.Handle(
            new PipelineTestRequest { Name = "invalid" },
            (_, _) =>
            {
                handlerWasCalled = true;
                return new ValueTask<IResponseWrapper>(ResponseWrapper.Success("Handler reached."));
            },
            CancellationToken.None);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().Contain("Name must be 'expected'.");
        handlerWasCalled.Should().BeFalse();
    }

    private sealed class PipelineTestRequest : IRequest<IResponseWrapper>, IValidateMe
    {
        public string Name { get; init; } = string.Empty;
    }

    private sealed class PassingPipelineTestValidator : AbstractValidator<PipelineTestRequest>
    {
        public PassingPipelineTestValidator()
        {
            RuleFor(x => x.Name).NotEmpty();
        }
    }

    private sealed class FailingPipelineTestValidator : AbstractValidator<PipelineTestRequest>
    {
        public FailingPipelineTestValidator()
        {
            RuleFor(x => x.Name)
                .Equal("expected")
                .WithMessage("Name must be 'expected'.");
        }
    }
}
