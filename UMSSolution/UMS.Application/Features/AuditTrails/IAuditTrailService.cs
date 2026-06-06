using UMS.Application.Dtos.Pagination;
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.AuditTrails.Queries.GetAuditTrailsPaged;

namespace UMS.Application.Features.AuditTrails
{
    public interface IAuditTrailService
    {
        Task<IResponseWrapper<PagedResult<AuditTrailResponse>>> GetAuditTrailsPagedQueryAsync(
            PagedFilterRequest pagedFilterRequest,
            string? tableName,
            string? entityId,
            string? actionTypes,
            string? fromDate,
            string? toDate,
            int? userId,
            CancellationToken ct);

        Task<IResponseWrapper<List<AuditTrailResponse>>> GetAuditTrailsListAsync(
            string? tableName,
            string? entityId,
            string? actionTypes,
            string? fromDate,
            string? toDate,
            int? userId,
            CancellationToken ct);

        Task<byte[]> ExportAuditTrailsAsync(List<AuditTrailResponse> data, string format, CancellationToken ct);
    }
}
