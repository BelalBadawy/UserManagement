using UMS.Application.Dtos.Pagination;

namespace UMS.Application.Features.Categories.Queries.GetCategoriesPagedAdmin
{
    public class GetCategoriesPagedAdminQueryValidator : AbstractValidator<GetCategoriesPagedAdminQuery>
    {
        public GetCategoriesPagedAdminQueryValidator()
        {
            RuleFor(x => x.PagedFilterRequest)
                .SetValidator(new PagedFilterValidator());
        }
    }
}
