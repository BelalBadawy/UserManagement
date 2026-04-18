using Microsoft.Extensions.DependencyInjection;
using NUnit.Framework;

namespace UMS.IntegrationTests.Base
{
    public abstract class IntegrationTestBase
    {
        protected CustomWebApplicationFactory Factory { get; private set; }
        protected HttpClient Client { get; private set; }

        [OneTimeSetUp]
        public void OneTimeSetUp()
        {
            Factory = new CustomWebApplicationFactory();
            Client = Factory.CreateClient();
        }

        [OneTimeTearDown]
        public async Task OneTimeTearDown()
        {
            if (Client != null)
            {
                Client.Dispose();
            }

            if (Factory != null)
            {
                await Factory.DisposeAsync();
            }
        }

        protected T GetRequiredService<T>() where T : notnull
        {
            return Factory.Services.CreateScope().ServiceProvider.GetRequiredService<T>();
        }
    }
}
