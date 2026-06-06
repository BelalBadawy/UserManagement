using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using FluentAssertions;
using Moq;
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Categories;
using UMS.Application.Features.Categories.Queries.ExportCategories;
using UMS.Application.Features.Categories.Queries.GetCategoriesPaged;
using Xunit;

namespace UMS.Application.Tests.Handlers.Categories
{
    public class ExportCategoriesQueryHandlerTests
    {
        private readonly Mock<ICategoryService> _categoryService = new();

        [Fact]
        public async Task Handle_should_return_file_bytes_when_successful()
        {
            var query = new ExportCategoriesQuery
            {
                SearchTerm = "test",
                IsActive = true,
                SortBy = "name",
                SortDirection = "asc",
                ExportFormat = "excel"
            };

            var categories = new List<CategoryResponse>
            {
                new(1, "Test 1", "test-1", null, 1, true, System.Array.Empty<byte>()),
                new(2, "Test 2", "test-2", null, 2, true, System.Array.Empty<byte>())
            };

            var fileBytes = new byte[] { 1, 2, 3 };

            _categoryService
                .Setup(s => s.GetCategoriesListAsync("test", true, "name", "asc", It.IsAny<CancellationToken>()))
                .ReturnsAsync(ResponseWrapper<List<CategoryResponse>>.Success(categories));

            _categoryService
                .Setup(s => s.ExportCategoriesAsync(categories, "excel", It.IsAny<CancellationToken>()))
                .ReturnsAsync(fileBytes);

            var handler = new ExportCategoriesQueryHandler(_categoryService.Object);

            var result = await handler.Handle(query, CancellationToken.None);

            result.IsSuccessful.Should().BeTrue();
            result.Data.Should().BeEquivalentTo(fileBytes);
            _categoryService.Verify(s => s.GetCategoriesListAsync("test", true, "name", "asc", CancellationToken.None), Times.Once);
            _categoryService.Verify(s => s.ExportCategoriesAsync(categories, "excel", CancellationToken.None), Times.Once);
        }

        [Fact]
        public async Task Handle_should_return_failure_when_list_retrieval_fails()
        {
            var query = new ExportCategoriesQuery
            {
                SearchTerm = "test",
                ExportFormat = "pdf"
            };

            _categoryService
                .Setup(s => s.GetCategoriesListAsync("test", null, null, null, It.IsAny<CancellationToken>()))
                .ReturnsAsync(ResponseWrapper<List<CategoryResponse>>.Fail("Failed", 400));

            var handler = new ExportCategoriesQueryHandler(_categoryService.Object);

            var result = await handler.Handle(query, CancellationToken.None);

            result.IsSuccessful.Should().BeFalse();
            result.Messages.Should().Contain("Failed");
            _categoryService.Verify(s => s.GetCategoriesListAsync("test", null, null, null, CancellationToken.None), Times.Once);
            _categoryService.Verify(s => s.ExportCategoriesAsync(It.IsAny<List<CategoryResponse>>(), It.IsAny<string>(), It.IsAny<CancellationToken>()), Times.Never);
        }
    }
}
