using FluentValidation;
using MyDent.Model.Requests;

namespace MyDent.Services.Validators
{
    public class ServiceCategoryUpdateValidator : AbstractValidator<ServiceCategoryUpdateRequest>
    {
        public ServiceCategoryUpdateValidator()
        {
            RuleFor(x => x.Name)
                .NotEmpty().WithMessage("Name is required.")
                .MaximumLength(100).WithMessage("Name cannot exceed 100 characters.");

            RuleFor(x => x.Description)
                .MaximumLength(500).WithMessage("Description cannot exceed 500 characters.");
        }
    }
}
