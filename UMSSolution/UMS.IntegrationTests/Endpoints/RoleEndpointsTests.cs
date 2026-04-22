using FluentAssertions;
using NUnit.Framework;
using System.Net;
using System.Net.Http.Json;
using UMS.Application.Features.Roles;
using UMS.IntegrationTests.Base;

namespace UMS.IntegrationTests.Endpoints
{
    [TestFixture]
    public class RoleEndpointsTests : IntegrationTestBase
    {
        [SetUp]
        public async Task SetUp()
        {
            await LoginAsAdminAsync();
        }

        [Test]
        public async Task GetAllRoles_Should_ReturnOk_When_Authorized()
        {
            // Act
            var response = await Client.GetAsync("/api/v1/roles/all");

            // Assert
            response.StatusCode.Should().Be(HttpStatusCode.OK);
            var result = await response.Content.ReadFromJsonAsync<ResponseWrapperStub<List<RoleResponse>>>();
            result.IsSuccessful.Should().BeTrue();
            result.Data.Should().NotBeEmpty();
        }

        [Test]
        public async Task CreateRole_Should_ReturnOk_When_Valid()
        {
            // Arrange
            var request = new { Name = "NewTestRole", Description = "Test Description" };

            // Act
            var response = await Client.PostAsJsonAsync("/api/v1/roles", request);

            // Assert
            response.StatusCode.Should().Be(HttpStatusCode.OK);
            var result = await response.Content.ReadFromJsonAsync<ResponseWrapperStub<object>>();
            result.IsSuccessful.Should().BeTrue();
        }

        [Test]
        public async Task GetRoleById_Should_ReturnNotFound_When_InvalidId()
        {
            // Act
            var response = await Client.GetAsync("/api/v1/roles/9999");

            // Assert
            response.StatusCode.Should().Be(HttpStatusCode.NotFound);
        }
    }
}
