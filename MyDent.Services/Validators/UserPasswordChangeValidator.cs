using FluentValidation;
using MyDent.Model.Requests;

namespace MyDent.Services.Validators
{
    public class UserPasswordChangeValidator : AbstractValidator<UserPasswordChangeRequest>
    {
        public UserPasswordChangeValidator()
        {
            RuleFor(x => x.Password)
                .NotEmpty().WithMessage("Current password is required.");

            // Same 6-char floor as UserInsertValidator's Password rule — registration enforces
            // this, but changing password had no equivalent, so a user could otherwise change
            // into a 1-character password even though sign-up never allows one.
            RuleFor(x => x.NewPassword)
                .NotEmpty().WithMessage("New password is required.")
                .MinimumLength(6).WithMessage("New password must be at least 6 characters.")
                .MaximumLength(100).WithMessage("New password cannot exceed 100 characters.");

            RuleFor(x => x.ConfirmNewPassword)
                .NotEmpty().WithMessage("Password confirmation is required.");
        }
    }
}
