using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
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

        public ServiceCategoryService(
            MyDentDbContext dbContext,
            MapsterMapper.IMapper mapper,
            FluentValidation.IValidator<ServiceCategoryInsertRequest> insertValidator,
            FluentValidation.IValidator<ServiceCategoryUpdateRequest> updateValidator,
            IDentalServiceService dentalServiceService)
            : base(dbContext, mapper, insertValidator, updateValidator)
        {
            _dentalServiceService = dentalServiceService;
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
        }

        public override async Task<ServiceCategoryResponse> UpdateAsync(int id, ServiceCategoryUpdateRequest request)
        {
            if (!request.IsActive)
            {
                await DeactivateServicesInCategoryAsync(id);
            }

            return await base.UpdateAsync(id, request);
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
