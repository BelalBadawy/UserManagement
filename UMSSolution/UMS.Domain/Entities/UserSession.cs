namespace UMS.Domain.Entities;

/// <summary>
/// Logical user session representing a device/browser login.
/// Managed alongside RefreshToken families.
/// </summary>
public class UserSession : BaseEntity<int>, IAuditable
{
    public int UserId { get; set; }
    public string FamilyId { get; set; } = string.Empty;
    public string? IpAddress { get; set; }
    public string? UserAgent { get; set; }
    public DateTime LastActivityAt { get; set; }
    public bool IsRevoked { get; set; }

    public int? CreatedBy { get; set; }
    public DateTime CreatedAt { get; set; }
    public int? LastModifiedBy { get; set; }
    public DateTime? LastModifiedAt { get; set; }
}
