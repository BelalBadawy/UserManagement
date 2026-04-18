using UMS.Application.Dtos.Pagination;
using UMS.Application.Features.Categories.Queries.GetCategoriesPaged;

namespace UMS.Application.Features.Categories.Queries.GetCategoriesPaged
{
    public class GetCategoriesPagedQueryValidator : AbstractValidator<GetCategoriesPagedQuery>
    {
        public GetCategoriesPagedQueryValidator()
        {
            RuleFor(x => x.PagedFilterRequest)
                .SetValidator(new PagedFilterValidator());
        }
    }
}
