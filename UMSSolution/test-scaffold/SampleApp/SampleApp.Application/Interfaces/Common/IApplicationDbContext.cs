using Microsoft.EntityFrameworkCore;
using SampleApp.Domain.Entities;
using SampleApp.Domain.Interfaces;

namespace SampleApp.Application.Interfaces.Common
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
        DbSet<User> Users { get; }
     

        void AddOutboxMessage<TNotification>(TNotification notification) where TNotification : class;
        void SetOriginalRowVersion<TEntity>(TEntity entity, byte[] rowVersion) where TEntity : class, IDataConcurrency;
    }
}