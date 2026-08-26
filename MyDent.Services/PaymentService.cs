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
using MyDent.Services.Messaging;

namespace MyDent.Services
{
    public class PaymentService
        : BaseReadService<Payment, PaymentResponse, PaymentSearch>,
          IPaymentService
    {
        private readonly IValidator<PaymentCreateIntentRequest> _createValidator;
        private readonly IAuthenticatedUserAccessor _userAccessor;
        private readonly IAppointmentEventPublisher _eventPublisher;

        public PaymentService(
            MyDentDbContext dbContext,
            MapsterMapper.IMapper mapper,
            IValidator<PaymentCreateIntentRequest> createValidator,
            IAuthenticatedUserAccessor userAccessor,
            IAppointmentEventPublisher eventPublisher)
            : base(mapper, dbContext)
        {
            _createValidator = createValidator;
            _userAccessor = userAccessor;
            _eventPublisher = eventPublisher;
        }

        protected override Task<IQueryable<Payment>> IncludeRelatedEntitiesAsync(PaymentSearch? search, IQueryable<Payment> query = null!)
        {
            query = query.Include(p => p.Appointment).ThenInclude(a => a.Patient);
            query = query.Include(p => p.Appointment).ThenInclude(a => a.Doctor);
            return base.IncludeRelatedEntitiesAsync(search, query);
        }

        protected override IQueryable<Payment> ApplyFilters(IQueryable<Payment> query, PaymentSearch? search)
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

                if (search.DateFrom.HasValue)
                {
                    query = query.Where(p => p.CreatedAt >= search.DateFrom.Value);
                }

                if (search.DateTo.HasValue)
                {
                    query = query.Where(p => p.CreatedAt <= search.DateTo.Value);
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

            await ApplyStripeStatusAsync(entity, intent.Status);

            return _mapper.Map<PaymentResponse>(entity);
        }

        // Shared by ConfirmAsync (client-triggered, re-fetches from Stripe) and the webhook
        // handler below (Stripe-triggered, status comes from the signed event payload itself).
        private async Task ApplyStripeStatusAsync(Payment entity, string stripeStatus)
        {
            var justPaid = false;

            if (stripeStatus == "succeeded")
            {
                // Idempotent: a repeat call on an already-Paid payment must not shift PaidAt
                // forward every time it's called — both ConfirmAsync and the webhook can observe
                // the same "succeeded" transition. Also guards the notification below from firing
                // twice for the same payment (once from ConfirmAsync, once from the webhook).
                if (entity.Status != PaymentStatus.Paid)
                {
                    entity.Status = PaymentStatus.Paid;
                    entity.PaidAt = DateTime.UtcNow;
                    justPaid = true;
                }
            }
            else if (stripeStatus == "canceled")
            {
                entity.Status = PaymentStatus.Failed;
            }
            // Any other Stripe status (requires_payment_method, requires_action, processing...)
            // means it isn't resolved yet — leave it Pending rather than guessing.

            await _dbContext.SaveChangesAsync();

            if (justPaid)
            {
                await _eventPublisher.PublishNotificationAsync(new NotificationInsertRequest
                {
                    UserId = entity.Appointment.PatientId,
                    Title = "Uplata primljena",
                    Message = $"Uspješno ste platili {entity.Amount} KM za termin zakazan za " +
                        $"{entity.Appointment.ScheduledAt:dd.MM.yyyy. 'u' HH:mm}.",
                    Type = NotificationType.PaymentSucceeded,
                    AppointmentId = entity.AppointmentId
                });
            }
        }

        // Stripe calls this directly (no user session) whenever a PaymentIntent's status changes —
        // covers the case ConfirmAsync's client-triggered call can miss entirely, e.g. the app
        // being closed right after presentPaymentSheet() succeeds but before the eager confirm()
        // call fires. The signature check IS the authorization here: it cryptographically proves
        // the payload actually came from Stripe, so nothing else needs to re-verify it.
        public async Task HandleWebhookAsync(string json, string stripeSignatureHeader, string webhookSecret)
        {
            if (string.IsNullOrEmpty(webhookSecret))
            {
                throw new ClientException("Stripe webhook is not configured.");
            }

            // Throws Stripe.StripeException on a bad/missing signature — the controller lets that
            // become a 400, same as any other invalid request, rather than silently trusting an
            // unverified payload.
            var stripeEvent = Stripe.EventUtility.ConstructEvent(json, stripeSignatureHeader, webhookSecret);

            if (stripeEvent.Data.Object is not Stripe.PaymentIntent intent)
            {
                return;
            }

            var entity = await _dbContext.Payments.Include(p => p.Appointment)
                .FirstOrDefaultAsync(p => p.ProviderTransactionId == intent.Id);
            if (entity == null)
            {
                // A PaymentIntent this app didn't create (or one whose local row was never
                // persisted) — nothing to update.
                return;
            }

            await ApplyStripeStatusAsync(entity, intent.Status);
        }

        // Called when the patient backs out of the PaymentSheet instead of completing it — without
        // this, the Payment row created by CreateIntentAsync stays Pending forever (Stripe's
        // PaymentIntent never resolves on its own until it auto-expires after 24h), which both
        // looks like an unresolved payment sitting in the Payments list and blocks retrying (see
        // PaymentCreateIntentValidator, which refuses a second intent while one already exists).
        public async Task<PaymentResponse> CancelAsync(int id)
        {
            var entity = await _dbContext.Payments.Include(p => p.Appointment)
                .FirstOrDefaultAsync(p => p.Id == id)
                ?? throw new KeyNotFoundException($"Payment with id {id} not found.");

            if (!_userAccessor.IsInRole("Admin") && entity.Appointment.PatientId != _userAccessor.GetUserId())
            {
                throw new ClientException("You can only cancel your own payments.");
            }

            if (entity.Status != PaymentStatus.Pending)
            {
                throw new ClientException($"Cannot cancel a payment with status {entity.Status}. Only Pending payments can be cancelled.");
            }

            try
            {
                var paymentIntentService = new Stripe.PaymentIntentService();
                await paymentIntentService.CancelAsync(entity.ProviderTransactionId);
            }
            catch (Stripe.StripeException)
            {
                // Already succeeded/canceled on Stripe's side, or never had a payment method
                // attached — either way there's nothing left to cancel there. The local status
                // below is what actually matters for the app.
            }

            entity.Status = PaymentStatus.Failed;
            await _dbContext.SaveChangesAsync();

            return _mapper.Map<PaymentResponse>(entity);
        }

        public async Task<PaymentResponse> RefundAsync(int id)
        {
            var entity = await _dbContext.Payments.Include(p => p.Appointment)
                .FirstOrDefaultAsync(p => p.Id == id)
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

            await _eventPublisher.PublishNotificationAsync(new NotificationInsertRequest
            {
                UserId = entity.Appointment.PatientId,
                Title = "Uplata vraćena",
                Message = $"Vraćen vam je iznos od {entity.RefundedAmount} KM za termin zakazan za " +
                    $"{entity.Appointment.ScheduledAt:dd.MM.yyyy. 'u' HH:mm}.",
                Type = NotificationType.PaymentRefunded,
                AppointmentId = entity.AppointmentId
            });

            return _mapper.Map<PaymentResponse>(entity);
        }
    }
}
