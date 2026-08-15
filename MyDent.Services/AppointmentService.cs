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

        // Same rules AppointmentInsertValidator checks against one candidate ScheduledAt (working
        // hours, absence, overlap) — here applied to generate the whole list of valid slots for a
        // day, so the client can offer a picker instead of guess-and-check.
        public async Task<List<AvailableSlotResponse>> GetAvailableSlotsAsync(AvailableSlotsRequest request)
        {
            var doctor = await _dbContext.Doctors.AsNoTracking()
                .FirstOrDefaultAsync(d => d.Id == request.DoctorId && d.IsActive)
                ?? throw new ClientException($"Doctor with id {request.DoctorId} does not exist or is not active.");

            var dentalService = await _dbContext.DentalServices.AsNoTracking()
                .FirstOrDefaultAsync(s => s.Id == request.DentalServiceId && s.IsActive)
                ?? throw new ClientException($"DentalService with id {request.DentalServiceId} does not exist or is not active.");

            var isOnAbsence = await _dbContext.DoctorAbsences.AnyAsync(a =>
                a.DoctorId == request.DoctorId &&
                a.StartDate <= request.Date &&
                a.EndDate >= request.Date);

            if (isOnAbsence)
            {
                return new List<AvailableSlotResponse>();
            }

            var workingHours = await _dbContext.DoctorWorkingHours
                .Where(w => w.DoctorId == request.DoctorId && w.DayOfWeek == request.Date.DayOfWeek)
                .ToListAsync();

            if (workingHours.Count == 0)
            {
                return new List<AvailableSlotResponse>();
            }

            var dayStart = request.Date.ToDateTime(TimeOnly.MinValue);
            var dayEnd = dayStart.AddDays(1);

            var existingAppointments = await _dbContext.Appointments.AsNoTracking()
                .Where(a => a.DoctorId == request.DoctorId
                    && a.Status != AppointmentStatus.Cancelled
                    && a.ScheduledAt >= dayStart && a.ScheduledAt < dayEnd)
                .Select(a => new { a.ScheduledAt, a.DurationMinutes })
                .ToListAsync();

            var duration = TimeSpan.FromMinutes(dentalService.DurationMinutes);
            var now = DateTime.UtcNow;
            var slots = new List<AvailableSlotResponse>();

            foreach (var shift in workingHours)
            {
                // Slots are aligned to a grid starting at the shift's own start time, sized to
                // this service's duration — simple and predictable (e.g. always :00/:30 for a
                // 30-minute service), at the cost of occasionally missing an odd-sized gap between
                // two existing appointments that doesn't land on the grid. Good enough for a
                // clinic booking flow; a fully packed scheduler is out of scope here.
                var slotStart = dayStart + shift.StartTime;
                var shiftEnd = dayStart + shift.EndTime;

                while (slotStart + duration <= shiftEnd)
                {
                    var slotEnd = slotStart + duration;

                    if (slotStart > now && !existingAppointments.Any(a =>
                        slotStart < a.ScheduledAt.AddMinutes(a.DurationMinutes) && a.ScheduledAt < slotEnd))
                    {
                        slots.Add(new AvailableSlotResponse { StartTime = slotStart, EndTime = slotEnd });
                    }

                    slotStart += duration;
                }
            }

            return slots.OrderBy(s => s.StartTime).ToList();
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
