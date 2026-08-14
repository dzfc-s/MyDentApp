using MyDent.Model.Access;
using MyDent.Model.Requests;
using MyDent.Model.Responses;
using MyDent.Model.SearchObjects;
using MyDent.Services;
using MyDent.WebAPI.Filters;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MyDent.WebAPI.Controllers;

// Managing the user list (list all, view any profile, create/edit/delete an account) is an
// Admin action. Public self-registration goes through AccessController.Register, not here.
// ChangePassword is the one exception: any authenticated user changes their own password.
[ApiController]
[Route("[controller]")]
public class UsersController : BaseCRUDController<UserResponse, UserSearch, UserInsertRequest, UserUpdateRequest, IUserService>
{
    public UsersController(IUserService userService) : base(userService)
    {
    }

    [Authorize(Roles = "Admin")]
    public override Task<PageResult<UserResponse>> GetAll([FromQuery] UserSearch? search)
        => base.GetAll(search);

    [Authorize(Roles = "Admin")]
    public override Task<ActionResult<UserResponse>> GetById(int id)
        => base.GetById(id);

    [Authorize(Roles = "Admin")]
    public override Task<ActionResult<UserResponse>> Create([FromBody] UserInsertRequest request)
        => base.Create(request);

    [Authorize(Roles = "Admin")]
    public override Task<ActionResult<UserResponse>> Update(int id, [FromBody] UserUpdateRequest request)
        => base.Update(id, request);

    [Authorize(Roles = "Admin")]
    public override Task<IActionResult> Delete(int id)
        => base.Delete(id);

    [Authorize]
    [HttpPut("ChangePassword")]
    public async Task<IActionResult> ChangePassword([FromBody] UserPasswordChangeRequest request)
    {
        await _service.ChangePasswordAsync(request);
        return Ok();
    }
}
