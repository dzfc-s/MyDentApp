using Azure;
using MyDent.Model.Access;
using MyDent.Model.Exceptions;
using MyDent.Model.Requests;
using MyDent.Services;
using MyDent.WebAPI.Services.AccessManager;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MyDent.WebAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class AccessController : Controller
    {
        private readonly IAccessManager _accessManager;
        private readonly IUserService _userService;
        private readonly IRefreshTokenService _refreshTokenService;
        private readonly IAuthenticatedUserAccessor _userAccessor;

        public AccessController(
            IAccessManager accessManager,
            IUserService userService,
            IRefreshTokenService refreshTokenService,
            IAuthenticatedUserAccessor userAccessor)
        {
            _accessManager = accessManager;
            _userService = userService;
            _refreshTokenService = refreshTokenService;
            _userAccessor = userAccessor;
        }

        [HttpPost("Login")]
        public async Task<ActionResult> Login([FromBody] UserLoginRequest request)
        {
            var result = await _accessManager.LoginAsync(request);
            return Ok(result);
        }

        [HttpPost("LoginWithRefreshToken")]
        public async Task<ActionResult> LoginWithRefreshToken([FromBody] RefreshAccessTokenRequest request)
        {
            var result = await _accessManager.LoginWithRefreshTokenAsync(request);
            return Ok(result);
        }

        [HttpPost("Register")]
        public async Task<IActionResult> Register([FromBody] UserInsertRequest request)
        {
            await _userService.InsertAsync(request);
            return Ok("You have registered successfully");
        }

        // Part of the auth flow, same as Login/Register — a user who forgot their password by
        // definition can't authenticate first. Never reveals whether the email exists.
        [HttpPost("ForgotPassword")]
        public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordRequest request)
        {
            await _userService.ForgotPasswordAsync(request);
            return Ok();
        }

        [HttpPost("ResetPassword")]
        public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordRequest request)
        {
            await _userService.ResetPasswordAsync(request);
            return Ok();
        }

        // Server-side invalidation: revokes every refresh token this user has, so the session
        // can't be silently extended via LoginWithRefreshToken after logout. The access token
        // itself remains technically valid until it naturally expires (JwtToken__DurationInMinutes),
        // as is normal for stateless JWTs — the client is expected to discard it, and this closes
        // the one avenue (refresh) that would otherwise get them a fresh one without logging in again.
        [Authorize]
        [HttpPost("Logout")]
        public async Task<IActionResult> Logout()
        {
            var userId = _userAccessor.GetUserId()
                ?? throw new ClientException("Authenticated user could not be resolved.");
            await _refreshTokenService.DeleteAllUserRefreshTokensAsync(userId);
            return Ok();
        }
    }
}
