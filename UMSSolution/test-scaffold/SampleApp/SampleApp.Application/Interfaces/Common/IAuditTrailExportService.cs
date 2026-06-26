using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using SampleApp.Application.Features.AuditTrails.Queries.GetAuditTrailsPaged;

namespace SampleApp.Application.Interfaces.Common
{
    public interface IAuditTrailExportService
    {
        Task<byte[]> ExportAuditTrailsAsync(List<AuditTrailResponse> data, string format, CancellationToken ct);
    }
}