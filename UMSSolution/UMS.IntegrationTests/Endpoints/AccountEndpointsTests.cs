using FluentAssertions;
using NUnit.Framework;
using System.Net;
using System.Net.Http.Json;
using UMS.IntegrationTests.Base;

namespace UMS.IntegrationTests.Endpoints
{
    [TestFixture]
    public class AccountEndpointsTests : IntegrationTestBase
    {
        [Test]
        public async Task Login_Should_ReturnToken_When_CredentialsValid()
        {
            // Arrange
            var loginRequest = new { Email = "admin@gmail.com", Password = "Admin@123" };

            // Act
            var response = await Client.PostAsJsonAsync("/api/v1/account/login", loginRequest);

            // Assert
            response.StatusCode.Should().Be(HttpStatusCode.OK);
            var result = await response.Content.ReadFromJsonAsync<ResponseWrapperStub<TokenResponseStub>>();
            result.IsSuccessful.Should().BeTrue();
            result.Data.AccessToken.Should().NotBeNullOrEmpty();
        }

        [Test]
        public async Task Login_Should_ReturnBadRequest_When_CredentialsInvalid()
        {
            // Arrange
            var loginRequest = new { Email = "admin@gmail.com", Password = "WrongPassword" };

            // Act
            var response = await Client.PostAsJsonAsync("/api/v1/account/login", loginRequest);

            // Assert
            // Depending on implementation, it might be 400 or 200 with IsSuccessful = false.
            // Based on ToApiResult extension, usually it maps to 400 or 200.
            response.StatusCode.Should().BeOneOf(HttpStatusCode.BadRequest, HttpStatusCode.OK);
            if (response.StatusCode == HttpStatusCode.OK)
            {
                var result = await response.Content.ReadFromJsonAsync<ResponseWrapperStub<TokenResponseStub>>();
                result.IsSuccessful.Should().BeFalse();
            }
        }

        [Test]
        public async Task ForgotPassword_Should_ReturnOk_When_EmailExists()
        {
            // Arrange
            var email = "admin@gmail.com";

            // Act
            var response = await Client.PostAsJsonAsync($"/api/v1/account/forgot-password?email={email}", new { });

            // Assert
            response.StatusCode.Should().Be(HttpStatusCode.OK);
        }
    }
}
