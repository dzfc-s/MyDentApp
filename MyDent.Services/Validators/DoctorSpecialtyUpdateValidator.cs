using FluentValidation;
using Microsoft.EntityFrameworkCore;
using MyDent.Model.Requests;
using MyDent.Services.Database;

namespace MyDent.Services.Validators
{
    public class DoctorSpecialtyUpdateValidator : AbstractValidator<DoctorSpecialtyUpdateRequest>
    {
        public DoctorSpecialtyUpdateValidator(MyDentDbContext dbContext)
        {
            RuleFor(x => x.DoctorId)
                .GreaterThan(0).WithMessage("DoctorId is required.")
                .MustAsync(async (id, cancellation) => await dbContext.Doctors.AnyAsync(d => d.Id == id, cancellation))
                .WithMessage(x => $"Doctor with id {x.DoctorId} does not exist.");

            RuleFor(x => x.ServiceCategoryId)
                .GreaterThan(0).WithMessage("ServiceCategoryId is required.")
                .MustAsync(async (id, cancellation) => await dbContext.ServiceCategories.AnyAsync(c => c.Id == id, cancellation))
                .WithMessage(x => $"ServiceCategory with id {x.ServiceCategoryId} does not exist.");
        }
    }
}
