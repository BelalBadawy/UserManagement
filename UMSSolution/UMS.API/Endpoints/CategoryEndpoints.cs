using Mediator;
using UMS.API.Extensions;
using UMS.Application.Dtos.Pagination;
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Categories.Commands.Create;
using UMS.Application.Features.Categories.Commands.Delete;
using UMS.Application.Features.Categories.Commands.Update;
using UMS.Application.Features.Categories.Queries.GetAllCategories;
using UMS.Application.Features.Categories.Queries.GetAllCategoriesForList;
using UMS.Application.Features.Categories.Queries.GetCategoriesPaged;
using UMS.Application.Features.Categories.Queries.GetCategoryById;
using UMS.Application.Authorization;

namespace UMS.API.Endpoints
{
    public static class CategoryEndpoints
    {
        public static IEndpointRouteBuilder MapCategoryEndpoints(this IEndpointRouteBuilder app)
        {
            var group = app.MapGroup("api/v{version:apiVersion}/categories")
                .WithTags("Categories");

            group.MapGet("/", async (ISender sender, bool? isActive, CancellationToken ct) =>
            {
                var query = new GetAllCategoriesQuery(isActive);
                var response = await sender.Send(query, ct);
                  return response.ToApiResult(); 
            })
            .Produces<IResponseWrapper<List<CategoryResponse>>>()
            .WithName("GetAllCategories")
            .AllowAnonymous();

            group.MapGet("/paged", async (ISender sender, [AsParameters] PagedFilterRequest filter, CancellationToken ct) =>
            {
                // Use object initializer syntax instead of a constructor
                var query = new GetCategoriesPagedQuery { PagedFilterRequest = filter };
                var response = await sender.Send(query, ct);
                return response.ToApiResult();
            })
            .Produces<IResponseWrapper<PagedResult<CategoryResponse>>>()
            .WithName("GetCategoriesPaged")
            .AllowAnonymous();

            group.MapGet("/for-list", async (ISender sender, CancellationToken ct) =>
            {
                var query = new GetAllCategoriesForListQuery();
                var response = await sender.Send(query, ct);
                return response.ToApiResult();
            })
            .Produces<IResponseWrapper<List<CategoryLookupDto>>>()
            .WithName("GetCategoriesForList")
            .RequireAuthorization(AppPermission.NameFor(AppService.Product, AppFeature.Categories, AppAction.Read));

            group.MapGet("/{categoryId:int}", async (ISender sender, int categoryId, CancellationToken ct) =>
            {
                var query = new GetCategoryByIdQuery(categoryId);
                var response = await sender.Send(query, ct);
                return response.ToApiResult();
            })
            .Produces<IResponseWrapper<CategoryResponse>>()
            .WithName("GetCategoryById")
            .AllowAnonymous();

            group.MapPost("/", async (ISender sender, CreateCategoryCommand request, CancellationToken ct) =>
            {
                var response = await sender.Send(request, ct);
                return response.ToApiResult();
            })
            .Produces<IResponseWrapper>()
            .WithName("CreateCategory")
            .RequireAuthorization(AppPermission.NameFor(AppService.Product, AppFeature.Categories, AppAction.Create));

            group.MapPut("/", async (ISender sender, UpdateCategoryCommand request, CancellationToken ct) =>
            {
                var response = await sender.Send(request, ct);
                return response.ToApiResult();
            })
            .Produces<IResponseWrapper>()
            .WithName("UpdateCategory")
            .RequireAuthorization(AppPermission.NameFor(AppService.Product, AppFeature.Categories, AppAction.Update));

            group.MapDelete("/{categoryId:int}", async (ISender sender, int categoryId, CancellationToken ct) =>
            {
                var command = new DeleteCategoryCommand(categoryId);
                var response = await sender.Send(command, ct);
                return response.ToApiResult();
            })
            .Produces<IResponseWrapper>()
            .WithName("DeleteCategory")
            .RequireAuthorization(AppPermission.NameFor(AppService.Product, AppFeature.Categories, AppAction.Delete));

            return app;
        }
    }
}
