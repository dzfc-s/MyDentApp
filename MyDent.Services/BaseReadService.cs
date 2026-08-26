using MyDent.Model.Exceptions;
using MyDent.Model.Responses;
using MyDent.Model.SearchObjects;
using MyDent.Services.Database;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Threading.Tasks;
using System.Linq.Dynamic.Core;
using Microsoft.EntityFrameworkCore;

namespace MyDent.Services
{
    public abstract class BaseReadService<TEntity, TResponse, TSearch> : IBaseReadService<TResponse, TSearch>
        where TEntity : class
        where TSearch : BaseSearchObject
    {
        // An unbounded "get all" is treated as a defect — cap how much a single request can pull
        // back regardless of what PageSize the caller asks for. Raised from the original 100 to
        // 2000 to match the app's own documented bulk-fetch call sites (e.g. the desktop dashboard
        // aggregates client-side over "the full dataset" with pageSize:2000) — those were silently
        // truncated to 100 rows before, which was a correctness bug (wrong totals/charts), not just
        // a style choice. Safe to raise now that filtering/paging below execute in SQL instead of
        // pulling the whole table into memory first (see ApplyFilters below).
        private const int MaxPageSize = 2000;

        protected readonly MapsterMapper.IMapper _mapper;
        protected readonly MyDentDbContext _dbContext;

        protected BaseReadService(MapsterMapper.IMapper mapper, MyDentDbContext dbContext)
        {
            _mapper = mapper;
            _dbContext = dbContext;
        }


        /// <summary>
        /// Applies search filters to the query. Override in derived classes to implement specific filtering logic.
        /// IQueryable, not IEnumerable — so the Where/OrderBy clauses below compose into one SQL query instead of
        /// forcing the entire table to be loaded into memory before filtering (see history for the bug this fixed).
        /// </summary>
        protected abstract IQueryable<TEntity> ApplyFilters(IQueryable<TEntity> query, TSearch? search);

        public virtual async Task<PageResult<TResponse>> GetAllAsync(TSearch? search = null)
        {
            IQueryable<TEntity> query = this._dbContext.Set<TEntity>();

            query = await IncludeRelatedEntitiesAsync(search, query);
            query = ApplyFilters(query, search);

            int? totalCount = null;

            if (search.IncludeTotalCount ?? false)
            {
                totalCount = await query.CountAsync();
            }

            if (!string.IsNullOrWhiteSpace(search.SortBy))
            {
                query = query.OrderBy(ValidateSortBy(search.SortBy));
            }

            var effectivePageSize = Math.Min(search.PageSize ?? MaxPageSize, MaxPageSize);

            if (search.Page.HasValue)
            {
                query = query.Skip((search.Page.Value - 1) * effectivePageSize);
            }

            query = query.Take(effectivePageSize);

            // Materialize only this page of raw entities first, then project to the response DTO
            // in memory — the Mapster mapping call isn't SQL-translatable, so it can't be part of
            // the IQueryable pipeline above.
            var entities = await query.ToListAsync();
            var list = entities.Select(item => _mapper.Map<TResponse>(item)).ToList();

            var pageResult = new PageResult<TResponse>
            {
                Items = list,
                TotalCount = totalCount
            };

            return pageResult;
        }

        // search.SortBy is a raw client-supplied string fed into System.Linq.Dynamic.Core's
        // string-based OrderBy — passing it through unchecked lets a caller reference arbitrary
        // members/expressions instead of just a column to sort by. Restrict it to an actual public
        // property name on TEntity (optionally suffixed with "asc"/"desc") before it ever reaches
        // Dynamic Linq.
        private static string ValidateSortBy(string sortBy)
        {
            var parts = sortBy.Trim().Split(' ', StringSplitOptions.RemoveEmptyEntries);
            var propertyName = parts[0];
            var direction = parts.Length > 1 ? parts[1].ToLowerInvariant() : null;

            if (direction != null && direction != "asc" && direction != "desc")
            {
                throw new ClientException($"Invalid sort direction '{parts[1]}'. Use 'asc' or 'desc'.");
            }

            var property = typeof(TEntity).GetProperty(
                propertyName,
                BindingFlags.Public | BindingFlags.Instance | BindingFlags.IgnoreCase);

            if (property == null)
            {
                throw new ClientException($"Cannot sort by unknown field '{propertyName}'.");
            }

            return direction == null ? property.Name : $"{property.Name} {direction}";
        }

        protected virtual async Task<IQueryable<TEntity>> IncludeRelatedEntitiesAsync(TSearch? search, IQueryable<TEntity> query = null)
        {
            // Override in derived classes to include related entities if necessary
            return query;
        }


        public virtual async Task<TResponse> GetByIdAsync(int id)
        {
            IQueryable<TEntity> query = this._dbContext.Set<TEntity>();
            query = await IncludeRelatedEntitiesAsync(null, query);

            var entity = await query.FirstOrDefaultAsync(e => EF.Property<int>(e, "Id") == id);
            if (entity == null)
            {
                throw new KeyNotFoundException($"{typeof(TEntity).Name} with id {id} not found.");
            }

            return _mapper.Map<TResponse>(entity);
        }
    }
}
