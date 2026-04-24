using System.Net;
using System.Net.Http.Json;
using UMS.API.Tests.Contracts;
using UMS.API.Tests.Fixtures;
using UMS.API.Tests.Support;

namespace UMS.API.Tests.Endpoints;

[Collection("API collection")]
public class UserEndpointsTests : ApiTestBase
{
    public UserEndpointsTests(CustomWebApplicationFactory factory) : base(factory)
    {
    }

    [Fact]
    public async Task Get_all_users_should_return_successful_response_when_authorized()
    {
        await AuthenticateAsAdminAsync();

        var response = await Client.GetAsync("/api/v1/users/all");

        response.StatusCode.Should().Be(HttpStatusCode.OK);

        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<List<UserResponseContract>>>();

        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeTrue();
        payload.Data.Should().NotBeEmpty();
    }

    [Fact]
    public async Task Get_user_by_id_should_return_successful_response_when_user_exists()
    {
        await AuthenticateAsAdminAsync();

        var allUsersResponse = await Client.GetAsync("/api/v1/users/all");
        var allUsers = await allUsersResponse.Content.ReadFromJsonAsync<ResponseContract<List<UserResponseContract>>>();

        allUsers.Should().NotBeNull();
        allUsers!.Data.Should().NotBeNull();

        var adminUser = allUsers.Data!.First(user => user.Email == "admin@gmail.com");

        var response = await Client.GetAsync($"/api/v1/users/{adminUser.Id}");

        response.StatusCode.Should().Be(HttpStatusCode.OK);

        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<UserResponseContract>>();

        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeTrue();
        payload.Data.Should().NotBeNull();
        payload.Data!.Id.Should().Be(adminUser.Id);
    }

    [Fact]
    public async Task Get_user_by_id_should_return_not_found_when_user_does_not_exist()
    {
        await AuthenticateAsAdminAsync();

        var response = await Client.GetAsync("/api/v1/users/9999");

        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }
}
