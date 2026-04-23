using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.Configuration;

namespace UMS.API.Tests.Fixtures;

public sealed class CustomWebApplicationFactory : WebApplicationFactory<Program>, IAsyncLifetime
{
    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Development");

        builder.ConfigureAppConfiguration((_, configBuilder) =>
        {
            configBuilder.AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["DbProvider"] = "InMemory",
                ["EnableAuditLog"] = "false"
            });
        });
    }

    public Task InitializeAsync() => Task.CompletedTask;

    public new Task DisposeAsync() => base.DisposeAsync().AsTask();
}
