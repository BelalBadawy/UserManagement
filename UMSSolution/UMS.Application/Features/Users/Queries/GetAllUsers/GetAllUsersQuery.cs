using UMS.Application.Features.Users.Models.Responses;

namespace UMS.Application.Features.Users.Queries
{
    public class GetAllUsersQuery : IRequest<IResponseWrapper<List<UserResponse>>>
    {
    }

    public class GetAllUsersQueryHandler : IRequestHandler<GetAllUsersQuery, IResponseWrapper<List<UserResponse>>>
    {
        private readonly IUserService _userService;

        public GetAllUsersQueryHandler(IUserService userService)
        {
            _userService = userService;
        }

        public async ValueTask<IResponseWrapper<List<UserResponse>>> Handle(GetAllUsersQuery request, CancellationToken ct)
        {
            return await _userService.GetAllUsersAsync();
        }
    }
}
