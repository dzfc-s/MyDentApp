using MyDent.Model.Access;
using MyDent.Model.Requests;
using MyDent.Model.Responses;
using MyDent.Model.SearchObjects;
using MyDent.Services;
using MyDent.WebAPI.Filters;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MyDent.WebAPI.Controllers;

// Managing the full user list and creating/deleting accounts is an Admin action. Public
// self-registration goes through AccessController.Register, not here. GetById/Update are also
// reachable by the user themselves, for their own profile including health-record fields —
// ownership is enforced in UserService, not here. ChangePassword is likewise any authenticated
// user, for their own password only.
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

    [Authorize]
    public override Task<ActionResult<UserResponse>> GetById(int id)
        => base.GetById(id);

    [Authorize(Roles = "Admin")]
    public override Task<ActionResult<UserResponse>> Create([FromBody] UserInsertRequest request)
        => base.Create(request);

    [Authorize]
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
