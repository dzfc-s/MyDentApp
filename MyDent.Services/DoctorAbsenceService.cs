using System.Collections.Generic;
using System.Linq;
using Microsoft.EntityFrameworkCore;
using MyDent.Model.Requests;
using MyDent.Model.Responses;
using MyDent.Model.SearchObjects;
using MyDent.Services.Database;

namespace MyDent.Services
{
    public class DoctorAbsenceService
        : BaseCRUDService<DoctorAbsence, DoctorAbsenceResponse, DoctorAbsenceSearch, DoctorAbsenceInsertRequest, DoctorAbsenceUpdateRequest>,
          IDoctorAbsenceService
    {
        public DoctorAbsenceService(
            MyDentDbContext dbContext,
            MapsterMapper.IMapper mapper,
            FluentValidation.IValidator<DoctorAbsenceInsertRequest> insertValidator,
            FluentValidation.IValidator<DoctorAbsenceUpdateRequest> updateValidator)
            : base(dbContext, mapper, insertValidator, updateValidator)
        {
        }

        protected override Task<IQueryable<DoctorAbsence>> IncludeRelatedEntitiesAsync(DoctorAbsenceSearch? search, IQueryable<DoctorAbsence> query = null!)
        {
            query = query.Include(a => a.Doctor);
            return base.IncludeRelatedEntitiesAsync(search, query);
        }

        protected override IEnumerable<DoctorAbsence> ApplyFilters(IEnumerable<DoctorAbsence> query, DoctorAbsenceSearch? search)
        {
            if (search != null)
            {
                if (search.DoctorId.HasValue)
                {
                    query = query.Where(a => a.DoctorId == search.DoctorId.Value);
                }
            }

            return query;
        }
    }
}
