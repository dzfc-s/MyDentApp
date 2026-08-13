using System.Threading.Tasks;
using MyDent.Model.Requests;
using MyDent.Model.Responses;
using MyDent.Model.SearchObjects;

namespace MyDent.Services
{
    // Not IBaseCRUDService: a payment's lifecycle is driven by Stripe, not by free-form edits —
    // CreateIntentAsync starts it, ConfirmAsync syncs the real status from Stripe, RefundAsync
    // reverses it. There's nothing left for a generic Update to do.
    public interface IPaymentService : IBaseReadService<PaymentResponse, PaymentSearch>
    {
        Task<PaymentIntentResponse> CreateIntentAsync(PaymentCreateIntentRequest request);
        Task<PaymentResponse> ConfirmAsync(int id);
        Task<PaymentResponse> RefundAsync(int id);
    }
}
