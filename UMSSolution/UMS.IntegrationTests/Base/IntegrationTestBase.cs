using Microsoft.Extensions.DependencyInjection;
using NUnit.Framework;
using System.Net.Http.Json;
using System.Net.Http.Headers;

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

        protected async Task LoginAsAdminAsync()
        {
            var loginRequest = new { Email = "admin@gmail.com", Password = "Admin@123" };
            var response = await Client.PostAsJsonAsync("/api/v1/account/login", loginRequest);
            var result = await response.Content.ReadFromJsonAsync<ResponseWrapperStub<TokenResponseStub>>();
            
            Client.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", result.Data.AccessToken);
        }
    }

    public record TokenResponseStub(string AccessToken, string RefreshToken, DateTime Expiration);

    public class ResponseWrapperStub<T>
    {
        public List<string> Messages { get; set; } = new();
        public bool IsSuccessful { get; set; }
        public T Data { get; set; }
    }

    public record CategoryResponseStub(
        int Id,
        string Name,
        string Slug,
        int? ParentId,
        int SortOrder
    );
}
