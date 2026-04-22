using FluentAssertions;
using Microsoft.EntityFrameworkCore;
using MockQueryable.NSubstitute;
using NSubstitute;
using UMS.Application.Features.Categories.Commands;
using UMS.Application.Interfaces.Common;
using UMS.Domain.Entities;

namespace UMS.Tests.Application.Features.Categories.Commands
{
    [TestFixture]
    public class CategoryWriteGuardsTests
    {
        [Test]
        public void NormalizeKey_Should_TrimAndUppercase()
        {
            // Arrange
            var input = "  Category Name  ";
            var expected = "CATEGORY NAME";

            // Act
            var result = CategoryWriteGuards.NormalizeKey(input);

            // Assert
            result.Should().Be(expected);
        }

        [Test]
        public void IsUniqueConstraintViolation_Should_ReturnTrue_When_ExceptionContainsUniqueConstraint()
        {
            // Arrange
            var exception = new DbUpdateException("UNIQUE KEY constraint violation", new Exception("UX_Categories_NormalizedName"));

            // Act
            var result = CategoryWriteGuards.IsUniqueConstraintViolation(exception);

            // Assert
            result.Should().BeTrue();
        }

        [Test]
        public void GetUniqueConstraintMessage_Should_ReturnSpecificMessage_For_NormalizedName()
        {
            // Arrange
            var exception = new DbUpdateException("Error", new Exception("UX_Categories_NormalizedName"));

            // Act
            var result = CategoryWriteGuards.GetUniqueConstraintMessage(exception);

            // Assert
            result.Should().Be("Category with this name already exists.");
        }

        [Test]
        public async Task ValidateParentAssignmentAsync_Should_ReturnNull_When_ParentIdIsNull()
        {
            // Arrange
            var dbContext = Substitute.For<IApplicationDbContext>();

            // Act
            var result = await CategoryWriteGuards.ValidateParentAssignmentAsync(dbContext, 1, null, CancellationToken.None);

            // Assert
            result.Should().BeNull();
        }

        [Test]
        public async Task ValidateParentAssignmentAsync_Should_ReturnError_When_SelfReferencing()
        {
            // Arrange
            var dbContext = Substitute.For<IApplicationDbContext>();

            // Act
            var result = await CategoryWriteGuards.ValidateParentAssignmentAsync(dbContext, 1, 1, CancellationToken.None);

            // Assert
            result.Should().Be("A category cannot be its own parent.");
        }

        [Test]
        public async Task ValidateParentAssignmentAsync_Should_ReturnError_When_ParentNotFound()
        {
            // Arrange
            var dbContext = Substitute.For<IApplicationDbContext>();
            var categories = new List<Category>().AsQueryable().BuildMockDbSet();
            dbContext.Categories.Returns(categories);

            // Act
            var result = await CategoryWriteGuards.ValidateParentAssignmentAsync(dbContext, 1, 2, CancellationToken.None);

            // Assert
            result.Should().Be("Selected parent category does not exist.");
        }

        [Test]
        public async Task ValidateParentAssignmentAsync_Should_ReturnError_When_CircularHierarchyDetected()
        {
            // Arrange
            var dbContext = Substitute.For<IApplicationDbContext>();
            var categories = new List<Category>
            {
                new Category { ParentId = 3 }.SetId(2),
                new Category { ParentId = 2 }.SetId(3)
            }.AsQueryable().BuildMockDbSet();
            dbContext.Categories.Returns(categories);

            // Act
            var result = await CategoryWriteGuards.ValidateParentAssignmentAsync(dbContext, 1, 2, CancellationToken.None);

            // Assert
            result.Should().Be("Category hierarchy contains a cycle. Please select a valid parent category.");
        }

        [Test]
        public async Task ValidateParentAssignmentAsync_Should_ReturnError_When_AssignedToDescendant()
        {
            // Arrange
            var dbContext = Substitute.For<IApplicationDbContext>();
            var categories = new List<Category>
            {
                new Category { ParentId = 3 }.SetId(2),
                new Category { ParentId = 1 }.SetId(3) // 3 is descendant of 1
            }.AsQueryable().BuildMockDbSet();
            dbContext.Categories.Returns(categories);

            // Act
            var result = await CategoryWriteGuards.ValidateParentAssignmentAsync(dbContext, 1, 2, CancellationToken.None);

            // Assert
            result.Should().Be("A category cannot be assigned to one of its descendants.");
        }

        [Test]
        public async Task ValidateParentAssignmentAsync_Should_ReturnNull_When_HierarchyIsValid()
        {
            // Arrange
            var dbContext = Substitute.For<IApplicationDbContext>();
            var categories = new List<Category>
            {
                new Category { ParentId = 3 }.SetId(2),
                new Category { ParentId = null }.SetId(3)
            }.AsQueryable().BuildMockDbSet();
            dbContext.Categories.Returns(categories);

            // Act
            var result = await CategoryWriteGuards.ValidateParentAssignmentAsync(dbContext, 1, 2, CancellationToken.None);

            // Assert
            result.Should().BeNull();
        }
    }
}
