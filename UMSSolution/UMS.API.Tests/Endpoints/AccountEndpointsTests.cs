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

    [Fact]
    public async Task Login_should_return_unsuccessful_payload_when_credentials_are_invalid()
    {
        var response = await Client.PostAsJsonAsync("/api/v1/account/login", new
        {
            Email = "admin@gmail.com",
            Password = "WrongPassword"
        });

        response.StatusCode.Should().Be(HttpStatusCode.InternalServerError);

        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<TokenResponseContract>>();

        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeFalse();
    }

    [Fact]
    public async Task Forgot_password_should_return_unsuccessful_payload_when_email_flow_is_not_configured()
    {
        var response = await Client.PostAsJsonAsync("/api/v1/account/forgot-password?email=admin@gmail.com", new { });

        response.StatusCode.Should().Be(HttpStatusCode.InternalServerError);

        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<object>>();

        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeFalse();
    }
}
