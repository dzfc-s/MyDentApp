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
        }
    }
}
