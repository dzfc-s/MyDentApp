using MyDent.Services;
using MyDent.Model.Responses;
using MyDent.Model.SearchObjects;
using Microsoft.AspNetCore.Mvc;
using MyDent.Model.Requests;

namespace MyDent.WebAPI.Controllers;

public class AssetsController : BaseCRUDController<AssetResponse, AssetSearch, AssetInsertRequest, AssetUpdateRequest, IAssetService>
{
    public AssetsController(IAssetService assetService) : base(assetService)
    {
    }
}
