# API Presentation Layer

## Minimal APIs
- STRICTLY use Minimal APIs. MVC Controllers prohibited
- Use MapGroup extension methods for organization

## Dynamic Claims-Based Authorization
- Permissions manifest cached via IMemoryCache
- Use .RequireAuthorization("PolicyName") with dynamic claim checking

## Global Exception Handling
- Implement IExceptionHandler (ASP.NET Core 8+)
- Return standardized RFC 7807 ProblemDetails
- NEVER leak internal server details in production

## Logging (Serilog)
- JSON format (JsonFormatter or CompactJsonFormatter)
- Automatic enrichment: TraceId, UserId, ClientIp

## Health Checks
- /health/live - API process running
- /health/ready - Database + Hangfire connections active

## Endpoint Example Pattern
```csharp
public static class UserEndpoints
{
    public static void MapUserEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/v1/users")
                       .WithTags("Users")
                       .RequireRateLimiting("StandardPolicy");
        
        group.MapPost("/", CreateUser)
             .RequireAuthorization("DynamicPolicyName");
    }
}
```