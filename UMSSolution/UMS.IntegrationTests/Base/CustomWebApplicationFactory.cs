using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using UMS.Infrastructure.Persistence.Contexts;

namespace UMS.IntegrationTests.Base
{
    public class CustomWebApplicationFactory : WebApplicationFactory<Program>
    {
        protected override void ConfigureWebHost(IWebHostBuilder builder)
        {
            builder.ConfigureAppConfiguration((context, config) =>
            {
                config.AddInMemoryCollection(new Dictionary<string, string>
                {
                    { "DbProvider", "InMemory" }
                });
            });

            builder.ConfigureServices(services =>
            {
                // Ensure we don't try to register another provider here.
                // The registration happens in Program.cs via AddInfrastructureServices.
                
                // We can still get the DB and ensure it's created.
                var sp = services.BuildServiceProvider();
                using var scope = sp.CreateScope();
                var db = scope.ServiceProvider.GetService<ApplicationDbContext>();
                if (db != null)
                {
                    db.Database.EnsureCreated();
                }
            });
        }
    }
}
