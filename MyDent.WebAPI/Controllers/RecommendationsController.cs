using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MyDent.Model.Responses;
using MyDent.Services;

namespace MyDent.WebAPI.Controllers;

// Not a CRUD resource — a single computed view over the patient's own appointment history (or,
// for Admin, any patient's), so this doesn't extend BaseReadController.
[ApiController]
[Route("[controller]")]
[Authorize]
public class RecommendationsController : ControllerBase
{
    private readonly IRecommenderService _service;

    public RecommendationsController(IRecommenderService service)
    {
        _service = service;
    }

    [HttpGet]
    public async Task<ActionResult<List<RecommendationResponse>>> Get([FromQuery] int? patientId)
    {
        return await _service.GetRecommendationsAsync(patientId);
    }
}
