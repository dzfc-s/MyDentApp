using FluentValidation;
using Microsoft.EntityFrameworkCore;
using MyDent.Model.Requests;
using MyDent.Services.Database;

namespace MyDent.Services.Validators
{
    public class NewsInsertValidator : AbstractValidator<NewsInsertRequest>
    {
        public NewsInsertValidator(MyDentDbContext dbContext)
        {
            RuleFor(x => x.Title)
                .NotEmpty().WithMessage("Title is required.")
                .MaximumLength(200).WithMessage("Title cannot exceed 200 characters.");

            RuleFor(x => x.Content)
                .NotEmpty().WithMessage("Content is required.");

            RuleFor(x => x.ImageAssetId)
                .GreaterThan(0).WithMessage("ImageAssetId must be greater than 0.")
                .MustAsync(async (id, cancellation) => await dbContext.Assets.AnyAsync(a => a.Id == id, cancellation))
                .WithMessage(x => $"Asset with id {x.ImageAssetId} does not exist.")
                .When(x => x.ImageAssetId.HasValue);
        }
    }
}
