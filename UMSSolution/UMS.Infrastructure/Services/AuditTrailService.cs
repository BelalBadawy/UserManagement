using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using ClosedXML.Excel;
using Microsoft.EntityFrameworkCore;
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;
using UMS.Application.Dtos.Pagination;
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.AuditTrails;
using UMS.Application.Features.AuditTrails.Queries.GetAuditTrailsPaged;
using UMS.Application.Interfaces.Common;
using UMS.Domain.Enums;
using UMS.Infrastructure.Persistence.Contexts;

namespace UMS.Infrastructure.Services
{
    internal class AuditTrailQueryModel
    {
        public Domain.Entities.AuditTrail Audit { get; set; } = null!;
        public string? UserEmail { get; set; }
    }

    public class AuditTrailService(IApplicationDbContext context) : IAuditTrailService
    {
        private readonly IApplicationDbContext _context = context;

        private IQueryable<AuditTrailQueryModel> BuildAuditTrailQuery(GetAuditTrailsPagedQuery request)
        {
            var dbContext = _context as ApplicationDbContext;
            if (dbContext == null)
            {
                throw new InvalidOperationException("Invalid database context.");
            }

            var auditQuery = from audit in dbContext.AuditTrails
                             join user in dbContext.Users on audit.UserId equals user.Id into userGroup
                             from user in userGroup.DefaultIfEmpty()
                             select new AuditTrailQueryModel
                             {
                                 Audit = audit,
                                 UserEmail = user != null ? user.Email : null
                             };

            // Conditionally filter by UserId (exact match)
            if (request.UserId.HasValue)
            {
                auditQuery = auditQuery.Where(a => a.Audit.UserId == request.UserId.Value);
            }

            // Conditionally filter by TableName (exact match)
            if (!string.IsNullOrWhiteSpace(request.TableName))
            {
                auditQuery = auditQuery.Where(a => a.Audit.TableName == request.TableName.Trim());
            }

            // Conditionally filter by EntityId (PrimaryKey substring search)
            if (!string.IsNullOrWhiteSpace(request.EntityId))
            {
                var idTrimmed = request.EntityId.Trim();
                auditQuery = auditQuery.Where(a => a.Audit.PrimaryKey != null && a.Audit.PrimaryKey.Contains(idTrimmed));
            }

            // Conditionally filter by ActionTypes list
            if (!string.IsNullOrWhiteSpace(request.ActionTypes))
            {
                var typesList = request.ActionTypes.Split(',', StringSplitOptions.RemoveEmptyEntries)
                    .Select(t => Enum.TryParse<AuditType>(t.Trim(), true, out var result) ? result : (AuditType?)null)
                    .Where(t => t.HasValue)
                    .Select(t => t!.Value)
                    .ToList();

                if (typesList.Count > 0)
                {
                    auditQuery = auditQuery.Where(a => typesList.Contains(a.Audit.Type));
                }
            }

            // Conditionally filter by FromDate (inclusive)
            if (!string.IsNullOrWhiteSpace(request.FromDate) && DateTime.TryParseExact(request.FromDate.Trim(), "yyyy/MM/dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out var parsedFromDate))
            {
                auditQuery = auditQuery.Where(a => a.Audit.DateTime >= parsedFromDate);
            }

            // Conditionally filter by ToDate (inclusive, adjusted to end of day)
            if (!string.IsNullOrWhiteSpace(request.ToDate) && DateTime.TryParseExact(request.ToDate.Trim(), "yyyy/MM/dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out var parsedToDate))
            {
                var adjustedToDate = parsedToDate.Date.AddDays(1).AddTicks(-1);
                auditQuery = auditQuery.Where(a => a.Audit.DateTime <= adjustedToDate);
            }

            return auditQuery;
        }

        public async Task<IResponseWrapper<PagedResult<AuditTrailResponse>>> GetAuditTrailsPagedQueryAsync(
            PagedFilterRequest pagedFilterRequest,
            string? tableName,
            string? entityId,
            string? actionTypes,
            string? fromDate,
            string? toDate,
            int? userId,
            CancellationToken ct)
        {
            var auditQuery = BuildAuditTrailQuery(new GetAuditTrailsPagedQuery
                {
                    TableName = tableName,
                    EntityId = entityId,
                    ActionTypes = actionTypes,
                    FromDate = fromDate,
                    ToDate = toDate,
                    UserId = userId
                });

            // Apply SearchTerm filter
            if (!string.IsNullOrWhiteSpace(pagedFilterRequest.SearchTerm))
            {
                var term = pagedFilterRequest.SearchTerm.Trim();
                var pattern = $"%{term}%";

                auditQuery = auditQuery.Where(a =>
                    EF.Functions.Like(a.Audit.TableName ?? "", pattern) ||
                    EF.Functions.Like(a.Audit.IpAddress ?? "", pattern) ||
                    EF.Functions.Like(a.UserEmail ?? "", pattern)
                );
            }

            // Sorting
            auditQuery = pagedFilterRequest.SortBy?.ToLower() switch
            {
                "tablename" => pagedFilterRequest.SortDirection == "desc"
                    ? auditQuery.OrderByDescending(a => a.Audit.TableName)
                    : auditQuery.OrderBy(a => a.Audit.TableName),
                "type" => pagedFilterRequest.SortDirection == "desc"
                    ? auditQuery.OrderByDescending(a => a.Audit.Type)
                    : auditQuery.OrderBy(a => a.Audit.Type),
                "datetime" => pagedFilterRequest.SortDirection == "desc"
                    ? auditQuery.OrderByDescending(a => a.Audit.DateTime)
                    : auditQuery.OrderBy(a => a.Audit.DateTime),
                "id" => pagedFilterRequest.SortDirection == "desc"
                    ? auditQuery.OrderByDescending(a => a.Audit.Id)
                    : auditQuery.OrderBy(a => a.Audit.Id),
                _ => pagedFilterRequest.SortDirection == "asc"
                    ? auditQuery.OrderBy(a => a.Audit.DateTime).ThenBy(a => a.Audit.Id)
                    : auditQuery.OrderByDescending(a => a.Audit.DateTime).ThenByDescending(a => a.Audit.Id)
            };

            var totalCount = await auditQuery.CountAsync(ct);

            var auditTrails = await auditQuery
                .Skip((pagedFilterRequest.PageNumber - 1) * pagedFilterRequest.PageSize)
                .Take(pagedFilterRequest.PageSize)
                .Select(a => new AuditTrailResponse(
                    a.Audit.Id,
                    a.Audit.UserId,
                    a.UserEmail,
                    a.Audit.IpAddress,
                    a.Audit.Type.ToString(),
                    a.Audit.TableName,
                    a.Audit.DateTime,
                    a.Audit.OldValues,
                    a.Audit.NewValues,
                    a.Audit.AffectedColumns,
                    a.Audit.PrimaryKey
                ))
                .ToListAsync(ct);

            var pagedResult = PagedResult<AuditTrailResponse>.Create(
                auditTrails,
                totalCount,
                pagedFilterRequest.PageNumber,
                pagedFilterRequest.PageSize);

            return ResponseWrapper<PagedResult<AuditTrailResponse>>.Success(pagedResult);
        }

        public async Task<IResponseWrapper<List<AuditTrailResponse>>> GetAuditTrailsListAsync(
            string? tableName,
            string? entityId,
            string? actionTypes,
            string? fromDate,
            string? toDate,
            int? userId,
            CancellationToken ct)
        {
            var auditQuery = BuildAuditTrailQuery(new GetAuditTrailsPagedQuery
                {
                    TableName = tableName,
                    EntityId = entityId,
                    ActionTypes = actionTypes,
                    FromDate = fromDate,
                    ToDate = toDate,
                    UserId = userId
                });

            // Default sort descending by DateTime, then Id
            auditQuery = auditQuery.OrderByDescending(a => a.Audit.DateTime).ThenByDescending(a => a.Audit.Id);

            var auditTrails = await auditQuery
                .Select(a => new AuditTrailResponse(
                    a.Audit.Id,
                    a.Audit.UserId,
                    a.UserEmail,
                    a.Audit.IpAddress,
                    a.Audit.Type.ToString(),
                    a.Audit.TableName,
                    a.Audit.DateTime,
                    a.Audit.OldValues,
                    a.Audit.NewValues,
                    a.Audit.AffectedColumns,
                    a.Audit.PrimaryKey
                ))
                .ToListAsync(ct);

            return ResponseWrapper<List<AuditTrailResponse>>.Success(auditTrails);
        }

        public async Task<byte[]> ExportAuditTrailsAsync(List<AuditTrailResponse> data, string format, CancellationToken ct)
        {
            if (format.Equals("pdf", StringComparison.OrdinalIgnoreCase))
            {
                return GeneratePdfExport(data);
            }
            else
            {
                return GenerateExcelExport(data);
            }
        }

        private byte[] GenerateExcelExport(List<AuditTrailResponse> data)
        {
            using var workbook = new XLWorkbook();
            var worksheet = workbook.Worksheets.Add("Audit Logs");

            // Define headers
            worksheet.Cell(1, 1).Value = "ID";
            worksheet.Cell(1, 2).Value = "User Email";
            worksheet.Cell(1, 3).Value = "IP Address";
            worksheet.Cell(1, 4).Value = "Type";
            worksheet.Cell(1, 5).Value = "Table Name";
            worksheet.Cell(1, 6).Value = "DateTime (UTC)";
            worksheet.Cell(1, 7).Value = "PrimaryKey";
            worksheet.Cell(1, 8).Value = "Affected Columns";
            worksheet.Cell(1, 9).Value = "Old Values";
            worksheet.Cell(1, 10).Value = "New Values";

            // Format Header Row
            var headerRange = worksheet.Range(1, 1, 1, 10);
            headerRange.Style.Font.Bold = true;
            headerRange.Style.Fill.BackgroundColor = XLColor.FromHtml("#4F46E5"); // Indigo-600
            headerRange.Style.Font.FontColor = XLColor.White;
            headerRange.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;

            // Populate rows
            int row = 2;
            foreach (var log in data)
            {
                worksheet.Cell(row, 1).Value = log.Id;
                worksheet.Cell(row, 2).Value = log.UserEmail ?? "System / Guest";
                worksheet.Cell(row, 3).Value = log.IpAddress ?? "N/A";
                worksheet.Cell(row, 4).Value = log.Type;
                worksheet.Cell(row, 5).Value = log.TableName ?? "N/A";
                worksheet.Cell(row, 6).Value = log.DateTime;
                worksheet.Cell(row, 6).Style.DateFormat.Format = "yyyy-MM-dd HH:mm:ss";
                worksheet.Cell(row, 7).Value = log.PrimaryKey ?? "N/A";
                worksheet.Cell(row, 8).Value = log.AffectedColumns ?? "N/A";
                worksheet.Cell(row, 9).Value = log.OldValues ?? "";
                worksheet.Cell(row, 10).Value = log.NewValues ?? "";
                row++;
            }

            // Auto-fit columns
            worksheet.Columns().AdjustToContents();

            using var stream = new MemoryStream();
            workbook.SaveAs(stream);
            return stream.ToArray();
        }

        private byte[] GeneratePdfExport(List<AuditTrailResponse> data)
        {
            var document = Document.Create(container =>
            {
                container.Page(page =>
                {
                    page.Size(PageSizes.A4.Landscape());
                    page.Margin(1.5f, Unit.Centimetre);
                    page.PageColor(Colors.White);
                    page.DefaultTextStyle(x => x.FontSize(8).FontFamily("Helvetica"));

                    // Header
                    page.Header()
                        .PaddingBottom(10)
                        .Text("Audit Trails Report")
                        .SemiBold().FontSize(16).FontColor(Colors.Indigo.Medium);

                    // Content
                    page.Content()
                        .Table(table =>
                        {
                            // Columns definition
                            table.ColumnsDefinition(columns =>
                            {
                                columns.ConstantColumn(35); // ID
                                columns.RelativeColumn(2.5f); // User Email
                                columns.RelativeColumn(1.2f); // Type
                                columns.RelativeColumn(2f); // Table Name
                                columns.RelativeColumn(1.5f); // IP Address
                                columns.RelativeColumn(2.5f); // DateTime
                                columns.RelativeColumn(1.5f); // Primary Key
                            });

                            // Table Header
                            table.Header(header =>
                            {
                                header.Cell().Element(HeaderStyle).Text("ID").SemiBold().FontColor(Colors.White);
                                header.Cell().Element(HeaderStyle).Text("User Email").SemiBold().FontColor(Colors.White);
                                header.Cell().Element(HeaderStyle).Text("Type").SemiBold().FontColor(Colors.White);
                                header.Cell().Element(HeaderStyle).Text("Table Name").SemiBold().FontColor(Colors.White);
                                header.Cell().Element(HeaderStyle).Text("IP Address").SemiBold().FontColor(Colors.White);
                                header.Cell().Element(HeaderStyle).Text("DateTime (UTC)").SemiBold().FontColor(Colors.White);
                                header.Cell().Element(HeaderStyle).Text("Primary Key").SemiBold().FontColor(Colors.White);

                                static IContainer HeaderStyle(IContainer container)
                                {
                                    return container
                                        .Background(Colors.Indigo.Medium)
                                        .Padding(6)
                                        .AlignMiddle();
                                }
                            });

                            // Table Rows
                            foreach (var log in data)
                            {
                                table.Cell().Element(CellStyle).Text(log.Id.ToString());
                                table.Cell().Element(CellStyle).Text(log.UserEmail ?? "System / Guest");
                                table.Cell().Element(CellStyle).Text(log.Type);
                                table.Cell().Element(CellStyle).Text(log.TableName ?? "N/A");
                                table.Cell().Element(CellStyle).Text(log.IpAddress ?? "N/A");
                                table.Cell().Element(CellStyle).Text(log.DateTime.ToString("yyyy-MM-dd HH:mm:ss"));
                                table.Cell().Element(CellStyle).Text(log.PrimaryKey ?? "N/A");

                                static IContainer CellStyle(IContainer container)
                                {
                                    return container
                                        .BorderBottom(0.5f)
                                        .BorderColor(Colors.Grey.Lighten3)
                                        .Padding(6)
                                        .AlignMiddle();
                                }
                            }
                        });

                    // Footer
                    page.Footer()
                        .PaddingTop(10)
                        .AlignCenter()
                        .Text(x =>
                        {
                            x.Span("Page ");
                            x.CurrentPageNumber();
                            x.Span(" of ");
                            x.TotalPages();
                        });
                });
            });

            using var stream = new MemoryStream();
            document.GeneratePdf(stream);
            return stream.ToArray();
        }
    }
}
