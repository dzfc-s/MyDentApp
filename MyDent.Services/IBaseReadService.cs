using MyDent.Model.Responses;
using MyDent.Model.SearchObjects;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace MyDent.Services
{
    public interface IBaseReadService<TResponse, TSearch>
        where TSearch : BaseSearchObject
    {
        Task<TResponse> GetByIdAsync(int id);
        Task<PageResult<TResponse>> GetAllAsync(TSearch? search = null);
    }
}
