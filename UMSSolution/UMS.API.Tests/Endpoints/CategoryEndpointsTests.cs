using System.Net;
using System.Net.Http.Json;
using UMS.API.Tests.Contracts;
using UMS.API.Tests.Fixtures;
using UMS.API.Tests.Support;

namespace UMS.API.Tests.Endpoints;

[Collection("API collection")]
public class CategoryEndpointsTests : ApiTestBase
{
    public CategoryEndpointsTests(CustomWebApplicationFactory factory) : base(factory)
    {
    }

    [Fact]
    public async Task Get_all_categories_should_return_successful_response()
    {
        var response = await Client.GetAsync("/api/v1/categories");

        response.StatusCode.Should().Be(HttpStatusCode.OK);

        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<List<CategoryResponseContract>>>();

        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeTrue();
        payload.Data.Should().NotBeNull();
    }

    [Fact]
    public async Task Create_category_should_require_authorization()
    {
        var response = await Client.PostAsJsonAsync("/api/v1/categories", new
        {
            Name = "Unauthorized Category",
            Slug = "unauthorized-category",
            SortOrder = 2,
            IsActive = true
        });

        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

}
