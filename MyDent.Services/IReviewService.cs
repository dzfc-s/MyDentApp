using MyDent.Model.Requests;
using MyDent.Model.Responses;
using MyDent.Model.SearchObjects;

namespace MyDent.Services
{
    public interface IReviewService : IBaseCRUDService<ReviewResponse, ReviewSearch, ReviewInsertRequest, ReviewUpdateRequest>
    {
    }
}
