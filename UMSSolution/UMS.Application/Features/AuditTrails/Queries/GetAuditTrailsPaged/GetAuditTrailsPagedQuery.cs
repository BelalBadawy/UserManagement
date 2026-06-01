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
    }

    public class GetAuditTrailsPagedQueryHandler(IAuditTrailService auditTrailService)
        : IRequestHandler<GetAuditTrailsPagedQuery, IResponseWrapper<PagedResult<AuditTrailResponse>>>
    {
        private readonly IAuditTrailService _auditTrailService = auditTrailService;

        public async ValueTask<IResponseWrapper<PagedResult<AuditTrailResponse>>> Handle(GetAuditTrailsPagedQuery request, CancellationToken ct)
        {
            return await _auditTrailService.GetAuditTrailsPagedQueryAsync(request.PagedFilterRequest, ct);
        }
    }
}
