using System.Net.Http.Headers;
using System.Net.Http.Json;
using Microsoft.Extensions.DependencyInjection;
using UMS.API.Tests.Contracts;

namespace UMS.API.Tests.Fixtures;

public abstract class ApiTestBase : IClassFixture<CustomWebApplicationFactory>
{
    protected ApiTestBase(CustomWebApplicationFactory factory)
    {
        Factory = factory;
        Client = factory.CreateClient();
    }

    protected CustomWebApplicationFactory Factory { get; }
    protected HttpClient Client { get; }

    protected T GetRequiredService<T>() where T : notnull
    {
        using var scope = Factory.Services.CreateScope();
        return scope.ServiceProvider.GetRequiredService<T>();
    }

    protected async Task AuthenticateAsAdminAsync()
    {
        var response = await Client.PostAsJsonAsync("/api/v1/account/login", new
        {
            Email = "admin@gmail.com",
            Password = "Admin@123"
        });

        response.EnsureSuccessStatusCode();

        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<TokenResponseContract>>();
        payload.Should().NotBeNull();
        payload!.Data.Should().NotBeNull();

        Client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", payload.Data!.Token);
    }
}
