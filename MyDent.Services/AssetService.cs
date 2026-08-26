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

        // A page of Assets can be up to MaxPageSize (2000) rows — returning full Base64 image
        // content for every one of them here (instead of just on GetByIdAsync, which nothing calls
        // this heavily) would make list responses enormous for no reason nothing in either Flutter
        // app actually reads that field from a list call.
        public override async Task<PageResult<AssetResponse>> GetAllAsync(AssetSearch? search = null)
        {
            var result = await base.GetAllAsync(search);
            foreach (var item in result.Items)
            {
                item.Base64Content = string.Empty;
            }
            return result;
        }
    }
}
