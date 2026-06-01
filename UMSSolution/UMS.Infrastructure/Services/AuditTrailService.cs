using Microsoft.EntityFrameworkCore;
using UMS.Application.Dtos.Pagination;
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.AuditTrails;
using UMS.Application.Features.AuditTrails.Queries.GetAuditTrailsPaged;
using UMS.Application.Interfaces.Common;
using UMS.Infrastructure.Persistence.Contexts;

namespace UMS.Infrastructure.Services
{
    public class AuditTrailService(IApplicationDbContext context) : IAuditTrailService
    {
        private readonly IApplicationDbContext _context = context;

        public async Task<IResponseWrapper<PagedResult<AuditTrailResponse>>> GetAuditTrailsPagedQueryAsync(
            PagedFilterRequest pagedFilterRequest,
            CancellationToken ct)
        {
            var dbContext = _context as ApplicationDbContext;
            if (dbContext == null)
            {
                return ResponseWrapper<PagedResult<AuditTrailResponse>>.Fail("Invalid database context.");
            }

            var auditQuery = from audit in dbContext.AuditTrails
                             join user in dbContext.Users on audit.UserId equals user.Id into userGroup
                             from user in userGroup.DefaultIfEmpty()
                             select new { audit, UserEmail = user != null ? user.Email : null };

            // Apply SearchTerm filter
            if (!string.IsNullOrWhiteSpace(pagedFilterRequest.SearchTerm))
            {
                var term = pagedFilterRequest.SearchTerm.Trim();
                var pattern = $"%{term}%";
                
                auditQuery = auditQuery.Where(a =>
                    EF.Functions.Like(a.audit.TableName ?? "", pattern) ||
                    EF.Functions.Like(a.audit.IpAddress ?? "", pattern) ||
                    EF.Functions.Like(a.UserEmail ?? "", pattern)
                );
            }

            // Sorting
            auditQuery = pagedFilterRequest.SortBy?.ToLower() switch
            {
                "tablename" => pagedFilterRequest.SortDirection == "desc"
                    ? auditQuery.OrderByDescending(a => a.audit.TableName)
                    : auditQuery.OrderBy(a => a.audit.TableName),
                "type" => pagedFilterRequest.SortDirection == "desc"
                    ? auditQuery.OrderByDescending(a => a.audit.Type)
                    : auditQuery.OrderBy(a => a.audit.Type),
                "datetime" => pagedFilterRequest.SortDirection == "desc"
                    ? auditQuery.OrderByDescending(a => a.audit.DateTime)
                    : auditQuery.OrderBy(a => a.audit.DateTime),
                "id" => pagedFilterRequest.SortDirection == "desc"
                    ? auditQuery.OrderByDescending(a => a.audit.Id)
                    : auditQuery.OrderBy(a => a.audit.Id),
                _ => pagedFilterRequest.SortDirection == "asc"
                    ? auditQuery.OrderBy(a => a.audit.DateTime).ThenBy(a => a.audit.Id)
                    : auditQuery.OrderByDescending(a => a.audit.DateTime).ThenByDescending(a => a.audit.Id)
            };

            var totalCount = await auditQuery.CountAsync(ct);

            var auditTrails = await auditQuery
                .Skip((pagedFilterRequest.PageNumber - 1) * pagedFilterRequest.PageSize)
                .Take(pagedFilterRequest.PageSize)
                .Select(a => new AuditTrailResponse(
                    a.audit.Id,
                    a.audit.UserId,
                    a.UserEmail,
                    a.audit.IpAddress,
                    a.audit.Type.ToString(),
                    a.audit.TableName,
                    a.audit.DateTime,
                    a.audit.OldValues,
                    a.audit.NewValues,
                    a.audit.AffectedColumns,
                    a.audit.PrimaryKey
                ))
                .ToListAsync(ct);

            var pagedResult = PagedResult<AuditTrailResponse>.Create(
                auditTrails,
                totalCount,
                pagedFilterRequest.PageNumber,
                pagedFilterRequest.PageSize);

            return ResponseWrapper<PagedResult<AuditTrailResponse>>.Success(pagedResult);
        }
    }
}
