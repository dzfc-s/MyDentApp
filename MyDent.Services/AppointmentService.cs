using FluentValidation;
using FluentValidation.Results;
using Microsoft.EntityFrameworkCore;
using MyDent.Model.Enums;
using MyDent.Model.Exceptions;
using MyDent.Model.Requests;
using MyDent.Model.Responses;
using MyDent.Model.SearchObjects;
using MyDent.Services.Database;
using MyDent.Services.Messaging;

namespace MyDent.Services
{
    public class AppointmentService
        : BaseReadService<Appointment, AppointmentResponse, AppointmentSearch>,
          IAppointmentService
    {
        private readonly IValidator<AppointmentInsertRequest> _insertValidator;
        private readonly IAuthenticatedUserAccessor _userAccessor;
        private readonly IAppointmentEventPublisher _eventPublisher;

        public AppointmentService(
            MyDentDbContext dbContext,
            MapsterMapper.IMapper mapper,
            IValidator<AppointmentInsertRequest> insertValidator,
            IAuthenticatedUserAccessor userAccessor,
            IAppointmentEventPublisher eventPublisher)
            : base(mapper, dbContext)
        {
            _insertValidator = insertValidator;
            _userAccessor = userAccessor;
            _eventPublisher = eventPublisher;
        }

        protected override Task<IQueryable<Appointment>> IncludeRelatedEntitiesAsync(AppointmentSearch? search, IQueryable<Appointment> query = null!)
        {
            query = query.Include(a => a.Patient).Include(a => a.Doctor).Include(a => a.DentalService);
            return base.IncludeRelatedEntitiesAsync(search, query);
        }

        protected override IEnumerable<Appointment> ApplyFilters(IEnumerable<Appointment> query, AppointmentSearch? search)
        {
            if (search != null)
            {
                if (search.PatientId.HasValue)
                {
                    query = query.Where(a => a.PatientId == search.PatientId.Value);
                }

                if (search.DoctorId.HasValue)
                {
                    query = query.Where(a => a.DoctorId == search.DoctorId.Value);
                }

                if (search.DentalServiceId.HasValue)
                {
                    query = query.Where(a => a.DentalServiceId == search.DentalServiceId.Value);
                }

                if (search.Status.HasValue)
                {
                    query = query.Where(a => a.Status == search.Status.Value);
                }

                if (search.DateFrom.HasValue)
                {
                    query = query.Where(a => a.ScheduledAt >= search.DateFrom.Value);
                }

                if (search.DateTo.HasValue)
                {
                    query = query.Where(a => a.ScheduledAt <= search.DateTo.Value);
                }
            }

            return query;
        }

        public async Task<AppointmentResponse> InsertAsync(AppointmentInsertRequest request)
        {
            var validationResult = await _insertValidator.ValidateAsync(request);
            if (!validationResult.IsValid)
            {
                var errors = validationResult.Errors.Select(e => _mapper.Map<ValidationFailure>(e));
                throw new FluentValidation.ValidationException(errors);
            }

            // Price/DurationMinutes are a snapshot of the DentalService at booking time — the
            // validator already confirmed this service exists and is active, so it's safe to load.
            var dentalService = await _dbContext.DentalServices.FindAsync(request.DentalServiceId);

            var entity = new Appointment
            {
                PatientId = request.PatientId,
                DoctorId = request.DoctorId,
                DentalServiceId = request.DentalServiceId,
                ScheduledAt = request.ScheduledAt,
                DurationMinutes = dentalService!.DurationMinutes,
                Price = dentalService.Price,
                Status = AppointmentStatus.Pending,
                CreatedAt = DateTime.UtcNow
            };

            _dbContext.Appointments.Add(entity);
            await _dbContext.SaveChangesAsync();

            return _mapper.Map<AppointmentResponse>(entity);
        }

        public async Task<AppointmentResponse> ConfirmAsync(int id)
        {
            var entity = await _dbContext.Appointments.FindAsync(id)
                ?? throw new KeyNotFoundException($"Appointment with id {id} not found.");

            if (entity.Status != AppointmentStatus.Pending)
            {
                throw new ClientException($"Cannot confirm an appointment with status {entity.Status}. Only Pending appointments can be confirmed.");
            }

            await AddStatusHistoryAsync(entity, AppointmentStatus.Confirmed, reason: null);
            await _dbContext.SaveChangesAsync();

            await _eventPublisher.PublishNotificationAsync(new NotificationInsertRequest
            {
                UserId = entity.PatientId,
                Title = "Termin potvrđen",
                Message = $"Vaš termin zakazan za {entity.ScheduledAt:dd.MM.yyyy. 'u' HH:mm} je potvrđen.",
                Type = NotificationType.AppointmentConfirmed,
                AppointmentId = entity.Id
            });

            return _mapper.Map<AppointmentResponse>(entity);
        }

        public async Task<AppointmentResponse> CancelAsync(int id, AppointmentCancelRequest request)
        {
            var entity = await _dbContext.Appointments.FindAsync(id)
                ?? throw new KeyNotFoundException($"Appointment with id {id} not found.");

            // Same ownership rule as booking: a patient can cancel their own appointment, an
            // Admin can cancel any of them.
            if (!_userAccessor.IsInRole("Admin") && entity.PatientId != _userAccessor.GetUserId())
            {
                throw new ClientException("You can only cancel your own appointments.");
            }

            if (entity.Status != AppointmentStatus.Pending && entity.Status != AppointmentStatus.Confirmed)
            {
                throw new ClientException($"Cannot cancel an appointment with status {entity.Status}.");
            }

            entity.CancellationReason = request.CancellationReason;
            entity.CancelledByUserId = _userAccessor.GetUserId();
            entity.CancelledAt = DateTime.UtcNow;

            await AddStatusHistoryAsync(entity, AppointmentStatus.Cancelled, request.CancellationReason);
            await _dbContext.SaveChangesAsync();

            var cancelMessage = $"Vaš termin zakazan za {entity.ScheduledAt:dd.MM.yyyy. 'u' HH:mm} je otkazan.";
            if (!string.IsNullOrWhiteSpace(request.CancellationReason))
            {
                cancelMessage += $" Razlog: {request.CancellationReason}";
            }

            // Cancelling doesn't touch Payment at all — refunding is a deliberate Admin action
            // (POST /Payments/{id}/refund), never automatic. This just makes sure the patient (and
            // whoever reads the notification) knows a paid appointment needs that follow-up,
            // instead of a paid appointment silently sitting cancelled with no visible next step.
            var isPaid = await _dbContext.Payments.AnyAsync(p => p.AppointmentId == entity.Id && p.Status == PaymentStatus.Paid);
            if (isPaid)
            {
                cancelMessage += " Uplata za ovaj termin će biti obrađena od strane klinike.";
            }

            await _eventPublisher.PublishNotificationAsync(new NotificationInsertRequest
            {
                UserId = entity.PatientId,
                Title = "Termin otkazan",
                Message = cancelMessage,
                Type = NotificationType.AppointmentCancelled,
                AppointmentId = entity.Id
            });

            return _mapper.Map<AppointmentResponse>(entity);
        }

        public async Task<AppointmentResponse> CompleteAsync(int id)
        {
            var entity = await _dbContext.Appointments.FindAsync(id)
                ?? throw new KeyNotFoundException($"Appointment with id {id} not found.");

            if (entity.Status != AppointmentStatus.Confirmed)
            {
                throw new ClientException($"Cannot complete an appointment with status {entity.Status}. Only Confirmed appointments can be completed.");
            }

            await AddStatusHistoryAsync(entity, AppointmentStatus.Completed, reason: null);
            await _dbContext.SaveChangesAsync();

            return _mapper.Map<AppointmentResponse>(entity);
        }

        public async Task<List<AppointmentStatusHistoryResponse>> GetHistoryAsync(int id)
        {
            var exists = await _dbContext.Appointments.AnyAsync(a => a.Id == id);
            if (!exists)
            {
                throw new KeyNotFoundException($"Appointment with id {id} not found.");
            }

            var history = await _dbContext.AppointmentStatusHistories
                .Include(h => h.ChangedByUser)
                .Where(h => h.AppointmentId == id)
                .OrderBy(h => h.ChangedAt)
                .ToListAsync();

            return history.Select(h => _mapper.Map<AppointmentStatusHistoryResponse>(h)).ToList();
        }

        // Shared by all three status-transition actions: flips the entity's status and appends
        // the corresponding audit row. Caller is responsible for validating the transition is
        // legal *before* calling this, and for SaveChangesAsync afterwards.
        private async Task AddStatusHistoryAsync(Appointment entity, AppointmentStatus newStatus, string? reason)
        {
            var fromStatus = entity.Status;
            entity.Status = newStatus;

            var userId = _userAccessor.GetUserId()
                ?? throw new ClientException("Authenticated user could not be resolved.");

            _dbContext.AppointmentStatusHistories.Add(new AppointmentStatusHistory
            {
                AppointmentId = entity.Id,
                FromStatus = fromStatus,
                ToStatus = newStatus,
                ChangedByUserId = userId,
                Reason = reason,
                ChangedAt = DateTime.UtcNow
            });

            await Task.CompletedTask;
        }
    }
}
