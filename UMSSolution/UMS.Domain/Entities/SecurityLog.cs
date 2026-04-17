namespace UMS.Domain.Entities;

/// <summary>
/// Records security events like login attempts, password changes, etc.
/// </summary>
public class SecurityLog : BaseEntity<int>
{
    public int? UserId { get; set; }
    public string EventType { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string? IpAddress { get; set; }
    public string? UserAgent { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
