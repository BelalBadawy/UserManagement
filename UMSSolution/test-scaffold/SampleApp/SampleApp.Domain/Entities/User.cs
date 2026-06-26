using SampleApp.Domain.Common;

namespace SampleApp.Domain.Entities
{
    public class User : BaseEntity<int>
    {
        public string Email { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
        public bool IsActive { get; set; }
    }
}