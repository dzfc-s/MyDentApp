using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MyDent.Model.Requests;
using MyDent.Model.Responses;
using MyDent.Model.SearchObjects;
using MyDent.Services;

namespace MyDent.WebAPI.Controllers;

// GetAll/GetById are intentionally left open (no [Authorize]) — News is public-facing clinic
// content, like a website's news/announcements section. NewsService.ApplyFilters/GetByIdAsync
// already hide unpublished drafts from anyone who isn't Admin, authenticated or not. Only the
// write actions are staff-only.
public class NewsController
    : BaseReadController<NewsResponse, NewsSearch, INewsService>
{
    public NewsController(INewsService service) : base(service)
    {
    }

    [HttpPost]
    [Authorize(Roles = "Admin")]
    [ProducesResponseType(StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<NewsResponse>> Create([FromBody] NewsInsertRequest request)
    {
        var result = await _service.InsertAsync(request);
        return result;
    }

    [HttpPut("{id}")]
    [Authorize(Roles = "Admin")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<NewsResponse>> Update(int id, [FromBody] NewsUpdateRequest request)
    {
        // KeyNotFoundException -> 404 is now handled centrally by ExceptionFilter.
        return await _service.UpdateAsync(id, request);
    }

    [HttpDelete("{id}")]
    [Authorize(Roles = "Admin")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(int id)
    {
        await _service.DeleteAsync(id);
        return NoContent();
    }
}
