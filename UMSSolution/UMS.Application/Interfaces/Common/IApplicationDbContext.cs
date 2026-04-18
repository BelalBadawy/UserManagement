using UMS.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace UMS.Application.Interfaces.Common
{
    public interface IApplicationDbContext
    {
        Task StartTransaction(CancellationToken cancellationToken = default);
        Task CommitTransaction(CancellationToken cancellationToken = default);
        Task RollbackTransaction(CancellationToken cancellationToken = default);

        Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
        DbSet<Category> Categories { get; }
        DbSet<AuditTrail> AuditTrails { get; }
        DbSet<LogUserActivity> LogUserActivities { get; }
        DbSet<OutboxMessage> OutboxMessages { get; }
        DbSet<RefreshToken> RefreshTokens { get; }

        void AddOutboxMessage<TNotification>(TNotification notification) where TNotification : class;
    }
}
