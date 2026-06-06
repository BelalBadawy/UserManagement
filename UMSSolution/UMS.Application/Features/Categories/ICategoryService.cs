using UMS.Application.Dtos.Pagination;
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Categories.Queries.GetCategoriesPaged;

namespace UMS.Application.Features.Categories
{
    public interface ICategoryService
    {
        Task<IResponseWrapper<PagedResult<CategoryResponse>>> GetCategoriesPagedQueryAsync(
            PagedFilterRequest pagedFilterRequest,
            CancellationToken ct);

        Task<IResponseWrapper<List<CategoryResponse>>> GetCategoriesListAsync(
            string? searchTerm,
            bool? isActive,
            string? sortBy,
            string? sortDirection,
            CancellationToken ct);

        Task<byte[]> ExportCategoriesAsync(List<CategoryResponse> data, string format, CancellationToken ct);
    }
}
