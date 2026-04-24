using System.Net;
using System.Net.Http.Json;
using UMS.Application.Features.Categories.Commands.Create;
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

    [Fact]
    public async Task Create_category_should_return_bad_request_when_create_payload_binding_fails()
    {
        await AuthenticateAsAdminAsync();

        var suffix = Guid.NewGuid().ToString("N")[..8];
        var request = new CreateCategoryCommand(
            Name: $"Category {suffix}",
            Slug: $"category-{suffix}",
            ParentId: null,
            IsActive: true,
            SortOrder: 10);

        var response = await Client.PostAsJsonAsync("/api/v1/categories", request);

        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }

    [Fact]
    public async Task Get_category_by_id_should_return_unsuccessful_payload_when_id_is_invalid()
    {
        await AuthenticateAsAdminAsync();

        var response = await Client.GetAsync("/api/v1/categories/99999");

        response.StatusCode.Should().Be(HttpStatusCode.InternalServerError);

        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<CategoryResponseContract>>();

        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeFalse();
    }

}
