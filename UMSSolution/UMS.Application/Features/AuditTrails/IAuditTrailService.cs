using UMS.Application.Dtos.Pagination;
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.AuditTrails.Queries.GetAuditTrailsPaged;

namespace UMS.Application.Features.AuditTrails
{
    public interface IAuditTrailService
    {
        Task<IResponseWrapper<PagedResult<AuditTrailResponse>>> GetAuditTrailsPagedQueryAsync(PagedFilterRequest pagedFilterRequest, CancellationToken ct);
    }
}
