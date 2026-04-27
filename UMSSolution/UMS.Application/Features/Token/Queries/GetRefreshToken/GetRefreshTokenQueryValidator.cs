using UMS.Application.Features.Token.Queries;

namespace UMS.Application.Features.Token.Queries
{
    public class GetRefreshTokenQueryValidator : AbstractValidator<GetRefreshTokenQuery>
    {
        public GetRefreshTokenQueryValidator()
        {
            RuleFor(u => u.RefreshTokenRequest.Token)
                .NotEmpty();

            RuleFor(u => u.RefreshTokenRequest.RefreshToken)
                .NotEmpty();
        }
    }
}
