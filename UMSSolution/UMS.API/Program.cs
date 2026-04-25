using Scalar.AspNetCore;
using UMS.API;
using UMS.API.Endpoints;
using UMS.API.Helpers;
using UMS.Application;
using UMS.Infrastructure;
using WebApi.Endpoints;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
// Add OpenAPI
builder.Services.AddOpenApi("v1", options =>
{
    options.AddDocumentTransformer((document, context, ct) =>
        new BearerSchemeTransformer().TransformAsync(document, context, ct)
    );
});

//// Add services
//builder.Services.AddControllers()
//    .AddNewtonsoftJson(opt =>
//        opt.SerializerSettings.ReferenceLoopHandling = ReferenceLoopHandling.Ignore);



builder.Services.AddCorsAllowAll();
builder.Services.AddHttpContextAccessor();

builder.Services.AddApiVersioningConfig();
builder.Services.AddApplicationServices();
builder.Services.AddInfrastructureServices(builder.Configuration, builder.Environment);


var app = builder.Build();


// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();

    // app.MapScalarApiReference(); 

    //  Map **Scalar API Reference**, securing it with JWT
    app.MapScalarApiReference(options =>
    {
        options.AddPreferredSecuritySchemes("Bearer");
    });
    //.RequireAuthorization();  // <- Require JWT to view the Scalar UI
}

app.UseHttpsRedirection();

app.UseMiddleware<ErrorHandlingMiddleware>();

// Routing first
app.UseRouting();

app.UseStaticFiles();

// CORS before authentication
app.UseCorsAllowAll();
await app.UseInfrastructureAsync();
app.MapAccountEndpoints();
app.MapCategoryEndpoints();
app.MapRoleEndpoints();
app.MapUserEndpoints();
app.Run();

public partial class Program { }
