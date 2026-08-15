using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MyDent.Model.Requests;
using MyDent.Services;

namespace MyDent.WebAPI.Controllers;

// Business/financial reports — Admin only, not a CRUD resource.
[ApiController]
[Route("[controller]")]
[Authorize(Roles = "Admin")]
public class ReportsController : ControllerBase
{
    private readonly IReportService _service;

    public ReportsController(IReportService service)
    {
        _service = service;
    }

    [HttpGet("revenue")]
    public async Task<IActionResult> Revenue([FromQuery] RevenueReportRequest request)
    {
        var pdfBytes = await _service.GenerateRevenueReportAsync(request);
        return File(pdfBytes, "application/pdf", $"izvjestaj-prihod-{request.StartDate:yyyy-MM-dd}_{request.EndDate:yyyy-MM-dd}.pdf");
    }

    [HttpGet("service-popularity")]
    public async Task<IActionResult> ServicePopularity([FromQuery] ServicePopularityReportRequest request)
    {
        var pdfBytes = await _service.GenerateServicePopularityReportAsync(request);
        return File(pdfBytes, "application/pdf", $"izvjestaj-popularnost-{request.StartDate:yyyy-MM-dd}_{request.EndDate:yyyy-MM-dd}.pdf");
    }
}
