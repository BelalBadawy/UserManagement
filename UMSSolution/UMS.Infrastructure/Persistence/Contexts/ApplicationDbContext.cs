using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage;
using System.Reflection;
using System.Text.Json;
using UMS.Application.Interfaces.Common;
using UMS.Domain.Enums;
using UMS.Domain.Interfaces;
using UMS.Infrastructure.Extensions;
using UMS.Infrastructure.Persistence.Audit;
using static UMS.Application.Enums.AppEnums;

namespace UMS.Infrastructure.Persistence.Contexts
{
    public class ApplicationDbContext : IdentityDbContext<
        ApplicationUser,
        ApplicationRole,
        int,
        ApplicationUserClaim,
        ApplicationUserRole,
        ApplicationUserLogin,
        ApplicationRoleClaim,
        ApplicationUserToken>,
        IApplicationDbContext
    {
        private readonly IConfiguration _configuration;
        private readonly ICurrentUserService _currentUserService;
        private readonly IDateTimeService _dateTimeService;
        private IDbContextTransaction? _dbContextTransaction;

        private static readonly JsonSerializerOptions OutboxSerializerOptions = new(JsonSerializerDefaults.Web);

        public ApplicationDbContext(
            DbContextOptions<ApplicationDbContext> options,
            IConfiguration configuration,
            ICurrentUserService currentUserService,
            IDateTimeService dateTimeService)
            : base(options)
        {
            _configuration = configuration;
            _currentUserService = currentUserService;
            _dateTimeService = dateTimeService;
        }

        public DbSet<Category> Categories => Set<Category>();
        public DbSet<AuditTrail> AuditTrails => Set<AuditTrail>();
        public DbSet<LogUserActivity> LogUserActivities => Set<LogUserActivity>();
        public DbSet<OutboxMessage> OutboxMessages => Set<OutboxMessage>();
        public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();

        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        {
        }

        public override async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
        {
            var userId = _currentUserService.GetUserId();
            var dateTime = _dateTimeService.NowUtc;

            foreach (var entry in ChangeTracker.Entries<IAuditable>())
            {
                if (entry.State == EntityState.Added)
                {
                    entry.Entity.CreatedAt = dateTime;
                    entry.Entity.CreatedBy = userId;
                }
                else if (entry.State == EntityState.Modified)
                {
                    entry.Entity.LastModifiedAt = dateTime;
                    entry.Entity.LastModifiedBy = userId;
                }
            }

            foreach (var entry in ChangeTracker.Entries<ISoftDelete>())
            {
                if (entry.State == EntityState.Deleted)
                {
                    entry.State = EntityState.Modified;
                    entry.Entity.SoftDeleted = true;
                    entry.Entity.DeletedAt = dateTime;
                    entry.Entity.DeletedBy = userId;
                }
            }

            var enableAuditLog = _configuration.GetValue<bool>("EnableAuditLog", false);

            if (!enableAuditLog)
            {
                return await base.SaveChangesAsync(cancellationToken);
            }

            var auditEntries = OnBeforeSaveChanges(userId);
            var result = await base.SaveChangesAsync(cancellationToken);
            await OnAfterSaveChanges(auditEntries, cancellationToken);
            return result;
        }

        private List<AuditEntry> OnBeforeSaveChanges(int? userId)
        {
            ChangeTracker.DetectChanges();
            var auditEntries = new List<AuditEntry>();

            foreach (var entry in ChangeTracker.Entries())
            {
                if (entry.Entity is AuditTrail
                    || entry.State is EntityState.Detached or EntityState.Unchanged)
                {
                    continue;
                }

                var auditEntry = new AuditEntry(entry)
                {
                    TableName = entry.Entity.GetType().Name,
                    UserId = userId
                };
                auditEntries.Add(auditEntry);

                foreach (var property in entry.Properties)
                {
                    var propertyName = property.Metadata.Name;

                    if (property.Metadata.IsPrimaryKey())
                    {
                        auditEntry.KeyValues[propertyName] = property.CurrentValue!;
                        continue;
                    }

                    switch (entry.State)
                    {
                        case EntityState.Added:
                            auditEntry.Type = AuditType.Create;
                            auditEntry.NewValues[propertyName] = property.CurrentValue!;
                            break;
                        case EntityState.Deleted:
                            auditEntry.Type = AuditType.Delete;
                            auditEntry.OldValues[propertyName] = property.OriginalValue!;
                            break;
                        case EntityState.Modified when property.IsModified:
                            auditEntry.Type = AuditType.Update;
                            auditEntry.OldValues[propertyName] = property.OriginalValue!;
                            auditEntry.NewValues[propertyName] = property.CurrentValue!;
                            break;
                    }
                }
            }

            foreach (var auditEntry in auditEntries.Where(e => !e.HasTemporaryProperties))
            {
                AuditTrails.Add(auditEntry.ToAudit());
            }

            return auditEntries.Where(e => e.HasTemporaryProperties).ToList();
        }

        private async Task OnAfterSaveChanges(List<AuditEntry> auditEntries, CancellationToken cancellationToken)
        {
            if (auditEntries == null || auditEntries.Count == 0)
            {
                return;
            }

            foreach (var auditEntry in auditEntries)
            {
                foreach (var prop in auditEntry.TemporaryProperties)
                {
                    var name = prop.Metadata.Name;
                    if (prop.Metadata.IsPrimaryKey())
                    {
                        auditEntry.KeyValues[name] = prop.CurrentValue!;
                    }
                    else
                    {
                        auditEntry.NewValues[name] = prop.CurrentValue!;
                    }
                }

                AuditTrails.Add(auditEntry.ToAudit());
            }

            await base.SaveChangesAsync(cancellationToken);
        }

        public void AddOutboxMessage<TNotification>(TNotification notification) where TNotification : class
        {
            if (notification == null)
            {
                throw new ArgumentNullException(nameof(notification));
            }

            var notificationType = notification.GetType();
            var typeName = notificationType.AssemblyQualifiedName
                ?? throw new InvalidOperationException($"Unable to resolve assembly-qualified name for {notificationType.FullName}.");

            OutboxMessages.Add(new OutboxMessage
            {
                Type = typeName,
                Payload = JsonSerializer.Serialize(notification, notificationType, OutboxSerializerOptions),
                OccurredOnUtc = _dateTimeService.NowUtc
            });
        }

        public void SetOriginalRowVersion<TEntity>(TEntity entity, byte[] rowVersion) where TEntity : class, IDataConcurrency
        {
            Entry(entity).Property(e => e.RowVersion).OriginalValue = rowVersion;
        }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            modelBuilder.ApplyConfigurationsFromAssembly(Assembly.GetExecutingAssembly());

            foreach (var entityType in modelBuilder.Model.GetEntityTypes())
            {
                var tableName = entityType.GetTableName();
                if (tableName != null && (tableName.StartsWith("AspNet") || entityType.ClrType.Namespace?.Contains("Identity") == true))
                {
                    if (tableName.StartsWith("AspNet"))
                    {
                        entityType.SetTableName(tableName.Substring(6));
                    }

                    if (Database.IsSqlServer())
                    {
                        entityType.SetSchema("Identity");
                    }
                }

                var decimalProperties = entityType.GetProperties()
                    .Where(p => p.ClrType == typeof(decimal) || p.ClrType == typeof(decimal?));

                foreach (var property in decimalProperties)
                {
                    property.SetPrecision(18);
                    property.SetScale(6);
                }

                if (typeof(ISoftDelete).IsAssignableFrom(entityType.ClrType))
                {
                    entityType.AddSoftDeleteQueryFilter();
                }
            }
        }

        public async Task StartTransaction(CancellationToken cancellationToken)
        {
            if (_dbContextTransaction != null)
            {
                throw new InvalidOperationException("Transaction already started.");
            }

            _dbContextTransaction = await Database.BeginTransactionAsync(cancellationToken);
        }

        public async Task CommitTransaction(CancellationToken cancellationToken)
        {
            if (_dbContextTransaction == null)
            {
                throw new InvalidOperationException("No transaction to commit.");
            }

            try
            {
                await _dbContextTransaction.CommitAsync(cancellationToken);
            }
            finally
            {
                await _dbContextTransaction.DisposeAsync();
                _dbContextTransaction = null;
            }
        }

        public async Task RollbackTransaction(CancellationToken cancellationToken)
        {
            if (_dbContextTransaction == null)
            {
                throw new InvalidOperationException("No transaction to rollback.");
            }

            try
            {
                await _dbContextTransaction.RollbackAsync(cancellationToken);
            }
            finally
            {
                await _dbContextTransaction.DisposeAsync();
                _dbContextTransaction = null;
            }
        }

        public override void Dispose()
        {
            _dbContextTransaction?.Dispose();
            base.Dispose();
        }
    }
}
