using FluentValidation;
using Microsoft.EntityFrameworkCore;
using MyDent.Model.Requests;
using MyDent.Services.Database;

namespace MyDent.Services.Validators
{
    public class DentalServiceInsertValidator : AbstractValidator<DentalServiceInsertRequest>
    {
        public DentalServiceInsertValidator(MyDentDbContext dbContext)
        {
            RuleFor(x => x.Name)
                .NotEmpty().WithMessage("Name is required.")
                .MaximumLength(150).WithMessage("Name cannot exceed 150 characters.");

            RuleFor(x => x.Description)
                .MaximumLength(1000).WithMessage("Description cannot exceed 1000 characters.");

            RuleFor(x => x.Price)
                .GreaterThan(0).WithMessage("Price must be greater than 0.");

            RuleFor(x => x.DurationMinutes)
                .GreaterThan(0).WithMessage("DurationMinutes must be greater than 0.");

            RuleFor(x => x.ServiceCategoryId)
                .GreaterThan(0).WithMessage("ServiceCategoryId is required.")
                .MustAsync(async (id, cancellation) => await dbContext.ServiceCategories.AnyAsync(c => c.Id == id, cancellation))
                .WithMessage(x => $"ServiceCategory with id {x.ServiceCategoryId} does not exist.");

            RuleFor(x => x.ImageAssetId)
                .GreaterThan(0).WithMessage("ImageAssetId must be greater than 0.")
                .When(x => x.ImageAssetId.HasValue);
        }
    }
}
