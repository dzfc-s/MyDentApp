using System.Collections.Generic;
using System.Linq;
using Microsoft.EntityFrameworkCore;
using MyDent.Model.Requests;
using MyDent.Model.Responses;
using MyDent.Model.SearchObjects;
using MyDent.Services.Database;

namespace MyDent.Services
{
    public class DoctorSpecialtyService
        : BaseCRUDService<DoctorSpecialty, DoctorSpecialtyResponse, DoctorSpecialtySearch, DoctorSpecialtyInsertRequest, DoctorSpecialtyUpdateRequest>,
          IDoctorSpecialtyService
    {
        public DoctorSpecialtyService(
            MyDentDbContext dbContext,
            MapsterMapper.IMapper mapper,
            FluentValidation.IValidator<DoctorSpecialtyInsertRequest> insertValidator,
            FluentValidation.IValidator<DoctorSpecialtyUpdateRequest> updateValidator)
            : base(dbContext, mapper, insertValidator, updateValidator)
        {
        }

        protected override Task<IQueryable<DoctorSpecialty>> IncludeRelatedEntitiesAsync(DoctorSpecialtySearch? search, IQueryable<DoctorSpecialty> query = null!)
        {
            query = query.Include(ds => ds.Doctor).Include(ds => ds.ServiceCategory);
            return base.IncludeRelatedEntitiesAsync(search, query);
        }

        protected override IQueryable<DoctorSpecialty> ApplyFilters(IQueryable<DoctorSpecialty> query, DoctorSpecialtySearch? search)
        {
            if (search != null)
            {
                if (search.DoctorId.HasValue)
                {
                    query = query.Where(ds => ds.DoctorId == search.DoctorId.Value);
                }

                if (search.ServiceCategoryId.HasValue)
                {
                    query = query.Where(ds => ds.ServiceCategoryId == search.ServiceCategoryId.Value);
                }
            }

            return query;
        }
    }
}
