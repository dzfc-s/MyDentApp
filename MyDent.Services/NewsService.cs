using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using MyDent.Model.Exceptions;
using MyDent.Model.Requests;
using MyDent.Model.Responses;
using MyDent.Model.SearchObjects;
using MyDent.Services.Database;

namespace MyDent.Services
{
    public class NewsService
        : BaseCRUDService<News, NewsResponse, NewsSearch, NewsInsertRequest, NewsUpdateRequest>,
          INewsService
    {
        private readonly IAuthenticatedUserAccessor _userAccessor;

        public NewsService(
            MyDentDbContext dbContext,
            MapsterMapper.IMapper mapper,
            FluentValidation.IValidator<NewsInsertRequest> insertValidator,
            FluentValidation.IValidator<NewsUpdateRequest> updateValidator,
            IAuthenticatedUserAccessor userAccessor)
            : base(dbContext, mapper, insertValidator, updateValidator)
        {
            _userAccessor = userAccessor;
        }

        protected override Task<IQueryable<News>> IncludeRelatedEntitiesAsync(NewsSearch? search, IQueryable<News> query = null!)
        {
            query = query.Include(n => n.CreatedByUser);
            return base.IncludeRelatedEntitiesAsync(search, query);
        }

        protected override IEnumerable<News> ApplyFilters(IEnumerable<News> query, NewsSearch? search)
        {
            // Public/patient callers only ever see published articles, regardless of what's
            // requested — same private-content principle as Notification, just "not yet public"
            // instead of "not yours".
            if (!_userAccessor.IsInRole("Admin"))
            {
                query = query.Where(n => n.IsPublished);
            }
            else if (search?.IsPublished.HasValue == true)
            {
                query = query.Where(n => n.IsPublished == search.IsPublished.Value);
            }

            if (!string.IsNullOrWhiteSpace(search?.Title))
            {
                query = query.Where(n => n.Title.Contains(search.Title, StringComparison.OrdinalIgnoreCase));
            }

            return query;
        }

        // GetAllAsync goes through ApplyFilters above, but GetByIdAsync bypasses it — needs its
        // own visibility check. Returns "not found" rather than a 403-style error so a draft's
        // existence isn't revealed to non-Admins.
        public override async Task<NewsResponse> GetByIdAsync(int id)
        {
            IQueryable<News> query = _dbContext.Set<News>();
            query = await IncludeRelatedEntitiesAsync(null, query);
            var entity = await query.FirstOrDefaultAsync(n => n.Id == id);

            if (entity == null || (!entity.IsPublished && !_userAccessor.IsInRole("Admin")))
            {
                throw new KeyNotFoundException($"News with id {id} not found.");
            }

            return _mapper.Map<NewsResponse>(entity);
        }

        protected override News MapInsertRequestToEntity(NewsInsertRequest request)
        {
            var entity = base.MapInsertRequestToEntity(request);
            entity.CreatedByUserId = _userAccessor.GetUserId()
                ?? throw new ClientException("Authenticated user could not be resolved.");
            entity.PublishedAt = DateTime.UtcNow;
            return entity;
        }
    }
}
