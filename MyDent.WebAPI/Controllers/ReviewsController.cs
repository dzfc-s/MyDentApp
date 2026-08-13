using Microsoft.AspNetCore.Authorization;
using MyDent.Model.Requests;
using MyDent.Model.Responses;
using MyDent.Model.SearchObjects;
using MyDent.Services;

namespace MyDent.WebAPI.Controllers
{
    // Ownership checks in ReviewService/ReviewInsertValidator depend on knowing who's calling —
    // same reasoning as AppointmentsController.
    [Authorize]
    public class ReviewsController : BaseCRUDController<ReviewResponse, ReviewSearch, ReviewInsertRequest, ReviewUpdateRequest, IReviewService>
    {
        public ReviewsController(IReviewService service) : base(service)
        {
        }
    }
}
