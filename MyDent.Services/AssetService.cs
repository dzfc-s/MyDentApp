using MyDent.Model.Requests;
using MyDent.Model.Responses;
using MyDent.Model.SearchObjects;
using MyDent.Services.Database;
using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MyDent.Services
{
    public class AssetService : BaseCRUDService<Asset, AssetResponse, AssetSearch, AssetInsertRequest, AssetUpdateRequest>, IAssetService
    {
        public AssetService(MyDentDbContext dbContext, IMapper mapper, IValidator<AssetInsertRequest> insertValidator, IValidator<AssetUpdateRequest> updateValidator)
           : base(dbContext, mapper, insertValidator, updateValidator)
        {
        }

        protected override IQueryable<Asset> ApplyFilters(IQueryable<Asset> query, AssetSearch? search)
        {
            if (search != null)
            {
                if (!string.IsNullOrWhiteSpace(search.FileName))
                {
                    query = query.Where(a => EF.Functions.Like(a.FileName, $"%{search.FileName}%"));
                }

                if (!string.IsNullOrWhiteSpace(search.ContentType))
                {
                    query = query.Where(a => EF.Functions.Like(a.ContentType, $"%{search.ContentType}%"));
                }
            }

            return query;
        }
    }
}
