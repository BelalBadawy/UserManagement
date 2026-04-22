using FluentAssertions;
using NUnit.Framework;
using System.Net;
using System.Net.Http.Json;
using UMS.Application.Features.Users.Models.Responses;
using UMS.IntegrationTests.Base;

namespace UMS.IntegrationTests.Endpoints
{
    [TestFixture]
    public class UserEndpointsTests : IntegrationTestBase
    {
        [SetUp]
        public async Task SetUp()
        {
            await LoginAsAdminAsync();
        }

        [Test]
        public async Task GetAllUsers_Should_ReturnOk_When_Authorized()
        {
            // Act
            var response = await Client.GetAsync("/api/v1/users/all");

            // Assert
            response.StatusCode.Should().Be(HttpStatusCode.OK);
            var result = await response.Content.ReadFromJsonAsync<ResponseWrapperStub<List<UserResponse>>>();
            result.IsSuccessful.Should().BeTrue();
            result.Data.Should().NotBeEmpty();
        }

        [Test]
        public async Task GetUserById_Should_ReturnOk_When_UserExists()
        {
            // Arrange
            // Admin user email is admin@gmail.com, we can get its ID from GetAll
            var allUsersResponse = await Client.GetAsync("/api/v1/users/all");
            var allUsers = await allUsersResponse.Content.ReadFromJsonAsync<ResponseWrapperStub<List<UserResponse>>>();
            var adminUser = allUsers.Data.First(u => u.Email == "admin@gmail.com");

            // Act
            var response = await Client.GetAsync($"/api/v1/users/{adminUser.Id}");

            // Assert
            response.StatusCode.Should().Be(HttpStatusCode.OK);
            var result = await response.Content.ReadFromJsonAsync<ResponseWrapperStub<UserResponse>>();
            result.IsSuccessful.Should().BeTrue();
            result.Data.Id.Should().Be(adminUser.Id);
        }

        [Test]
        public async Task GetUserById_Should_ReturnNotFound_When_UserDoesNotExist()
        {
            // Act
            var response = await Client.GetAsync("/api/v1/users/9999");

            // Assert
            response.StatusCode.Should().Be(HttpStatusCode.NotFound);
        }
    }
}
