using System.Threading.Tasks;
using MyDent.Model.Requests;

namespace MyDent.Services
{
    // Each method returns the raw PDF bytes — the controller is responsible for turning that
    // into a file download response, this layer only knows how to gather the data and render it.
    public interface IReportService
    {
        Task<byte[]> GenerateRevenueReportAsync(RevenueReportRequest request);
        Task<byte[]> GenerateServicePopularityReportAsync(ServicePopularityReportRequest request);
    }
}
