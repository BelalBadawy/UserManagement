using SampleApp.Application.Dtos.Pagination;

namespace SampleApp.Application.Features.Users.Queries
{
    public class GetUsersPagedQueryValidator : AbstractValidator<GetUsersPagedQuery>
    {
        public GetUsersPagedQueryValidator()
        {
            RuleFor(x => x.PagedFilterRequest)
                .SetValidator(new PagedFilterValidator());

            RuleFor(x => x.PagedFilterRequest.SortBy)
                .Must(field => string.IsNullOrEmpty(field) || new[] { "fullname", "email", "id" }.Contains(field))
                .WithMessage("Invalid SortBy value");
        }
    }
}