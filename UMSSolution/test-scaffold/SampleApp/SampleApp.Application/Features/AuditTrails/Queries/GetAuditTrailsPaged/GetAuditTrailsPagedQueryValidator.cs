using FluentValidation;
using SampleApp.Application.Dtos.Pagination;
using System.Linq;

namespace SampleApp.Application.Features.AuditTrails.Queries.GetAuditTrailsPaged
{
    public class GetAuditTrailsPagedQueryValidator : AbstractValidator<GetAuditTrailsPagedQuery>
    {
        public GetAuditTrailsPagedQueryValidator()
        {
            RuleFor(x => x.PagedFilterRequest)
                .SetValidator(new PagedFilterValidator());

            RuleFor(x => x.PagedFilterRequest.SortBy)
                .Must(field => string.IsNullOrEmpty(field) || new[] { "tablename", "type", "datetime", "id" }.Contains(field.ToLower()))
                .WithMessage("Invalid SortBy value");
        }
    }
}