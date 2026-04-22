using FluentAssertions;
using MockQueryable.NSubstitute;
using NSubstitute;
using Microsoft.EntityFrameworkCore;
using NUnit.Framework;
using UMS.Application.Features.Categories.Commands.Delete;
using UMS.Application.Features.Categories.Queries.GetAllCategories;
using UMS.Application.Features.Categories.Queries.GetCategoryById;
using UMS.Application.Features.Categories.Queries.GetCategoriesPaged;
using UMS.Application.Interfaces.Common;
using UMS.Domain.Entities;
using UMS.Application.Dtos.Pagination;

namespace UMS.Tests.Application.Features.Categories
{
    [TestFixture]
    public class DeleteCategoryCommandHandlerTests
    {
        private IApplicationDbContext _dbContext;
        private ICacheService _cacheService;
        private DeleteCategoryCommandHandler _handler;

        [SetUp]
        public void SetUp()
        {
            _dbContext = Substitute.For<IApplicationDbContext>();
            _cacheService = Substitute.For<ICacheService>();
            _handler = new DeleteCategoryCommandHandler(_dbContext, _cacheService);
        }

        [Test]
        public async Task Handle_Should_ReturnSuccess_When_DeleteIsValid()
        {
            // Arrange
            var command = new DeleteCategoryCommand(1);
            var category = new Category().SetId(1);
            
            var categories = new List<Category> { category }.AsQueryable().BuildMockDbSet();
            _dbContext.Categories.Returns(categories);

            // Act
            var result = await _handler.Handle(command, CancellationToken.None);

            // Assert
            result.IsSuccessful.Should().BeTrue();
            _dbContext.Categories.Received(1).Remove(category);
            await _dbContext.SaveChangesAsync(Arg.Any<CancellationToken>()).Received(1);
        }

        [Test]
        public async Task Handle_Should_ReturnFail_When_CategoryHasChildren()
        {
            // Arrange
            var command = new DeleteCategoryCommand(1);
            var category = new Category { Children = new List<Category> { new Category().SetId(2) } }.SetId(1);
            
            var categories = new List<Category> { category }.AsQueryable().BuildMockDbSet();
            _dbContext.Categories.Returns(categories);

            // Act
            var result = await _handler.Handle(command, CancellationToken.None);

            // Assert
            result.IsSuccessful.Should().BeFalse();
            result.Messages.Should().Contain(x => x.Contains("children"));
        }
    }

    [TestFixture]
    public class CategoryQueryHandlersTests
    {
        private IApplicationDbContext _dbContext;
        private ICacheService _cacheService;

        [SetUp]
        public void SetUp()
        {
            _dbContext = Substitute.For<IApplicationDbContext>();
            _cacheService = Substitute.For<ICacheService>();
        }

        [Test]
        public async Task GetAllCategories_Should_ReturnFromCache_When_Available()
        {
            // Arrange
            var cachedData = new List<CategoryListDto> { new CategoryListDto(1, "Test", "test", null, 0) };
            _cacheService.TryGet(Arg.Any<string>(), out Arg.Any<List<CategoryListDto>>())
                .Returns(x => { x[1] = cachedData; return true; });

            var handler = new GetAllCategoriesQueryHandler(_dbContext, _cacheService);

            // Act
            var result = await handler.Handle(new GetAllCategoriesQuery(true), CancellationToken.None);

            // Assert
            result.Data.Should().BeEquivalentTo(cachedData);
            await _dbContext.Categories.DidNotReceive().ToListAsync(Arg.Any<CancellationToken>());
        }

        [Test]
        public async Task GetCategoryById_Should_ReturnCategory_When_Found()
        {
            // Arrange
            var category = new Category { Name = "Test", Slug = "test" }.SetId(1);
            var categories = new List<Category> { category }.AsQueryable().BuildMockDbSet();
            _dbContext.Categories.Returns(categories);

            var handler = new GetCategoryByIdQueryHandler(_dbContext);

            // Act
            var result = await handler.Handle(new GetCategoryByIdQuery(1), CancellationToken.None);

            // Assert
            result.IsSuccessful.Should().BeTrue();
            result.Data.Id.Should().Be(1);
        }

        [Test]
        public async Task GetCategoryById_Should_ReturnFail_When_NotFound()
        {
            // Arrange
            var categories = new List<Category>().AsQueryable().BuildMockDbSet();
            _dbContext.Categories.Returns(categories);

            var handler = new GetCategoryByIdQueryHandler(_dbContext);

            // Act
            var result = await handler.Handle(new GetCategoryByIdQuery(1), CancellationToken.None);

            // Assert
            result.IsSuccessful.Should().BeFalse();
            result.Messages.Should().Contain("Category not found.");
        }

        [Test]
        public async Task GetCategoriesPaged_Should_ReturnPagedResult_When_ValidRequest()
        {
            // Arrange
            var categories = new List<Category>
            {
                new Category { Name = "A", Slug = "a", IsActive = true }.SetId(1),
                new Category { Name = "B", Slug = "b", IsActive = true }.SetId(2),
                new Category { Name = "C", Slug = "c", IsActive = true }.SetId(3)
            }.AsQueryable().BuildMockDbSet();
            _dbContext.Categories.Returns(categories);

            var handler = new GetCategoriesPagedQueryHandler(_dbContext);
            var query = new GetCategoriesPagedQuery { PagedFilterRequest = new PagedFilterRequest { PageNumber = 1, PageSize = 2 } };

            // Act
            var result = await handler.Handle(query, CancellationToken.None);

            // Assert
            result.IsSuccessful.Should().BeTrue();
            result.Data.Data.Should().HaveCount(2);
            result.Data.TotalCount.Should().Be(3);
        }
    }
}
