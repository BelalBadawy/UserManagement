namespace UMS.Domain.Entities;

/// <summary>
/// Persistently stored refresh token for session management.
/// Supports rotation and family-based revocation.
/// </summary>
public class RefreshToken : BaseEntity<int>, IAuditable
{
    public int UserId { get; set; }
    public string Token { get; set; } = string.Empty;
    public string? ReplacedByToken { get; set; }
    public DateTime ExpiresAt { get; set; }
    public bool IsRevoked { get; set; }
    public string? IpAddress { get; set; }
    public string? UserAgent { get; set; }
    public int? CreatedBy { get; set; }
    public DateTime CreatedAt { get; set; }
    public int? LastModifiedBy { get; set; }
    public DateTime? LastModifiedAt { get; set; }
}
