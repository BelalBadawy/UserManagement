using System.Text.Json.Serialization;

namespace UMS.Application.Features.Users.Models.Responses;

public class TwoFactorAuthViewModel
{
    public string? KeySecret { get; set; }
    public string? CodeQR { get; set; }

    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? VerificationCode { get; set; }
}
