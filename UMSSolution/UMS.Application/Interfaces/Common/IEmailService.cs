namespace UMS.Application.Interfaces.Common
{
    public interface IEmailService
    {
        Task<string> SendAsync(SendEmailDto request, CancellationToken ct = default);
    }
}
