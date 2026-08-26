using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using MyDent.Model.Requests;
using MyDent.Model.Responses;
using MyDent.Model.SearchObjects;
using MyDent.Services.Database;

namespace MyDent.Services
{
    public class ServiceCategoryService
        : BaseCRUDService<ServiceCategory, ServiceCategoryResponse, ServiceCategorySearch, ServiceCategoryInsertRequest, ServiceCategoryUpdateRequest>,
          IServiceCategoryService
    {
        private readonly IDentalServiceService _dentalServiceService;
        private readonly IMemoryCache _cache;

        // Categories rarely change (an admin edits them occasionally) but are read constantly —
        // every booking flow, service browse screen, and doctor specialty picker fetches them.
        // Cached at the service level per the "IMemoryCache for rarely-changing data" requirement,
        // not a Dictionary field (this service is Scoped — a field wouldn't survive past one
        // request anyway; IMemoryCache is backed by a singleton store).
        private const string CacheVersionKey = "ServiceCategory:CacheVersion";
        private static readonly TimeSpan CacheDuration = TimeSpan.FromMinutes(5);

        public ServiceCategoryService(
            MyDentDbContext dbContext,
            MapsterMapper.IMapper mapper,
            FluentValidation.IValidator<ServiceCategoryInsertRequest> insertValidator,
            FluentValidation.IValidator<ServiceCategoryUpdateRequest> updateValidator,
            IDentalServiceService dentalServiceService,
            IMemoryCache cache)
            : base(dbContext, mapper, insertValidator, updateValidator)
        {
            _dentalServiceService = dentalServiceService;
            _cache = cache;
        }

        // Every write bumps the version instead of trying to enumerate/remove individual cached
        // search-result entries (IMemoryCache has no key-prefix removal) — old entries simply stop
        // matching any future cache key and expire naturally off CacheDuration.
        private int BumpCacheVersion() => _cache.Set(CacheVersionKey, GetCacheVersion() + 1);

        private int GetCacheVersion() => _cache.TryGetValue(CacheVersionKey, out int v) ? v : 0;

        public override async Task<PageResult<ServiceCategoryResponse>> GetAllAsync(ServiceCategorySearch? search = null)
        {
            var cacheKey = $"ServiceCategory:v{GetCacheVersion()}:{search?.Name}:{search?.IsActive}:" +
                $"{search?.Page}:{search?.PageSize}:{search?.SortBy}:{search?.IncludeTotalCount}";

            if (_cache.TryGetValue(cacheKey, out PageResult<ServiceCategoryResponse>? cached) && cached != null)
            {
                return cached;
            }

            var result = await base.GetAllAsync(search);
            _cache.Set(cacheKey, result, CacheDuration);
            return result;
        }

        public override async Task<ServiceCategoryResponse> InsertAsync(ServiceCategoryInsertRequest request)
        {
            var result = await base.InsertAsync(request);
            BumpCacheVersion();
            return result;
        }

        // A service under an inactive category makes no sense to keep offering — cascade through
        // DentalServiceService.DeleteAsync (not a raw IsActive flip) so this also reuses its
        // existing "cancel future Pending/Confirmed appointments for this service" logic instead
        // of duplicating it here.
        private async Task DeactivateServicesInCategoryAsync(int categoryId)
        {
            var activeServiceIds = await _dbContext.DentalServices
                .Where(s => s.ServiceCategoryId == categoryId && s.IsActive)
                .Select(s => s.Id)
                .ToListAsync();

            foreach (var serviceId in activeServiceIds)
            {
                await _dentalServiceService.DeleteAsync(serviceId);
            }
        }

        public override async Task DeleteAsync(int id)
        {
            await DeactivateServicesInCategoryAsync(id);
            await base.DeleteAsync(id);
            BumpCacheVersion();
        }

        public override async Task<ServiceCategoryResponse> UpdateAsync(int id, ServiceCategoryUpdateRequest request)
        {
            if (!request.IsActive)
            {
                await DeactivateServicesInCategoryAsync(id);
            }

            var result = await base.UpdateAsync(id, request);
            BumpCacheVersion();
            return result;
        }

        protected override IQueryable<ServiceCategory> ApplyFilters(IQueryable<ServiceCategory> query, ServiceCategorySearch? search)
        {
            if (search != null)
            {
                if (!string.IsNullOrWhiteSpace(search.Name))
                {
                    query = query.Where(c => EF.Functions.Like(c.Name, $"%{search.Name}%"));
                }

                if (search.IsActive.HasValue)
                {
                    query = query.Where(c => c.IsActive == search.IsActive.Value);
                }
            }

            return query;
        }
    }
}
