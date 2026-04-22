using FluentAssertions;
using MockQueryable.NSubstitute;
using NSubstitute;
using UMS.Application.Features.Categories.Commands.Create;
using UMS.Application.Features.Categories.Commands.Update;
using UMS.Application.Interfaces.Common;
using UMS.Domain.Entities;
using UMS.Application.Dtos.Wrappers;
using Microsoft.EntityFrameworkCore;
using NUnit.Framework;

namespace UMS.Tests.Application.Features.Categories.Commands
{
    [TestFixture]
    public class CreateCategoryCommandHandlerTests
    {
        private IApplicationDbContext _dbContext;
        private ICacheService _cacheService;
        private CreateCategoryCommandHandler _handler;

        [SetUp]
        public void SetUp()
        {
            _dbContext = Substitute.For<IApplicationDbContext>();
            _cacheService = Substitute.For<ICacheService>();
            _handler = new CreateCategoryCommandHandler(_dbContext, _cacheService);
        }

        [Test]
        public async Task Handle_Should_ReturnSuccess_When_RequestIsValid()
        {
            // Arrange
            var command = new CreateCategoryCommand(
                "New Category",
                "new-category",
                null,
                true,
                1
            );

            var categories = new List<Category>().AsQueryable().BuildMockDbSet();
            _dbContext.Categories.Returns(categories);

            // Act
            var result = await _handler.Handle(command, CancellationToken.None);

            // Assert
            result.IsSuccessful.Should().BeTrue();
            await _dbContext.Categories.Received(1).AddAsync(Arg.Any<Category>(), Arg.Any<CancellationToken>());
            await _dbContext.SaveChangesAsync(Arg.Any<CancellationToken>()).Received(1);
            _cacheService.Received(1).Remove(Arg.Any<string>());
        }

        [Test]
        public async Task Handle_Should_ReturnFail_When_NameAlreadyExists()
        {
            // Arrange
            var command = new CreateCategoryCommand("Existing", "new", null, true, 0);
            var existingCategory = new Category { Name = "Existing" }.SetId(1);
            
            // Note: Since NormalizedName is a shadow property and not on the entity, 
            // the handler code using EF.Property might fail if not handled.
            // For now, we mock the DbSet to return a category.
            var categories = new List<Category> { existingCategory }.AsQueryable().BuildMockDbSet();
            _dbContext.Categories.Returns(categories);

            // Act
            var result = await _handler.Handle(command, CancellationToken.None);

            // Assert
            result.IsSuccessful.Should().BeFalse();
            result.Messages.Should().Contain("Category with this name already exists.");
        }
    }

    [TestFixture]
    public class UpdateCategoryCommandHandlerTests
    {
        private IApplicationDbContext _dbContext;
        private ICacheService _cacheService;
        private UpdateCategoryCommandHandler _handler;

        [SetUp]
        public void SetUp()
        {
            _dbContext = Substitute.For<IApplicationDbContext>();
            _cacheService = Substitute.For<ICacheService>();
            _handler = new UpdateCategoryCommandHandler(_dbContext, _cacheService);
        }

        [Test]
        public async Task Handle_Should_ReturnSuccess_When_UpdateIsValid()
        {
            // Arrange
            var command = new UpdateCategoryCommand(1, "Updated", "updated", null, true, 0, Array.Empty<byte>());
            var category = new Category { Name = "Old", Slug = "old" }.SetId(1);
            
            var categories = new List<Category> { category }.AsQueryable().BuildMockDbSet();
            _dbContext.Categories.Returns(categories);

            // Act
            var result = await _handler.Handle(command, CancellationToken.None);

            // Assert
            result.IsSuccessful.Should().BeTrue();
            category.Name.Should().Be("Updated");
            await _dbContext.SaveChangesAsync(Arg.Any<CancellationToken>()).Received(1);
        }

        [Test]
        public async Task Handle_Should_ReturnFail_When_CategoryNotFound()
        {
            // Arrange
            var command = new UpdateCategoryCommand(999, "", "", null, true, 0, Array.Empty<byte>());
            var categories = new List<Category>().AsQueryable().BuildMockDbSet();
            _dbContext.Categories.Returns(categories);

            // Act
            var result = await _handler.Handle(command, CancellationToken.None);

            // Assert
            result.IsSuccessful.Should().BeFalse();
            result.Messages.Should().Contain("Category not found.");
        }
    }
}
