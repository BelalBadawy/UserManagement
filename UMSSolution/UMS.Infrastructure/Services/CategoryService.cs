using System;
using System.Collections.Generic;
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
using UMS.Application.Features.Categories;
using UMS.Application.Features.Categories.Queries.GetCategoriesPaged;
using UMS.Application.Interfaces.Common;
using UMS.Domain.Entities;

namespace UMS.Infrastructure.Services
{
    public class CategoryService(
        IApplicationDbContext applicationDbContext,
        ICurrentUserService currentUserService)
        : ICategoryService
    {
        private readonly IApplicationDbContext _applicationDbContext = applicationDbContext;
        private readonly ICurrentUserService _currentUserService = currentUserService;

        private IQueryable<Category> BuildCategoryQuery(GetCategoriesPagedQuery query)
        {
            var request = query.PagedFilterRequest;
            var categoriesQuery = _applicationDbContext.Categories.AsNoTracking();

            // Status Filtering
            if (request.IsActive.HasValue)
            {
                categoriesQuery = categoriesQuery.Where(c => c.IsActive == request.IsActive.Value);
            }
            else
            {
                // For anonymous or non-privileged requests, show only active categories.
                if (!_currentUserService.IsAuthenticated() || !_currentUserService.HasClaim("permission", "Permission.Product.Categories.Read"))
                {
                    categoriesQuery = categoriesQuery.Where(c => c.IsActive);
                }
            }

            // Search Term Filtering
            if (!string.IsNullOrWhiteSpace(request.SearchTerm))
            {
                var term = request.SearchTerm.Trim();
                var pattern = $"%{term}%";
                categoriesQuery = categoriesQuery.Where(c =>
                    EF.Functions.Like(c.Name, pattern) ||
                    EF.Functions.Like(c.Slug, pattern));
            }

            return categoriesQuery;
        }

        private IQueryable<Category> ApplySorting(IQueryable<Category> query, string? sortBy, string? sortDirection)
        {
            return sortBy?.ToLower() switch
            {
                "name" => (sortDirection ?? "asc").Equals("desc", StringComparison.OrdinalIgnoreCase)
                    ? query.OrderByDescending(c => c.Name)
                    : query.OrderBy(c => c.Name),
                "slug" => (sortDirection ?? "asc").Equals("desc", StringComparison.OrdinalIgnoreCase)
                    ? query.OrderByDescending(c => c.Slug)
                    : query.OrderBy(c => c.Slug),
                "sortorder" => (sortDirection ?? "asc").Equals("desc", StringComparison.OrdinalIgnoreCase)
                    ? query.OrderByDescending(c => c.SortOrder)
                    : query.OrderBy(c => c.SortOrder),
                "id" => (sortDirection ?? "asc").Equals("desc", StringComparison.OrdinalIgnoreCase)
                    ? query.OrderByDescending(c => c.Id)
                    : query.OrderBy(c => c.Id),
                _ => (sortDirection ?? "asc").Equals("desc", StringComparison.OrdinalIgnoreCase)
                    ? query.OrderByDescending(c => c.SortOrder).ThenBy(c => c.Name)
                    : query.OrderBy(c => c.SortOrder).ThenBy(c => c.Name)
            };
        }

        public async Task<IResponseWrapper<PagedResult<CategoryResponse>>> GetCategoriesPagedQueryAsync(
            PagedFilterRequest pagedFilterRequest,
            CancellationToken ct)
        {
            var query = BuildCategoryQuery(new GetCategoriesPagedQuery { PagedFilterRequest = pagedFilterRequest });
            query = ApplySorting(query, pagedFilterRequest.SortBy, pagedFilterRequest.SortDirection);

            var totalCount = await query.CountAsync(ct);

            var categories = await query
                .Skip((pagedFilterRequest.PageNumber - 1) * pagedFilterRequest.PageSize)
                .Take(pagedFilterRequest.PageSize)
                .Select(c => new CategoryResponse(
                    c.Id,
                    c.Name,
                    c.Slug,
                    c.ParentId,
                    c.SortOrder,
                    c.IsActive,
                    c.RowVersion
                ))
                .ToListAsync(ct);

            var pagedResult = PagedResult<CategoryResponse>.Create(
                categories,
                totalCount,
                pagedFilterRequest.PageNumber,
                pagedFilterRequest.PageSize);

            return ResponseWrapper<PagedResult<CategoryResponse>>.Success(pagedResult);
        }

        public async Task<IResponseWrapper<List<CategoryResponse>>> GetCategoriesListAsync(
            string? searchTerm,
            bool? isActive,
            string? sortBy,
            string? sortDirection,
            CancellationToken ct)
        {
            var query = BuildCategoryQuery(new GetCategoriesPagedQuery { PagedFilterRequest = new PagedFilterRequest { SearchTerm = searchTerm, IsActive = isActive } });
            query = ApplySorting(query, sortBy, sortDirection);

            var categories = await query
                .Select(c => new CategoryResponse(
                    c.Id,
                    c.Name,
                    c.Slug,
                    c.ParentId,
                    c.SortOrder,
                    c.IsActive,
                    c.RowVersion
                ))
                .ToListAsync(ct);

            return ResponseWrapper<List<CategoryResponse>>.Success(categories);
        }

        public async Task<byte[]> ExportCategoriesAsync(List<CategoryResponse> data, string format, CancellationToken ct)
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

        private byte[] GenerateExcelExport(List<CategoryResponse> data)
        {
            using var workbook = new XLWorkbook();
            var worksheet = workbook.Worksheets.Add("Categories");

            worksheet.Cell(1, 1).Value = "ID";
            worksheet.Cell(1, 2).Value = "Name";
            worksheet.Cell(1, 3).Value = "Slug";
            worksheet.Cell(1, 4).Value = "Parent Category ID";
            worksheet.Cell(1, 5).Value = "Sort Order";
            worksheet.Cell(1, 6).Value = "Status";

            var headerRange = worksheet.Range(1, 1, 1, 6);
            headerRange.Style.Font.Bold = true;
            headerRange.Style.Fill.BackgroundColor = XLColor.FromHtml("#4F46E5"); // Indigo-600
            headerRange.Style.Font.FontColor = XLColor.White;
            headerRange.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;

            int row = 2;
            foreach (var item in data)
            {
                worksheet.Cell(row, 1).Value = item.Id;
                worksheet.Cell(row, 2).Value = item.Name;
                worksheet.Cell(row, 3).Value = item.Slug;
                worksheet.Cell(row, 4).Value = item.ParentId.HasValue ? item.ParentId.Value.ToString() : "Root";
                worksheet.Cell(row, 5).Value = item.SortOrder;
                worksheet.Cell(row, 6).Value = item.IsActive ? "Active" : "Inactive";
                row++;
            }

            worksheet.Columns().AdjustToContents();

            using var stream = new MemoryStream();
            workbook.SaveAs(stream);
            return stream.ToArray();
        }

        private byte[] GeneratePdfExport(List<CategoryResponse> data)
        {
            var document = Document.Create(container =>
            {
                container.Page(page =>
                {
                    page.Size(PageSizes.A4.Landscape());
                    page.Margin(1.5f, Unit.Centimetre);
                    page.PageColor(Colors.White);
                    page.DefaultTextStyle(x => x.FontSize(9).FontFamily("Helvetica"));

                    page.Header()
                        .PaddingBottom(10)
                        .Text("Product Categories Report")
                        .SemiBold().FontSize(16).FontColor(Colors.Indigo.Medium);

                    page.Content()
                        .Table(table =>
                        {
                            table.ColumnsDefinition(columns =>
                            {
                                columns.ConstantColumn(40); // ID
                                columns.RelativeColumn(3f); // Name
                                columns.RelativeColumn(3f); // Slug
                                columns.RelativeColumn(2f); // Parent Category ID
                                columns.RelativeColumn(1.5f); // Sort Order
                                columns.RelativeColumn(1.5f); // Status
                            });

                            table.Header(header =>
                            {
                                header.Cell().Element(HeaderStyle).Text("ID").SemiBold().FontColor(Colors.White);
                                header.Cell().Element(HeaderStyle).Text("Name").SemiBold().FontColor(Colors.White);
                                header.Cell().Element(HeaderStyle).Text("Slug").SemiBold().FontColor(Colors.White);
                                header.Cell().Element(HeaderStyle).Text("Parent ID").SemiBold().FontColor(Colors.White);
                                header.Cell().Element(HeaderStyle).Text("Sort Order").SemiBold().FontColor(Colors.White);
                                header.Cell().Element(HeaderStyle).Text("Status").SemiBold().FontColor(Colors.White);

                                static IContainer HeaderStyle(IContainer container)
                                {
                                    return container
                                        .Background(Colors.Indigo.Medium)
                                        .Padding(6)
                                        .AlignMiddle();
                                }
                            });

                            foreach (var item in data)
                            {
                                table.Cell().Element(CellStyle).Text(item.Id.ToString());
                                table.Cell().Element(CellStyle).Text(item.Name);
                                table.Cell().Element(CellStyle).Text(item.Slug);
                                table.Cell().Element(CellStyle).Text(item.ParentId.HasValue ? item.ParentId.Value.ToString() : "None");
                                table.Cell().Element(CellStyle).Text(item.SortOrder.ToString());
                                table.Cell().Element(CellStyle).Text(item.IsActive ? "Active" : "Inactive");

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
