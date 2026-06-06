using UMS.Application.Dtos.Pagination;
using UMS.Application.Interfaces.Common;

namespace UMS.Application.Features.Categories.Queries.GetCategoriesPaged
{
    public record CategoryResponse(
        int Id,
        string Name,
        string Slug,
        int? ParentId,
        int SortOrder,
        bool IsActive,
        byte[] RowVersion
    );

    public class GetCategoriesPagedQuery : IRequest<IResponseWrapper<PagedResult<CategoryResponse>>>, IValidateMe
    {
        public PagedFilterRequest PagedFilterRequest { get; set; } = new();
    }

    public class GetCategoriesPagedQueryHandler(ICategoryService categoryService)
        : IRequestHandler<GetCategoriesPagedQuery, IResponseWrapper<PagedResult<CategoryResponse>>>
    {
        private readonly ICategoryService _categoryService = categoryService;

        public async ValueTask<IResponseWrapper<PagedResult<CategoryResponse>>> Handle(GetCategoriesPagedQuery request, CancellationToken ct)
        {
            return await _categoryService.GetCategoriesPagedQueryAsync(request.PagedFilterRequest, ct);
        }
    }
}
