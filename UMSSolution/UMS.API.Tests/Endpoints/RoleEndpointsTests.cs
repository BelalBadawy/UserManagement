using System.Net;
using System.Net.Http.Json;
using UMS.API.Tests.Contracts;
using UMS.API.Tests.Fixtures;
using UMS.API.Tests.Support;

namespace UMS.API.Tests.Endpoints;

[Collection("API collection")]
public class RoleEndpointsTests : ApiTestBase
{
    public RoleEndpointsTests(CustomWebApplicationFactory factory) : base(factory)
    {
    }

    [Fact]
    public async Task Get_all_roles_should_return_successful_response_when_authorized()
    {
        await AuthenticateAsAdminAsync();

        var response = await Client.GetAsync("/api/v1/roles/all");

        response.StatusCode.Should().Be(HttpStatusCode.OK);

        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<List<RoleResponseContract>>>();

        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeTrue();
        payload.Data.Should().NotBeEmpty();
    }

    [Fact]
    public async Task Create_role_should_return_successful_response_when_valid()
    {
        await AuthenticateAsAdminAsync();

        var suffix = Guid.NewGuid().ToString("N")[..8];
        var request = new
        {
            Name = $"NewTestRole-{suffix}",
            Description = "Test Description"
        };

        var response = await Client.PostAsJsonAsync("/api/v1/roles", request);

        response.StatusCode.Should().Be(HttpStatusCode.OK);

        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<object>>();

        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeTrue();
    }

    [Fact]
    public async Task Get_role_by_id_should_return_not_found_when_id_is_invalid()
    {
        await AuthenticateAsAdminAsync();

        var response = await Client.GetAsync("/api/v1/roles/9999");

        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }
}
