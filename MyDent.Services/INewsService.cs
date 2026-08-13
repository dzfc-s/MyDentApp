using MyDent.Model.Requests;
using MyDent.Model.Responses;
using MyDent.Model.SearchObjects;

namespace MyDent.Services
{
    public interface INewsService
        : IBaseCRUDService<NewsResponse, NewsSearch, NewsInsertRequest, NewsUpdateRequest>
    {
    }
}
