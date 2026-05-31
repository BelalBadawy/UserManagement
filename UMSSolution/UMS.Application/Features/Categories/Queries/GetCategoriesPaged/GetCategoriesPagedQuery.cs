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

    public class GetCategoriesPagedQueryHandler(
        IApplicationDbContext applicationDbContext,
        ICurrentUserService currentUserService)
        : IRequestHandler<GetCategoriesPagedQuery, IResponseWrapper<PagedResult<CategoryResponse>>>
    {
        private readonly IApplicationDbContext _applicationDbContext = applicationDbContext;
        private readonly ICurrentUserService _currentUserService = currentUserService;

        public async ValueTask<IResponseWrapper<PagedResult<CategoryResponse>>> Handle(GetCategoriesPagedQuery request, CancellationToken ct)
        {
            var pagedFilter = request.PagedFilterRequest;
            var categoriesQuery = _applicationDbContext.Categories
                .AsNoTracking();

            // 0. Status Filtering
            if (pagedFilter.IsActive.HasValue)
            {
                categoriesQuery = categoriesQuery.Where(c => c.IsActive == pagedFilter.IsActive.Value);
            }
            else
            {
                // For anonymous or non-privileged requests, show only active categories.
                // For authenticated admins/managers (who have read permission), show all by default if no filter is set.
                if (!_currentUserService.IsAuthenticated() || !_currentUserService.HasClaim("permission", "Permission.Product.Categories.Read"))
                {
                    categoriesQuery = categoriesQuery.Where(c => c.IsActive);
                }
            }

            // 1. Filtering
            if (!string.IsNullOrWhiteSpace(pagedFilter.SearchTerm))
            {
                var term = pagedFilter.SearchTerm.Trim();
                var pattern = $"%{term}%";
                categoriesQuery = categoriesQuery.Where(c =>
                    EF.Functions.Like(c.Name, pattern) ||
                    EF.Functions.Like(c.Slug, pattern));
            }

            // 2. Sorting
            categoriesQuery = pagedFilter.SortBy?.ToLower() switch
            {
                "name" => pagedFilter.SortDirection == "desc"
                    ? categoriesQuery.OrderByDescending(c => c.Name)
                    : categoriesQuery.OrderBy(c => c.Name),
                "slug" => pagedFilter.SortDirection == "desc"
                    ? categoriesQuery.OrderByDescending(c => c.Slug)
                    : categoriesQuery.OrderBy(c => c.Slug),
                "sortorder" => pagedFilter.SortDirection == "desc"
                    ? categoriesQuery.OrderByDescending(c => c.SortOrder)
                    : categoriesQuery.OrderBy(c => c.SortOrder),
                "id" => pagedFilter.SortDirection == "desc"
                    ? categoriesQuery.OrderByDescending(c => c.Id)
                    : categoriesQuery.OrderBy(c => c.Id),
                _ => pagedFilter.SortDirection == "desc"
                    ? categoriesQuery.OrderByDescending(c => c.SortOrder).ThenBy(c => c.Name)
                    : categoriesQuery.OrderBy(c => c.SortOrder).ThenBy(c => c.Name)
            };

            // 3. Pagination
            var totalCount = await categoriesQuery.CountAsync(ct);

            var categories = await categoriesQuery
                .Skip((pagedFilter.PageNumber - 1) * pagedFilter.PageSize)
                .Take(pagedFilter.PageSize)
                .Select(c => new CategoryResponse(
                    c.Id,
                    c.Name,
                    c.Slug,
                    c.ParentId,
                    c.SortOrder,
                    c.IsActive,
                    c.RowVersion
                ))
                .ToListAsync(ct);

            var pagedResult = PagedResult<CategoryResponse>.Create(
                categories,
                totalCount,
                pagedFilter.PageNumber,
                pagedFilter.PageSize);

            return ResponseWrapper<PagedResult<CategoryResponse>>.Success(pagedResult);
        }
    }
}
