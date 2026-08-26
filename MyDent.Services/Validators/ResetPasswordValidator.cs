using FluentValidation;
using MyDent.Model.Requests;

namespace MyDent.Services.Validators
{
    public class ResetPasswordValidator : AbstractValidator<ResetPasswordRequest>
    {
        public ResetPasswordValidator()
        {
            RuleFor(x => x.Email)
                .NotEmpty().WithMessage("Email is required.")
                .EmailAddress().WithMessage("Email must be a valid email address.");

            RuleFor(x => x.Code)
                .NotEmpty().WithMessage("Code is required.")
                .Matches(@"^\d{6}$").WithMessage("Code must be 6 digits.");

            // Same 6-char floor as UserInsertValidator's Password rule — registration enforces
            // this, but ResetPassword had no equivalent, so a reset could otherwise set a
            // 1-character password even though sign-up never allows one.
            RuleFor(x => x.NewPassword)
                .NotEmpty().WithMessage("New password is required.")
                .MinimumLength(6).WithMessage("New password must be at least 6 characters.")
                .MaximumLength(100).WithMessage("New password cannot exceed 100 characters.");

            RuleFor(x => x.ConfirmNewPassword)
                .NotEmpty().WithMessage("Password confirmation is required.");
        }
    }
}
