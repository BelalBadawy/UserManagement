using System.Collections.Generic;

namespace UMS.Application.Features.Users.Models.Responses
{
    public class UserExportResponse : UserResponse
    {
        public List<string> Roles { get; set; } = new();
    }
}
