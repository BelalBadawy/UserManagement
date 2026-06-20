using System.Net;
using System.Net.Http.Json;
using UMS.Application.Authorization;
using UMS.API.Tests.Contracts;
using UMS.API.Tests.Fixtures;
using UMS.API.Tests.Support;

namespace UMS.API.Tests.Endpoints;

[Collection("API collection")]
public class AuditTrailEndpointsTests : ApiTestBase
{
    public AuditTrailEndpointsTests(CustomWebApplicationFactory factory) : base(factory)
    {
    }

    [Fact]
    public async Task GetAuditLogsPaged_DefaultRequest_ReturnsSuccessfulOrDebugs400()
    {
        UsePrivilegedClient(AppPermission.NameFor(AppService.Identity, AppFeature.AuditTrails, AppAction.Read));

        const string route = "/api/v1/audit-logs/paged?pageNumber=1&pageSize=10&sortBy=datetime&sortDirection=desc";

        var response = await Client.GetAsync(route);
        var content = await response.Content.ReadAsStringAsync();

        response.StatusCode.Should().Be(HttpStatusCode.OK, because: $"API returned status {response.StatusCode} with content: {content}");
    }
}
