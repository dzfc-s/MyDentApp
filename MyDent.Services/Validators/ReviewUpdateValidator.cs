using FluentValidation;
using Microsoft.EntityFrameworkCore;
using MyDent.Model.Requests;
using MyDent.Services.Database;

namespace MyDent.Services.Validators
{
    public class ReviewUpdateValidator : AbstractValidator<ReviewUpdateRequest>
    {
        public ReviewUpdateValidator(MyDentDbContext dbContext, IAuthenticatedUserAccessor userAccessor)
        {
            RuleFor(x => x.Comment)
               .MaximumLength(1000).WithMessage("Comment cannot exceed 1000 characters.");

            RuleFor(x => x.Rating)
                .InclusiveBetween(1, 5).WithMessage("Rating must be between 1 and 5.");
            
            // Only fails when IsApproved is actually being set (id.HasValue) and the caller
            // isn't an Admin — leaving IsApproved null (the patient-editing-own-review path)
            // must pass regardless of role.
            RuleFor(x => x.IsApproved)
                .Must(id => !id.HasValue || userAccessor.IsInRole("Admin"))
                .WithMessage("You can only approve reviews as an admin.");

        }
    }
}
