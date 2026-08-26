using Microsoft.EntityFrameworkCore;
using MyDent.Model.Requests;
using MyDent.Services.Database;
using FluentValidation;

namespace MyDent.Services.Validators
{
    public class UserInsertValidator : AbstractValidator<UserInsertRequest>
    {
        public UserInsertValidator(MyDentDbContext dbContext)
        {
            RuleFor(x => x.FirstName)
                .NotEmpty().WithMessage("First name is required.")
                .MaximumLength(50).WithMessage("First name cannot exceed 50 characters.");

            RuleFor(x => x.LastName)
                .NotEmpty().WithMessage("Last name is required.")
                .MaximumLength(50).WithMessage("Last name cannot exceed 50 characters.");

            RuleFor(x => x.Email)
                .NotEmpty().WithMessage("Email is required.")
                .EmailAddress().WithMessage("Email must be a valid email address.")
                .MaximumLength(100).WithMessage("Email cannot exceed 100 characters.")
                // No unique index on this column at the DB level, so nothing else catches a
                // duplicate — without this, registering with an already-used email either silently
                // succeeded (two accounts, same email) or blew up as an unhandled exception
                // downstream, depending what else happens to key off email.
                .MustAsync(async (email, cancellation) =>
                    !await dbContext.Users.AnyAsync(u => u.Email.ToLower() == email.Trim().ToLower(), cancellation))
                .WithMessage("This email is already registered.");

            RuleFor(x => x.Username)
                .NotEmpty().WithMessage("Username is required.")
                .MinimumLength(3).WithMessage("Username must be at least 3 characters.")
                .MaximumLength(100).WithMessage("Username cannot exceed 100 characters.")
                // Same reasoning as Email above — login resolves a user by Username, so a silent
                // duplicate here is worse than just untidy data: it makes login itself ambiguous.
                .MustAsync(async (username, cancellation) =>
                    !await dbContext.Users.AnyAsync(u => u.Username.ToLower() == username.Trim().ToLower(), cancellation))
                .WithMessage("This username is already taken.");

            RuleFor(x => x.Password)
                .NotEmpty().WithMessage("Password is required.")
                .MinimumLength(6).WithMessage("Password must be at least 6 characters.")
                .MaximumLength(100).WithMessage("Password cannot exceed 100 characters.");

            RuleFor(x => x.PhoneNumber)
                .MaximumLength(20).WithMessage("Phone number cannot exceed 20 characters.")
                .Matches(@"^\+?[0-9\s\-()]{6,20}$").WithMessage("Phone number format is invalid.")
                .When(x => !string.IsNullOrEmpty(x.PhoneNumber));

            RuleFor(x => x.ProfileImageAssetId)
                .GreaterThan(0).WithMessage("ProfileImageAssetId must be greater than 0.")
                .When(x => x.ProfileImageAssetId.HasValue);
        }
    }
}
