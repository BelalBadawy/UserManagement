using System.Net;
using System.Net.Http.Json;
using UMS.API.Tests.Contracts;
using UMS.API.Tests.Fixtures;
using UMS.API.Tests.Support;

namespace UMS.API.Tests.Endpoints;

[Collection("API collection")]
public class AccountEndpointsTests : ApiTestBase
{
    public AccountEndpointsTests(CustomWebApplicationFactory factory) : base(factory)
    {
    }

    [Fact]
    public async Task Login_should_return_token_for_seeded_admin_user()
    {
        var response = await Client.PostAsJsonAsync("/api/v1/account/login", new
        {
            Email = "admin@gmail.com",
            Password = "Admin@123"
        });

        response.StatusCode.Should().Be(HttpStatusCode.OK);

        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<TokenResponseContract>>();

        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeTrue();
        payload.Data.Should().NotBeNull();
        payload.Data!.Token.Should().NotBeNullOrWhiteSpace();
    }

}
