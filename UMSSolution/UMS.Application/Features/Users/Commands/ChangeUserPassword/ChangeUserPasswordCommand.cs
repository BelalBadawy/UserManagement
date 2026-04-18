namespace UMS.Application.Features.Users.Commands
{
    public class ChangeUserPasswordCommand : IRequest<IResponseWrapper>, IValidateMe
    {
        public ChangePasswordRequest ChangePassword { get; set; }
    }

    public class ChangeUserPasswordCommandHandler : IRequestHandler<ChangeUserPasswordCommand, IResponseWrapper>
    {
        private readonly IUserService _userService;

        public ChangeUserPasswordCommandHandler(IUserService userService)
        {
            _userService = userService;
        }

        public async ValueTask<IResponseWrapper> Handle(ChangeUserPasswordCommand request, CancellationToken ct)
        {
            return await _userService.ChangeUserPasswordAsync(request.ChangePassword);
        }
    }
}
