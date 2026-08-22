using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using FluentValidation;
using FluentValidation.Results;
using Microsoft.EntityFrameworkCore;
using MyDent.Model.Requests;
using MyDent.Model.Responses;
using MyDent.Model.SearchObjects;
using MyDent.Services.Database;

namespace MyDent.Services
{
    public class NotificationService
        : BaseReadService<Notification, NotificationResponse, NotificationSearch>,
          INotificationService
    {
        private readonly IValidator<NotificationInsertRequest> _insertValidator;
        private readonly IAuthenticatedUserAccessor _userAccessor;

        public NotificationService(
            MyDentDbContext dbContext,
            MapsterMapper.IMapper mapper,
            IValidator<NotificationInsertRequest> insertValidator,
            IAuthenticatedUserAccessor userAccessor)
            : base(mapper, dbContext)
        {
            _insertValidator = insertValidator;
            _userAccessor = userAccessor;
        }

        protected override Task<IQueryable<Notification>> IncludeRelatedEntitiesAsync(NotificationSearch? search, IQueryable<Notification> query = null!)
        {
            query = query.Include(n => n.User);
            query = query.Include(n => n.ServiceCategory);
            return base.IncludeRelatedEntitiesAsync(search, query);
        }

        protected override IQueryable<Notification> ApplyFilters(IQueryable<Notification> query, NotificationSearch? search)
        {
            // A non-Admin only ever sees their own notifications, no matter what UserId they
            // pass in search — this is the private-inbox equivalent of the ownership checks we
            // added on the write side for Review/Appointment, just enforced on reads instead.
            if (!_userAccessor.IsInRole("Admin"))
            {
                query = query.Where(n => n.UserId == _userAccessor.GetUserId());
            }
            else if (search?.UserId.HasValue == true)
            {
                query = query.Where(n => n.UserId == search.UserId.Value);
            }

            if (search != null)
            {
                if (search.Type.HasValue)
                {
                    query = query.Where(n => n.Type == search.Type.Value);
                }

                if (search.IsRead.HasValue)
                {
                    query = query.Where(n => n.IsRead == search.IsRead.Value);
                }

                if (search.AppointmentId.HasValue)
                {
                    query = query.Where(n => n.AppointmentId == search.AppointmentId.Value);
                }
            }

            return query.OrderByDescending(n => n.CreatedAt);
        }

        // GetAllAsync goes through ApplyFilters above, but GetByIdAsync bypasses it entirely
        // (base implementation just looks up by id) — so it needs its own ownership check here.
        // Returning "not found" instead of a 403-style error is deliberate: a non-owner shouldn't
        // be able to tell "this id doesn't exist" apart from "it exists but isn't yours."
        public override async Task<NotificationResponse> GetByIdAsync(int id)
        {
            IQueryable<Notification> query = _dbContext.Set<Notification>();
            query = await IncludeRelatedEntitiesAsync(null, query);
            var entity = await query.FirstOrDefaultAsync(n => n.Id == id);

            if (entity == null || (!_userAccessor.IsInRole("Admin") && entity.UserId != _userAccessor.GetUserId()))
            {
                throw new KeyNotFoundException($"Notification with id {id} not found.");
            }

            return _mapper.Map<NotificationResponse>(entity);
        }

        public async Task<NotificationResponse> InsertAsync(NotificationInsertRequest request)
        {
            var validationResult = await _insertValidator.ValidateAsync(request);
            if (!validationResult.IsValid)
            {
                var errors = validationResult.Errors.Select(e => _mapper.Map<ValidationFailure>(e));
                throw new FluentValidation.ValidationException(errors);
            }

            var entity = new Notification
            {
                UserId = request.UserId,
                Title = request.Title,
                Message = request.Message,
                Type = request.Type,
                AppointmentId = request.AppointmentId,
                ServiceCategoryId = request.ServiceCategoryId,
                IsRead = false,
                CreatedAt = DateTime.UtcNow
            };

            _dbContext.Notifications.Add(entity);
            await _dbContext.SaveChangesAsync();

            return _mapper.Map<NotificationResponse>(entity);
        }

        public async Task<NotificationResponse> MarkAsReadAsync(int id)
        {
            var entity = await _dbContext.Notifications.FindAsync(id)
                ?? throw new KeyNotFoundException($"Notification with id {id} not found.");

            // Admin bypass, same as Update/Delete — NotificationList is an Admin management
            // console over every user's notifications, not a personal inbox, so an Admin needs to
            // be able to mark any of them read from there.
            if (!_userAccessor.IsInRole("Admin") && entity.UserId != _userAccessor.GetUserId())
            {
                throw new KeyNotFoundException($"Notification with id {id} not found.");
            }

            entity.IsRead = true;
            await _dbContext.SaveChangesAsync();

            return _mapper.Map<NotificationResponse>(entity);
        }

        public async Task DeleteAsync(int id)
        {
            var entity = await _dbContext.Notifications.FindAsync(id)
                ?? throw new KeyNotFoundException($"Notification with id {id} not found.");

            if (!_userAccessor.IsInRole("Admin") && entity.UserId != _userAccessor.GetUserId())
            {
                throw new KeyNotFoundException($"Notification with id {id} not found.");
            }

            _dbContext.Notifications.Remove(entity);
            await _dbContext.SaveChangesAsync();
        }
    }
}
