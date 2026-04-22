using FluentAssertions;
using NUnit.Framework;
using System.Net;
using System.Net.Http.Json;
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Categories.Queries.GetCategoriesPaged;
using UMS.IntegrationTests.Base;

namespace UMS.IntegrationTests.Endpoints
{
    [TestFixture]
    public class CategoryEndpointsTests : IntegrationTestBase
    {
        [SetUp]
        public async Task SetUp()
        {
            await LoginAsAdminAsync();
        }

        [Test]
        public async Task GetAllCategories_Should_ReturnOk()
        {
            // Act
            var response = await Client.GetAsync("/api/v1/categories");

            // Assert
            response.StatusCode.Should().Be(HttpStatusCode.OK);
            
            var result = await response.Content.ReadFromJsonAsync<ResponseWrapperStub<List<CategoryResponseStub>>>();
            result.Should().NotBeNull();
            result.IsSuccessful.Should().BeTrue();
            result.Data.Should().NotBeNull();
        }

        [Test]
        public async Task CreateCategory_Should_ReturnOk_When_Valid()
        {
            // Arrange
            var request = new { Name = "Integration Category", Slug = "integration-category", SortOrder = 10 };

            // Act
            var response = await Client.PostAsJsonAsync("/api/v1/categories", request);

            // Assert
            response.StatusCode.Should().Be(HttpStatusCode.OK);
            var result = await response.Content.ReadFromJsonAsync<ResponseWrapperStub<int>>();
            result.IsSuccessful.Should().BeTrue();
            result.Data.Should().BeGreaterThan(0);
        }

        [Test]
        public async Task GetCategoryById_Should_ReturnNotFound_When_InvalidId()
        {
            // Arrange
            var invalidId = 99999;

            // Act
            var response = await Client.GetAsync($"/api/v1/categories/{invalidId}");

            // Assert
            response.StatusCode.Should().Be(HttpStatusCode.NotFound);
            
            var result = await response.Content.ReadFromJsonAsync<ResponseWrapperStub<CategoryResponseStub>>();
            result.Should().NotBeNull();
            result.IsSuccessful.Should().BeFalse();
        }
    }
}
