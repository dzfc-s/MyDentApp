using System.Collections.Generic;
using System.Linq;
using Microsoft.EntityFrameworkCore;
using MyDent.Model.Requests;
using MyDent.Model.Responses;
using MyDent.Model.SearchObjects;
using MyDent.Services.Database;

namespace MyDent.Services
{
    public class DoctorWorkingHoursService
        : BaseCRUDService<DoctorWorkingHours, DoctorWorkingHoursResponse, DoctorWorkingHoursSearch, DoctorWorkingHoursInsertRequest, DoctorWorkingHoursUpdateRequest>,
          IDoctorWorkingHoursService
    {
        public DoctorWorkingHoursService(
            MyDentDbContext dbContext,
            MapsterMapper.IMapper mapper,
            FluentValidation.IValidator<DoctorWorkingHoursInsertRequest> insertValidator,
            FluentValidation.IValidator<DoctorWorkingHoursUpdateRequest> updateValidator)
            : base(dbContext, mapper, insertValidator, updateValidator)
        {
        }

        protected override Task<IQueryable<DoctorWorkingHours>> IncludeRelatedEntitiesAsync(DoctorWorkingHoursSearch? search, IQueryable<DoctorWorkingHours> query = null!)
        {
            query = query.Include(wh => wh.Doctor);
            return base.IncludeRelatedEntitiesAsync(search, query);
        }

        protected override IQueryable<DoctorWorkingHours> ApplyFilters(IQueryable<DoctorWorkingHours> query, DoctorWorkingHoursSearch? search)
        {
            if (search != null)
            {
                if (search.DoctorId.HasValue)
                {
                    query = query.Where(wh => wh.DoctorId == search.DoctorId.Value);
                }

                if (search.DayOfWeek.HasValue)
                {
                    query = query.Where(wh => wh.DayOfWeek == search.DayOfWeek.Value);
                }
            }

            return query;
        }
    }
}
