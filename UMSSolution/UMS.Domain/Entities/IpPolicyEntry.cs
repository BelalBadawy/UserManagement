namespace UMS.Domain.Entities;

/// <summary>
/// Stores IP-based access policies (Allowlist/Blocklist).
/// </summary>
public class IpPolicyEntry : BaseEntity<int>, IAuditable
{
    public string IpAddress { get; set; } = string.Empty;
    public bool IsBlocked { get; set; }
    public string? Reason { get; set; }
    public DateTime? Expiration { get; set; }

    public int? CreatedBy { get; set; }
    public DateTime CreatedAt { get; set; }
    public int? LastModifiedBy { get; set; }
    public DateTime? LastModifiedAt { get; set; }
}
