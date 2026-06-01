using Mediator;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Routing;
using UMS.API.Extensions;
using UMS.Application.Authorization;
using UMS.Application.Dtos.Pagination;
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.AuditTrails.Queries.GetAuditTrailsPaged;

namespace UMS.API.Endpoints
{
    public static class AuditTrailEndpoints
    {
        public static IEndpointRouteBuilder MapAuditTrailEndpoints(this IEndpointRouteBuilder app)
        {
            var group = app.MapGroup("api/v{version:apiVersion}/audit-logs")
                .WithTags("AuditLogs");

            group.MapGet("/", async (ISender sender, [AsParameters] PagedFilterRequest filter, CancellationToken ct) =>
            {
                var query = new GetAuditTrailsPagedQuery { PagedFilterRequest = filter };
                var response = await sender.Send(query, ct);
                return response.ToApiResult();
            })
            .Produces<IResponseWrapper<PagedResult<AuditTrailResponse>>>()
            .WithName("GetAuditTrailsPaged")
            .RequireAuthorization(AppPermission.NameFor(AppService.Identity, AppFeature.AuditTrails, AppAction.Read));

            return app;
        }
    }
}
