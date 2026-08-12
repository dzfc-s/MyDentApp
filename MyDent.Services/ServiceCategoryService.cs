using System;
using System.Collections.Generic;
using System.Linq;
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
        public ServiceCategoryService(
            MyDentDbContext dbContext,
            MapsterMapper.IMapper mapper,
            FluentValidation.IValidator<ServiceCategoryInsertRequest> insertValidator,
            FluentValidation.IValidator<ServiceCategoryUpdateRequest> updateValidator)
            : base(dbContext, mapper, insertValidator, updateValidator)
        {
        }

        protected override IEnumerable<ServiceCategory> ApplyFilters(IEnumerable<ServiceCategory> query, ServiceCategorySearch? search)
        {
            if (search != null)
            {
                if (!string.IsNullOrWhiteSpace(search.Name))
                {
                    query = query.Where(c => c.Name.Contains(search.Name, StringComparison.OrdinalIgnoreCase));
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
