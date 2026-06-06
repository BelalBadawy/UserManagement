using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using Mediator;
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Categories.Queries.GetCategoriesPaged;

namespace UMS.Application.Features.Categories.Queries.ExportCategories
{
    public class ExportCategoriesQuery : IQuery<IResponseWrapper<byte[]>>
    {
        public string? SearchTerm { get; set; }
        public bool? IsActive { get; set; }
        public string? SortBy { get; set; }
        public string? SortDirection { get; set; }
        public string ExportFormat { get; set; } = "excel";
    }

    public class ExportCategoriesQueryHandler(ICategoryService categoryService)
        : IQueryHandler<ExportCategoriesQuery, IResponseWrapper<byte[]>>
    {
        private readonly ICategoryService _categoryService = categoryService;

        public async ValueTask<IResponseWrapper<byte[]>> Handle(ExportCategoriesQuery request, CancellationToken ct)
        {
            var listResponse = await _categoryService.GetCategoriesListAsync(
                request.SearchTerm,
                request.IsActive,
                request.SortBy,
                request.SortDirection,
                ct);

            if (!listResponse.IsSuccessful || listResponse.Data == null)
            {
                return ResponseWrapper<byte[]>.Fail(
                    listResponse.Messages ?? new List<string> { "Failed to retrieve categories for export." },
                    listResponse.StatusCode);
            }

            var fileBytes = await _categoryService.ExportCategoriesAsync(listResponse.Data, request.ExportFormat, ct);

            return ResponseWrapper<byte[]>.Success(fileBytes);
        }
    }
}
