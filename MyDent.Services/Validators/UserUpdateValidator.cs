using MyDent.Model.Requests;
using FluentValidation;

namespace MyDent.Services.Validators
{
    public class UserUpdateValidator : AbstractValidator<UserUpdateRequest>
    {
        public UserUpdateValidator()
        {
           
            RuleFor(x => x.FirstName)
                .NotEmpty().WithMessage("First name is required.")
                .MaximumLength(50).WithMessage("First name cannot exceed 50 characters.");

            RuleFor(x => x.ProfileImageAssetId)
                .GreaterThan(0).WithMessage("ProfileImageAssetId must be greater than 0.")
                .When(x => x.ProfileImageAssetId.HasValue);

            RuleFor(x => x.Allergies)
                .MaximumLength(500).WithMessage("Allergies cannot exceed 500 characters.");

            RuleFor(x => x.BloodType)
                .MaximumLength(10).WithMessage("BloodType cannot exceed 10 characters.");

            RuleFor(x => x.MedicalNotes)
                .MaximumLength(2000).WithMessage("MedicalNotes cannot exceed 2000 characters.");
        }
    }
}
