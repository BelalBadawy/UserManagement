using UMS.Application.Features.Categories.Events;
using UMS.Application.Features.Categories.Commands;
using UMS.Application.Interfaces.Common;

namespace UMS.Application.Features.Categories.Commands.Create
{

    public record CreateCategoryCommand(
        string Name,
        string Slug,
        int? ParentId,
        bool IsActive,
        int SortOrder
    ) : IRequest<IResponseWrapper<int>>, IValidateMe;

    public class CreateCategoryCommandHandler(
        IApplicationDbContext applicationDbContext,
        ICacheService cacheService)
       : IRequestHandler<CreateCategoryCommand, IResponseWrapper<int>>
    {
        private readonly IApplicationDbContext _applicationDbContext = applicationDbContext;
        private readonly ICacheService _cacheService = cacheService;

        public async ValueTask<IResponseWrapper<int>> Handle(CreateCategoryCommand request, CancellationToken ct)
        {
            var normalizedName = CategoryWriteGuards.NormalizeKey(request.Name);
            var normalizedSlug = CategoryWriteGuards.NormalizeKey(request.Slug);

            var parentValidationError = await CategoryWriteGuards.ValidateParentAssignmentAsync(
                _applicationDbContext,
                categoryId: null,
                parentId: request.ParentId,
                ct);

            if (!string.IsNullOrWhiteSpace(parentValidationError))
            {
                return ResponseWrapper<int>.Fail(parentValidationError);
            }

            if (await _applicationDbContext.Categories.AnyAsync(
                    o => EF.Property<string>(o, "NormalizedName") == normalizedName,
                    ct))
            {
                return ResponseWrapper<int>.Fail("Category with this name already exists.");
            }

            if (await _applicationDbContext.Categories.AnyAsync(
                    o => EF.Property<string>(o, "NormalizedSlug") == normalizedSlug,
                    ct))
            {
                return ResponseWrapper<int>.Fail("Category with this slug already exists.");
            }

            var category = new Category
            {
                Name = request.Name.Trim(),
                Slug = request.Slug.Trim(),
                ParentId = request.ParentId,
                IsActive = request.IsActive,
                SortOrder = request.SortOrder
            };

            var transactionStarted = false;

            async Task TryRollbackAsync()
            {
                if (!transactionStarted)
                {
                    return;
                }

                try
                {
                    await _applicationDbContext.RollbackTransaction(ct);
                }
                catch (InvalidOperationException)
                {
                    // Transaction may already be completed/disposed.
                }
            }

            try
            {
                await _applicationDbContext.StartTransaction(ct);
                transactionStarted = true;

                await _applicationDbContext.Categories.AddAsync(category, ct);
                await _applicationDbContext.SaveChangesAsync(ct);

                _applicationDbContext.AddOutboxMessage(new CategoryCreatedEvent(category.Id));
                await _applicationDbContext.SaveChangesAsync(ct);

                await _applicationDbContext.CommitTransaction(ct);
                transactionStarted = false;
            }
            catch (DbUpdateException ex) when (CategoryWriteGuards.IsUniqueConstraintViolation(ex))
            {
                await TryRollbackAsync();
                return ResponseWrapper<int>.Fail(CategoryWriteGuards.GetUniqueConstraintMessage(ex));
            }
            catch
            {
                await TryRollbackAsync();
                throw;
            }

            foreach (var key in CategoryCacheKeys.All)
            {
                _cacheService.Remove(key);
            }

            return ResponseWrapper<int>.Success(category.Id, "Category created successfully.");
        }
    }
}
