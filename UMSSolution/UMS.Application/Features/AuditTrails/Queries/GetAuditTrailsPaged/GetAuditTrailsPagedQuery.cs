using Mediator;
using UMS.Application.Dtos.Pagination;
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Interfaces.Common;

namespace UMS.Application.Features.AuditTrails.Queries.GetAuditTrailsPaged
{
    public record AuditTrailResponse(
        int Id,
        int? UserId,
        string? UserEmail,
        string? IpAddress,
        string Type,
        string? TableName,
        DateTime DateTime,
        string? OldValues,
        string? NewValues,
        string? AffectedColumns,
        string? PrimaryKey
    );

    public class GetAuditTrailsPagedQuery : IRequest<IResponseWrapper<PagedResult<AuditTrailResponse>>>, IValidateMe
    {
        public PagedFilterRequest PagedFilterRequest { get; set; } = new();
        public string? TableName { get; set; }
        public string? EntityId { get; set; }
        public string? ActionTypes { get; set; }
        public string? FromDate { get; set; }
        public string? ToDate { get; set; }
        public int? UserId { get; set; }
    }

    public class GetAuditTrailsPagedQueryHandler(IAuditTrailService auditTrailService)
        : IRequestHandler<GetAuditTrailsPagedQuery, IResponseWrapper<PagedResult<AuditTrailResponse>>>
    {
        private readonly IAuditTrailService _auditTrailService = auditTrailService;

        public async ValueTask<IResponseWrapper<PagedResult<AuditTrailResponse>>> Handle(GetAuditTrailsPagedQuery request, CancellationToken ct)
        {
            return await _auditTrailService.GetAuditTrailsPagedQueryAsync(
                request.PagedFilterRequest,
                request.TableName,
                request.EntityId,
                request.ActionTypes,
                request.FromDate,
                request.ToDate,
                request.UserId,
                ct);
        }
    }
}
