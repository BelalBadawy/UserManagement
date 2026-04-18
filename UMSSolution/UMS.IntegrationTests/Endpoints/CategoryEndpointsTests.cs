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

    // Stub classes to avoid namespace issues and complex deserialization of internal types
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
