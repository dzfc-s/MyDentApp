using System.Collections.Generic;
using System.Threading.Tasks;
using MyDent.Model.Responses;

namespace MyDent.Services
{
    public interface IRecommenderService
    {
        // patientId: only an Admin may pass another patient's id (e.g. staff assisting a walk-in);
        // a Patient caller always gets their own recommendations regardless of what's passed.
        Task<List<RecommendationResponse>> GetRecommendationsAsync(int? patientId);
    }
}
