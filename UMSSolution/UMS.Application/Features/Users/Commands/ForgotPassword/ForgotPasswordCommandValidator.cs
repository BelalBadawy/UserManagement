namespace UMS.Application.Features.Users.Commands
{
    public class ForgotPasswordCommandValidatorValidator : AbstractValidator<ForgotPasswordCommand>
    {
        public ForgotPasswordCommandValidatorValidator()
        {
            RuleFor(x => x.Email)
                .NotEmpty().WithMessage("Email is required.")
                .EmailAddress().WithMessage("Invalid email format.")
                .MaximumLength(255).WithMessage("Email must not exceed 255 characters.");
        }
    }
}
