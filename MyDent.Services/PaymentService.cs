using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using FluentValidation;
using FluentValidation.Results;
using Microsoft.EntityFrameworkCore;
using MyDent.Model.Enums;
using MyDent.Model.Exceptions;
using MyDent.Model.Requests;
using MyDent.Model.Responses;
using MyDent.Model.SearchObjects;
using MyDent.Services.Database;

namespace MyDent.Services
{
    public class PaymentService
        : BaseReadService<Payment, PaymentResponse, PaymentSearch>,
          IPaymentService
    {
        private readonly IValidator<PaymentCreateIntentRequest> _createValidator;
        private readonly IAuthenticatedUserAccessor _userAccessor;

        public PaymentService(
            MyDentDbContext dbContext,
            MapsterMapper.IMapper mapper,
            IValidator<PaymentCreateIntentRequest> createValidator,
            IAuthenticatedUserAccessor userAccessor)
            : base(mapper, dbContext)
        {
            _createValidator = createValidator;
            _userAccessor = userAccessor;
        }

        protected override Task<IQueryable<Payment>> IncludeRelatedEntitiesAsync(PaymentSearch? search, IQueryable<Payment> query = null!)
        {
            query = query.Include(p => p.Appointment).ThenInclude(a => a.Patient);
            query = query.Include(p => p.Appointment).ThenInclude(a => a.Doctor);
            return base.IncludeRelatedEntitiesAsync(search, query);
        }

        protected override IEnumerable<Payment> ApplyFilters(IEnumerable<Payment> query, PaymentSearch? search)
        {
            // Financial data is private, same principle as Notification: a non-Admin only ever
            // sees their own payments, regardless of what's requested.
            if (!_userAccessor.IsInRole("Admin"))
            {
                query = query.Where(p => p.Appointment.PatientId == _userAccessor.GetUserId());
            }
            else if (search?.PatientId.HasValue == true)
            {
                query = query.Where(p => p.Appointment.PatientId == search.PatientId.Value);
            }

            if (search != null)
            {
                if (search.AppointmentId.HasValue)
                {
                    query = query.Where(p => p.AppointmentId == search.AppointmentId.Value);
                }

                if (search.Status.HasValue)
                {
                    query = query.Where(p => p.Status == search.Status.Value);
                }
            }

            return query;
        }

        // GetAllAsync goes through ApplyFilters above, but GetByIdAsync bypasses it — needs its
        // own ownership check. "Not found" rather than a 403-style error, same reasoning as
        // Notification: a non-owner shouldn't learn whether a given payment id even exists.
        public override async Task<PaymentResponse> GetByIdAsync(int id)
        {
            IQueryable<Payment> query = _dbContext.Set<Payment>();
            query = await IncludeRelatedEntitiesAsync(null, query);
            var entity = await query.FirstOrDefaultAsync(p => p.Id == id);

            if (entity == null || (!_userAccessor.IsInRole("Admin") && entity.Appointment.PatientId != _userAccessor.GetUserId()))
            {
                throw new KeyNotFoundException($"Payment with id {id} not found.");
            }

            return _mapper.Map<PaymentResponse>(entity);
        }

        public async Task<PaymentIntentResponse> CreateIntentAsync(PaymentCreateIntentRequest request)
        {
            var validationResult = await _createValidator.ValidateAsync(request);
            if (!validationResult.IsValid)
            {
                var errors = validationResult.Errors.Select(e => _mapper.Map<ValidationFailure>(e));
                throw new FluentValidation.ValidationException(errors);
            }

            // The validator already confirmed this appointment exists, isn't cancelled, and has
            // no payment yet — safe to load without re-checking here.
            var appointment = await _dbContext.Appointments
                .Include(a => a.Patient)
                .FirstAsync(a => a.Id == request.AppointmentId);

            // A Stripe Customer is created fresh per payment rather than reused across a
            // patient's payments — simpler for now (no StripeCustomerId to store/look up on
            // User), at the cost of accumulating one Stripe Customer object per payment. Fine
            // for a thesis project; a real deployment would store/reuse the customer id.
            var customerService = new Stripe.CustomerService();
            var customer = await customerService.CreateAsync(new Stripe.CustomerCreateOptions
            {
                Name = appointment.Patient.FirstName + " " + appointment.Patient.LastName,
                Email = appointment.Patient.Email
            });

            var ephemeralKeyService = new Stripe.EphemeralKeyService();
            var ephemeralKey = await ephemeralKeyService.CreateAsync(new Stripe.EphemeralKeyCreateOptions
            {
                Customer = customer.Id
            });

            // Stripe amounts are in the smallest currency unit (cents for EUR).
            var amountInCents = (long)(appointment.Price * 100);

            var paymentIntentService = new Stripe.PaymentIntentService();
            var intent = await paymentIntentService.CreateAsync(new Stripe.PaymentIntentCreateOptions
            {
                Amount = amountInCents,
                Currency = "eur",
                Customer = customer.Id,
                // AllowRedirects = "never" restricts to payment methods that complete in-app
                // (card, Apple/Google Pay via PaymentSheet) — without it, Stripe also offers
                // redirect-based methods (Bancontact, EPS, ...) which require a return_url we
                // have no use for in a mobile PaymentSheet flow, and confirmation fails without one.
                AutomaticPaymentMethods = new Stripe.PaymentIntentAutomaticPaymentMethodsOptions
                {
                    Enabled = true,
                    AllowRedirects = "never"
                },
                Description = $"MyDent appointment #{appointment.Id}",
                Metadata = new Dictionary<string, string> { { "AppointmentId", appointment.Id.ToString() } }
            });

            var entity = new Payment
            {
                AppointmentId = appointment.Id,
                Amount = appointment.Price,
                Status = PaymentStatus.Pending,
                ProviderTransactionId = intent.Id,
                CreatedAt = DateTime.UtcNow
            };

            _dbContext.Payments.Add(entity);
            await _dbContext.SaveChangesAsync();

            return new PaymentIntentResponse
            {
                PaymentId = entity.Id,
                ClientSecret = intent.ClientSecret,
                EphemeralKey = ephemeralKey.Secret,
                CustomerId = customer.Id
            };
        }

        public async Task<PaymentResponse> ConfirmAsync(int id)
        {
            var entity = await _dbContext.Payments.Include(p => p.Appointment)
                .FirstOrDefaultAsync(p => p.Id == id)
                ?? throw new KeyNotFoundException($"Payment with id {id} not found.");

            if (!_userAccessor.IsInRole("Admin") && entity.Appointment.PatientId != _userAccessor.GetUserId())
            {
                throw new ClientException("You can only confirm your own payments.");
            }

            // The whole point of this method: ask Stripe what actually happened, rather than
            // trusting the caller's word that the card payment succeeded.
            var paymentIntentService = new Stripe.PaymentIntentService();
            var intent = await paymentIntentService.GetAsync(entity.ProviderTransactionId);

            if (intent.Status == "succeeded")
            {
                // Idempotent: a repeat /confirm call on an already-Paid payment must not shift
                // PaidAt forward every time it's called.
                if (entity.Status != PaymentStatus.Paid)
                {
                    entity.Status = PaymentStatus.Paid;
                    entity.PaidAt = DateTime.UtcNow;
                }
            }
            else if (intent.Status == "canceled")
            {
                entity.Status = PaymentStatus.Failed;
            }
            // Any other Stripe status (requires_payment_method, requires_action, processing...)
            // means it isn't resolved yet — leave it Pending rather than guessing.

            await _dbContext.SaveChangesAsync();

            return _mapper.Map<PaymentResponse>(entity);
        }

        public async Task<PaymentResponse> RefundAsync(int id)
        {
            var entity = await _dbContext.Payments.FindAsync(id)
                ?? throw new KeyNotFoundException($"Payment with id {id} not found.");

            if (entity.Status != PaymentStatus.Paid)
            {
                throw new ClientException($"Cannot refund a payment with status {entity.Status}. Only Paid payments can be refunded.");
            }

            var refundService = new Stripe.RefundService();
            await refundService.CreateAsync(new Stripe.RefundCreateOptions
            {
                PaymentIntent = entity.ProviderTransactionId
            });

            entity.Status = PaymentStatus.Refunded;
            entity.RefundedAmount = entity.Amount;
            entity.RefundedAt = DateTime.UtcNow;

            await _dbContext.SaveChangesAsync();

            return _mapper.Map<PaymentResponse>(entity);
        }
    }
}
