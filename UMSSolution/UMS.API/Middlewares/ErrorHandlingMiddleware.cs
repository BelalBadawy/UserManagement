
using System.Net;
using System.Text.Json;
using UMS.Application.Dtos.Wrappers;

namespace UMS.API
{
    public class ErrorHandlingMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly ILogger<ErrorHandlingMiddleware> _logger;

        public ErrorHandlingMiddleware(RequestDelegate next, ILogger<ErrorHandlingMiddleware> logger)
        {
            _next = next;
            _logger = logger;
        }

        public async Task InvokeAsync(HttpContext context)
        {
            try
            {
                await _next(context);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unhandled exception occurred.");

                if (context.Response.HasStarted)
                {
                    // Cannot modify headers or write a new body
                    _logger.LogWarning(
                        "The response has already started, the error handling middleware will not modify the response.");
                    throw; // or just return
                }

                await HandleExceptionAsync(context, ex);
            }
        }

        private static async Task HandleExceptionAsync(HttpContext context, Exception ex)
        {
            context.Response.Clear();
          
            //context.Response.StatusCode = ex switch
            //{
            //    ConflictException ce => (int)ce.StatusCode,
            //    NotFoundException nfe => (int)nfe.StatusCode,
            //    ForbiddenException fe => (int)fe.StatusCode,
            //    UnauthorizedException ue => (int)ue.StatusCode,
            //    ValidationException ve => (int)ve.StatusCode,
            //    _ => (int)HttpStatusCode.InternalServerError
            //};

            //context.Response.StatusCode = (int)HttpStatusCode.InternalServerError;

            context.Response.StatusCode = ex switch
            {
                UnauthorizedAccessException => (int)HttpStatusCode.Unauthorized,
                KeyNotFoundException => (int)HttpStatusCode.NotFound,
                InvalidOperationException => (int)HttpStatusCode.BadRequest,
                TimeoutException => (int)HttpStatusCode.RequestTimeout,
                ArgumentException => (int)HttpStatusCode.BadRequest,
                _ => (int)HttpStatusCode.InternalServerError
            };

            context.Response.ContentType = "application/json";

            var responseWrapper =  ResponseWrapper.Fail(ex.Message, context.Response.StatusCode);
            var result = JsonSerializer.Serialize(responseWrapper);

            await context.Response.WriteAsync(result);
        }
    }
}
