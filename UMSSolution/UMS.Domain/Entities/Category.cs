namespace UMS.Domain.Entities
{
    /// <summary>
    /// Represents a product category.
    /// </summary>
    public class Category : BaseEntity<int>, IFullEntity, IDataConcurrency
    {
        /// <summary>
        /// Display name of the category.
        /// </summary>
        public string Name { get; set; } = string.Empty;

        /// <summary>
        /// URL-friendly slug.
        /// </summary>
        public string Slug { get; set; } = string.Empty;

        /// <summary>
        /// Optional parent category id for hierarchy.
        /// </summary>
        public int? ParentId { get; set; }

        // ---------------------------------------------------------
        // NAVIGATION PROPERTIES
        // ---------------------------------------------------------

        /// <summary>
        /// Parent category navigation property.
        /// </summary>
        public virtual Category? Parent { get; set; }

        /// <summary>
        /// Collection of child categories (Inverse Navigation).
        /// </summary>
        public virtual ICollection<Category> Children { get; set; } = new HashSet<Category>();

        /// <summary>
        /// Indicates if the category is active.
        /// </summary>
        public bool IsActive { get; set; } = true;

        /// <summary>
        /// Ordering index used when displaying categories.
        /// </summary>
        public int SortOrder { get; set; }

        public bool SoftDeleted { get; set; }
        public int? DeletedBy { get; set; }
        public DateTime? DeletedAt { get; set; }

        public int? CreatedBy { get; set; }
        public DateTime CreatedAt { get; set; }
        public int? LastModifiedBy { get; set; }
        public DateTime? LastModifiedAt { get; set; }

        /// <inheritdoc/>
        public byte[] RowVersion { get; set; } = Array.Empty<byte>();
    }
}
