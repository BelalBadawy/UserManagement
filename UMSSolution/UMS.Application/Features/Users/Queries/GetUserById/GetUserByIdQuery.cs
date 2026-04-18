using UMS.Application.Features.Users.Models.Responses;

namespace UMS.Application.Features.Users.Queries
{
    public class GetUserByIdQuery : IRequest<IResponseWrapper<UserResponse>>, IValidateMe
    {
        public int UserId { get; set; }
    }

    public class GetUserByIdQueryHanlder : IRequestHandler<GetUserByIdQuery, IResponseWrapper<UserResponse>>
    {
        private readonly IUserService _userService;

        public GetUserByIdQueryHanlder(IUserService userService)
        {
            _userService = userService;
        }

        public async ValueTask<IResponseWrapper<UserResponse>> Handle(GetUserByIdQuery request, CancellationToken ct)
        {
            return await _userService.GetUserByIdAsync(request.UserId);
        }
    }
}
