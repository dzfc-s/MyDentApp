
using Microsoft.EntityFrameworkCore;
using MyDent.Model.Exceptions;
using MyDent.Model.Requests;
using MyDent.Model.Responses;
using MyDent.Model.SearchObjects;
using MyDent.Services.Database;

namespace MyDent.Services
{
    public class ReviewService : BaseCRUDService<Review, ReviewResponse, ReviewSearch, ReviewInsertRequest, ReviewUpdateRequest>, IReviewService
    {
        private readonly IAuthenticatedUserAccessor _userAccessor;

        public ReviewService(
            MyDentDbContext dbContext,
            MapsterMapper.IMapper mapper,
            FluentValidation.IValidator<ReviewInsertRequest> insertValidator,
            FluentValidation.IValidator<ReviewUpdateRequest> updateValidator,
            IAuthenticatedUserAccessor userAccessor)
            : base(dbContext, mapper, insertValidator, updateValidator)
        {
            _userAccessor = userAccessor;
        }

        // IsApproved-only-Admin is already enforced in ReviewUpdateValidator. What the validator
        // *can't* check is whose review this is (it never loads the entity) — a patient editing
        // Rating/Comment must only be able to touch their own review. Same ownership pattern as
        // AppointmentService.CancelAsync, just reached through Review -> Appointment -> PatientId.
        public override async Task<ReviewResponse> UpdateAsync(int id, ReviewUpdateRequest request)
        {
            var entity = await _dbContext.Reviews.Include(r => r.Appointment)
                .FirstOrDefaultAsync(r => r.Id == id)
                ?? throw new KeyNotFoundException($"Review with id {id} not found.");

            if (!_userAccessor.IsInRole("Admin") && entity.Appointment.PatientId != _userAccessor.GetUserId())
            {
                throw new ClientException("You can only edit your own reviews.");
            }

            return await base.UpdateAsync(id, request);
        }

        // Same ownership rule as UpdateAsync — deleting is just as much "editing" someone
        // else's review as changing its text would be.
        public override async Task DeleteAsync(int id)
        {
            var entity = await _dbContext.Reviews.Include(r => r.Appointment)
                .FirstOrDefaultAsync(r => r.Id == id)
                ?? throw new KeyNotFoundException($"Review with id {id} not found.");

            if (!_userAccessor.IsInRole("Admin") && entity.Appointment.PatientId != _userAccessor.GetUserId())
            {
                throw new ClientException("You can only delete your own reviews.");
            }

            await base.DeleteAsync(id);
        }

        protected override Task<IQueryable<Review>> IncludeRelatedEntitiesAsync(ReviewSearch? search, IQueryable<Review> query = null!)
        {
            query = query.Include(r => r.Appointment).ThenInclude(a => a.Doctor);
            query = query.Include(r => r.Appointment).ThenInclude(a => a.Patient);
            query = query.Include(r => r.Appointment).ThenInclude(a => a.DentalService);
            return base.IncludeRelatedEntitiesAsync(search, query);
        }

        protected override IEnumerable<Review> ApplyFilters(IEnumerable<Review> query, ReviewSearch? search)
        {
            if (search != null)
            {
                if (search.AppointmentId.HasValue)
                {
                    query = query.Where(r => r.AppointmentId == search.AppointmentId.Value);
                }

                if (search.Rating.HasValue)
                {
                    query = query.Where(r => r.Rating == search.Rating.Value);
                }

                if (search.PatientId.HasValue)
                {
                    query = query.Where(r => r.Appointment.PatientId == search.PatientId.Value);
                }

                if (search.DoctorId.HasValue)
                {
                    query = query.Where(r => r.Appointment.DoctorId == search.DoctorId.Value);
                }
            }

            return query;
        }
    }
}
