using SampleApp.Application.Features.Users.Models.Responses;

namespace SampleApp.Application.Features.Users.Commands.SetupTwoFactorAuth
{
    public class SetupTwoFactorAuthCommand
        : IRequest<IResponseWrapper<TwoFactorAuthViewModel>> { }

    public class SetupTwoFactorAuthCommandHandler
        : IRequestHandler<SetupTwoFactorAuthCommand, IResponseWrapper<TwoFactorAuthViewModel>>
    {
        private readonly IUserService _userService;

        public SetupTwoFactorAuthCommandHandler(IUserService userService)
            => _userService = userService;

        public async ValueTask<IResponseWrapper<TwoFactorAuthViewModel>> Handle(
            SetupTwoFactorAuthCommand request, CancellationToken ct)
            => await _userService.SetupTwoFactorAuthAsync();
    }
}