using UMS.Application.Dtos.Pagination;
using UMS.Application.Features.Users.Models.Responses;

namespace UMS.Application.Features.Users.Queries
{
    public class GetUsersPagedQuery : IRequest<IResponseWrapper<PagedResult<UserResponse>>>, IValidateMe
    {
        public PagedFilterRequest PagedFilterRequest { get; set; }
    }

    public class GetUsersPagedQueryHandler(IUserService userService) : IRequestHandler<GetUsersPagedQuery, IResponseWrapper<PagedResult<UserResponse>>>
    {
        private readonly IUserService _userService = userService;
        public async ValueTask<IResponseWrapper<PagedResult<UserResponse>>> Handle(GetUsersPagedQuery request, CancellationToken cancellationToken)
        {
            return await _userService.GetUsersPagedQueryAsync(request.PagedFilterRequest, cancellationToken);
        }
    }
}
