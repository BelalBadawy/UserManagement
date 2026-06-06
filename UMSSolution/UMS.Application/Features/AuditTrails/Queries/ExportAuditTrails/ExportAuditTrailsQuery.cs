using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using Mediator;
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.AuditTrails.Queries.GetAuditTrailsPaged;

namespace UMS.Application.Features.AuditTrails.Queries.ExportAuditTrails
{
    public class ExportAuditTrailsQuery : IQuery<IResponseWrapper<byte[]>>
    {
        public string? TableName { get; set; }
        public string? EntityId { get; set; }
        public string? ActionTypes { get; set; }
        public string? FromDate { get; set; }
        public string? ToDate { get; set; }
        public int? UserId { get; set; }
        public string ExportFormat { get; set; } = "excel";
    }

    public class ExportAuditTrailsQueryHandler(IAuditTrailService auditTrailService)
        : IQueryHandler<ExportAuditTrailsQuery, IResponseWrapper<byte[]>>
    {
        private readonly IAuditTrailService _auditTrailService = auditTrailService;

        public async ValueTask<IResponseWrapper<byte[]>> Handle(ExportAuditTrailsQuery request, CancellationToken ct)
        {
            var listResponse = await _auditTrailService.GetAuditTrailsListAsync(
                request.TableName,
                request.EntityId,
                request.ActionTypes,
                request.FromDate,
                request.ToDate,
                request.UserId,
                ct);

            if (!listResponse.IsSuccessful || listResponse.Data == null)
            {
                return ResponseWrapper<byte[]>.Fail(
                    listResponse.Messages ?? new List<string> { "Failed to retrieve audit trails for export." },
                    listResponse.StatusCode);
            }

            var fileBytes = await _auditTrailService.ExportAuditTrailsAsync(listResponse.Data, request.ExportFormat, ct);

            return ResponseWrapper<byte[]>.Success(fileBytes);
        }
    }
}
