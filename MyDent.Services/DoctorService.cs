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
    public class DoctorService
        : BaseCRUDService<Doctor, DoctorResponse, DoctorSearch, DoctorInsertRequest, DoctorUpdateRequest>,
          IDoctorService
    {
        public DoctorService(
            MyDentDbContext dbContext,
            MapsterMapper.IMapper mapper,
            FluentValidation.IValidator<DoctorInsertRequest> insertValidator,
            FluentValidation.IValidator<DoctorUpdateRequest> updateValidator)
            : base(dbContext, mapper, insertValidator, updateValidator)
        {
        }

        protected override Task<IQueryable<Doctor>> IncludeRelatedEntitiesAsync(DoctorSearch? search, IQueryable<Doctor> query = null!)
        {
            if (search?.ServiceCategoryId.HasValue == true)
            {
                query = query.Include(d => d.DoctorSpecialties);
            }

            return base.IncludeRelatedEntitiesAsync(search, query);
        }

        protected override IEnumerable<Doctor> ApplyFilters(IEnumerable<Doctor> query, DoctorSearch? search)
        {
            if (search != null)
            {
                if (!string.IsNullOrWhiteSpace(search.Name))
                {
                    query = query.Where(d =>
                        d.FirstName.Contains(search.Name, StringComparison.OrdinalIgnoreCase) ||
                        d.LastName.Contains(search.Name, StringComparison.OrdinalIgnoreCase));
                }

                if (search.IsActive.HasValue)
                {
                    query = query.Where(d => d.IsActive == search.IsActive.Value);
                }

                if (search.ServiceCategoryId.HasValue)
                {
                    query = query.Where(d => d.DoctorSpecialties.Any(ds => ds.ServiceCategoryId == search.ServiceCategoryId.Value));
                }
            }

            return query;
        }
    }
}
