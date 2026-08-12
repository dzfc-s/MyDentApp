using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.EntityFrameworkCore;
using MyDent.Model.Requests;
using MyDent.Model.Responses;
using MyDent.Model.SearchObjects;
using MyDent.Services.Database;

namespace MyDent.Services
{
    public class DentalServiceService
        : BaseCRUDService<DentalService, DentalServiceResponse, DentalServiceSearch, DentalServiceInsertRequest, DentalServiceUpdateRequest>,
          IDentalServiceService
    {
        public DentalServiceService(
            MyDentDbContext dbContext,
            MapsterMapper.IMapper mapper,
            FluentValidation.IValidator<DentalServiceInsertRequest> insertValidator,
            FluentValidation.IValidator<DentalServiceUpdateRequest> updateValidator)
            : base(dbContext, mapper, insertValidator, updateValidator)
        {
        }

        protected override Task<IQueryable<DentalService>> IncludeRelatedEntitiesAsync(DentalServiceSearch? search, IQueryable<DentalService> query = null!)
        {
            query = query.Include(s => s.ServiceCategory);
            return base.IncludeRelatedEntitiesAsync(search, query);
        }

        protected override IEnumerable<DentalService> ApplyFilters(IEnumerable<DentalService> query, DentalServiceSearch? search)
        {
            if (search != null)
            {
                if (!string.IsNullOrWhiteSpace(search.Name))
                {
                    query = query.Where(s => s.Name.Contains(search.Name, StringComparison.OrdinalIgnoreCase));
                }

                if (search.ServiceCategoryId.HasValue)
                {
                    query = query.Where(s => s.ServiceCategoryId == search.ServiceCategoryId.Value);
                }

                if (search.IsActive.HasValue)
                {
                    query = query.Where(s => s.IsActive == search.IsActive.Value);
                }
            }

            return query;
        }
    }
}
