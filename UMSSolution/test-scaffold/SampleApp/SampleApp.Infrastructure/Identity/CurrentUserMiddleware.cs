using Microsoft.AspNetCore.Http;
using SampleApp.Application.Interfaces.Common;

namespace SampleApp.Infrastructure.Identity
{
    public class CurrentUserMiddleware(ICurrentUserService currentUserService) : IMiddleware
    {
        private readonly ICurrentUserService _currentUserService = currentUserService;

        public async Task InvokeAsync(HttpContext context, RequestDelegate next)
        {
            _currentUserService.SetCurrentUser(context.User);
            await next(context);
        }
    }
}