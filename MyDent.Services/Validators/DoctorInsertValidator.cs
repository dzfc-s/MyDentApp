using FluentValidation;
using MyDent.Model.Requests;

namespace MyDent.Services.Validators
{
    public class DoctorInsertValidator : AbstractValidator<DoctorInsertRequest>
    {
        public DoctorInsertValidator()
        {
            RuleFor(x => x.FirstName)
                .NotEmpty().WithMessage("FirstName is required.")
                .MaximumLength(50).WithMessage("FirstName cannot exceed 50 characters.");

            RuleFor(x => x.LastName)
                .NotEmpty().WithMessage("LastName is required.")
                .MaximumLength(50).WithMessage("LastName cannot exceed 50 characters.");

            RuleFor(x => x.Bio)
                .MaximumLength(1000).WithMessage("Bio cannot exceed 1000 characters.");

            RuleFor(x => x.PhotoAssetId)
                .GreaterThan(0).WithMessage("PhotoAssetId must be greater than 0.")
                .When(x => x.PhotoAssetId.HasValue);
        }
    }
}
