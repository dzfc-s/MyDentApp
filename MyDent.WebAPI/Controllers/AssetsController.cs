using MyDent.Services;
using MyDent.Model.Responses;
using MyDent.Model.SearchObjects;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MyDent.Model.Requests;

namespace MyDent.WebAPI.Controllers;

// Assets (images) are referenced by public content (doctor photos, news images), so browsing
// (GetAll/GetById) stays public — an anonymous visitor still needs to load those images.
// Uploading is open to any authenticated user (e.g. a patient setting a profile picture);
// Update/Delete are Admin-only since assets carry no owner to check against.
public class AssetsController : BaseCRUDController<AssetResponse, AssetSearch, AssetInsertRequest, AssetUpdateRequest, IAssetService>
{
    public AssetsController(IAssetService assetService) : base(assetService)
    {
    }

    [Authorize]
    public override Task<ActionResult<AssetResponse>> Create([FromBody] AssetInsertRequest request)
        => base.Create(request);

    [Authorize(Roles = "Admin")]
    public override Task<ActionResult<AssetResponse>> Update(int id, [FromBody] AssetUpdateRequest request)
        => base.Update(id, request);

    [Authorize(Roles = "Admin")]
    public override Task<IActionResult> Delete(int id)
        => base.Delete(id);
}
