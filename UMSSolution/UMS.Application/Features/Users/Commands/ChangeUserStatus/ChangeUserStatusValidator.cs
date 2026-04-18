namespace UMS.Application.Features.Users.Commands
{
    public class ChangeUserStatusValidator : AbstractValidator<ChangeUserStatusCommand>
    {
        public ChangeUserStatusValidator()
        {

            RuleFor(x => x.ChangeUserStatus.UserId)
                .NotEqual(0).WithMessage("User Id is required.");

            RuleFor(x => x.ChangeUserStatus.ActivateOrDeactivate)
                .NotNull().WithMessage("Status is required.");
        }
    }
}
