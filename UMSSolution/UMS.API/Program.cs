using Scalar.AspNetCore;
using UMS.API;
using UMS.API.Endpoints;
using UMS.API.Helpers;
using UMS.Application;
using UMS.Application.Dtos.TwoFactor;
using UMS.Infrastructure;
using WebApi.Endpoints;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddOpenApi("v1", options =>
{
    options.AddDocumentTransformer((document, context, ct) =>
        new BearerSchemeTransformer().TransformAsync(document, context, ct)
    );
});

builder.Services.AddCorsConfig(builder.Configuration);
builder.Services.AddHttpContextAccessor();

builder.Services.AddApiVersioningConfig();
builder.Services.AddApplicationServices();
builder.Services.AddInfrastructureServices(builder.Configuration, builder.Environment);
builder.Services.AddMemoryCache();
builder.Services.Configure<TwoFactorOptions>(builder.Configuration.GetSection("TwoFactor"));


var app = builder.Build();


if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();

    app.MapScalarApiReference(options =>
    {
        options.AddPreferredSecuritySchemes("Bearer");
    }).RequireAuthorization();
}
else
{
    app.UseHsts();
}

app.UseHttpsRedirection();

app.UseStaticFiles();

app.UseMiddleware<ErrorHandlingMiddleware>();

app.UseRouting();

// CORS before authentication
app.UseCors("AllowedOrigins");
await app.UseInfrastructureAsync();
app.MapAccountEndpoints();
app.MapCategoryEndpoints();
app.MapRoleEndpoints();
app.MapUserEndpoints();
app.Run();

public partial class Program { }
