namespace UMS.Domain.Entities;

/// <summary>
/// Stores subscriptions for security-related webhooks.
/// </summary>
public class WebhookSubscription : BaseEntity<int>, IAuditable
{
    public string EventType { get; set; } = string.Empty;
    public string WebhookUrl { get; set; } = string.Empty;
    public string? Secret { get; set; }
    public bool IsActive { get; set; } = true;

    public int? CreatedBy { get; set; }
    public DateTime CreatedAt { get; set; }
    public int? LastModifiedBy { get; set; }
    public DateTime? LastModifiedAt { get; set; }
}
