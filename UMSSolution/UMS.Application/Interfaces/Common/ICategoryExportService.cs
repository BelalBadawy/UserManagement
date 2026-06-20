using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using UMS.Application.Features.Categories.Queries.GetCategoriesPaged;

namespace UMS.Application.Interfaces.Common
{
    public interface ICategoryExportService
    {
        Task<byte[]> ExportCategoriesAsync(List<CategoryResponse> data, string format, CancellationToken ct);
    }
}
