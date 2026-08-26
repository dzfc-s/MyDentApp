using MyDent.Common.Services.CryptoService;
using MyDent.Model.Access;
using MyDent.Model.Exceptions;
using MyDent.Model.Requests;
using MyDent.Model.Responses;
using MyDent.Model.SearchObjects;
using MyDent.Services.Database;
using MyDent.Services.Messaging;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;

namespace MyDent.Services
{
    public class UserService : BaseCRUDService<User, UserResponse, UserSearch, UserInsertRequest, UserUpdateRequest>, IUserService
    {
        private readonly ICryptoService _cryptoService;
        private readonly IAuthenticatedUserAccessor _userAccessor;
        private readonly IEmailEventPublisher _emailPublisher;
        private readonly IValidator<UserPasswordChangeRequest> _passwordChangeValidator;
        private readonly IValidator<ForgotPasswordRequest> _forgotPasswordValidator;
        private readonly IValidator<ResetPasswordRequest> _resetPasswordValidator;

        public UserService(
            MyDentDbContext dbContext,
            MapsterMapper.IMapper mapper,
            IValidator<UserInsertRequest> insertValidator,
            IValidator<UserUpdateRequest> updateValidator,
            ICryptoService cryptoService,
            IAuthenticatedUserAccessor userAccessor,
            IEmailEventPublisher emailPublisher,
            IValidator<UserPasswordChangeRequest> passwordChangeValidator,
            IValidator<ForgotPasswordRequest> forgotPasswordValidator,
            IValidator<ResetPasswordRequest> resetPasswordValidator)
            : base(dbContext, mapper, insertValidator, updateValidator)
        {
            _cryptoService = cryptoService;
            _userAccessor = userAccessor;
            _emailPublisher = emailPublisher;
            _passwordChangeValidator = passwordChangeValidator;
            _forgotPasswordValidator = forgotPasswordValidator;
            _resetPasswordValidator = resetPasswordValidator;
        }


        protected override Task<IQueryable<User>> IncludeRelatedEntitiesAsync(UserSearch? search, IQueryable<User> query = null!)
        {
            query = query.Include(u => u.UserRoles).ThenInclude(ur => ur.Role);
            return base.IncludeRelatedEntitiesAsync(search, query);
        }

        protected override IQueryable<User> ApplyFilters(IQueryable<User> query, UserSearch? search)
        {
            if (search != null)
            {
                if (!string.IsNullOrWhiteSpace(search.Role))
                {
                    query = query.Where(u => u.UserRoles.Any(ur => ur.Role.Name == search.Role));
                }

                if (!string.IsNullOrWhiteSpace(search.Email))
                {
                    query = query.Where(u => EF.Functions.Like(u.Email, $"%{search.Email}%"));
                }

                if (!string.IsNullOrWhiteSpace(search.Username))
                {
                    query = query.Where(u => EF.Functions.Like(u.Username, $"%{search.Username}%"));
                }

                if (!string.IsNullOrWhiteSpace(search.Name))
                {
                    query = query.Where(u => EF.Functions.Like(u.FirstName, $"%{search.Name}%")
                                          || EF.Functions.Like(u.LastName, $"%{search.Name}%"));
                }

                if (search.IsActive.HasValue)
                {
                    query = query.Where(u => u.IsActive == search.IsActive.Value);
                }
            }

            return query;
        }

        protected override User MapInsertRequestToEntity(UserInsertRequest request)
        {
            var entity = base.MapInsertRequestToEntity(request);

            // Handle password hashing for User entity
            var salt = _cryptoService.GenerateSalt();
            entity.PasswordSalt = salt;
            entity.PasswordHash = _cryptoService.GenerateHash(request.Password, salt);

            return entity;
        }

        public override async Task<UserResponse> InsertAsync(UserInsertRequest request)
        {
            // Trim + lowercase before anything else touches Email/Username, so validation,
            // the uniqueness checks below, and stored data all agree on one canonical form —
            // otherwise "User@Example.com" and "user@example.com " (trailing space) are treated
            // as different values and can register as separate accounts / fail to log back in.
            request.Email = request.Email.Trim().ToLowerInvariant();
            request.Username = request.Username.Trim().ToLowerInvariant();

            // let FluentValidation throw if the request isn't valid; the exception filter will
            // convert the resulting ValidationException into the standard error format.
            await _insertValidator.ValidateAndThrowAsync(request);

            // Check if email or username already exists
            if (await _dbContext.Users.AnyAsync(u => u.Email.ToLower() == request.Email))
            {
                throw new InvalidOperationException($"Email '{request.Email}' is already in use.");
            }

            if (await _dbContext.Users.AnyAsync(u => u.Username.ToLower() == request.Username))
            {
                throw new InvalidOperationException($"Username '{request.Username}' is already in use.");
            }

            var entity = MapInsertRequestToEntity(request);
            entity.CreatedAt = DateTime.UtcNow;

            // Two SaveChangesAsync calls (User needs its identity Id generated before UserRole
            // can reference it) — wrapped in one transaction so a crash between them can't leave
            // a User row with no role assigned.
            await using var transaction = await _dbContext.Database.BeginTransactionAsync();

            _dbContext.Users.Add(entity);
            await _dbContext.SaveChangesAsync();

            // Self-registration (and any other InsertAsync caller) always gets the default,
            // least-privileged role — nothing in UserInsertRequest lets a caller pick a role.
            // Without this, a registered user has zero UserRoles rows, so their JWT falls back
            // to a "user" role claim that matches neither "Admin" nor "Patient" role checks.
            var patientRole = await _dbContext.Roles.FirstOrDefaultAsync(r => r.Name == "Patient")
                ?? throw new InvalidOperationException("Default 'Patient' role is not seeded.");

            _dbContext.UserRoles.Add(new UserRole
            {
                UserId = entity.Id,
                RoleId = patientRole.Id,
                DateAssigned = DateTime.UtcNow
            });
            await _dbContext.SaveChangesAsync();

            await transaction.CommitAsync();

            return _mapper.Map<UserResponse>(entity);
        }


        public override async Task<UserResponse> GetByIdAsync(int id)
        {
            var user = await _dbContext.Users
                .Include(u => u.UserRoles)
                .ThenInclude(ur => ur.Role)
                .FirstOrDefaultAsync(u => u.Id == id);

            if (user == null)
            {
                throw new KeyNotFoundException($"User with id {id} not found.");
            }

            // Doctors have no User/login account in this system (see Doctor.cs) — only "Admin"
            // and "Patient" roles exist, so the only callers here are Admin staff or the patient
            // viewing their own record.
            var callerId = _userAccessor.GetUserId();
            var isSelf = callerId.HasValue && callerId.Value == id;
            if (!isSelf && !_userAccessor.IsInRole("Admin"))
            {
                throw new ClientException("You can only view your own profile.");
            }

            var response = _mapper.Map<UserResponse>(user);
            response.Role = user.UserRoles.FirstOrDefault()?.Role.Name ?? string.Empty;
            return response;
        }

        public override async Task<UserResponse> UpdateAsync(int id, UserUpdateRequest request)
        {
            var callerId = _userAccessor.GetUserId();
            if (callerId != id && !_userAccessor.IsInRole("Admin"))
            {
                throw new ClientException("You can only edit your own profile.");
            }

            if (request.Email != null)
            {
                request.Email = request.Email.Trim().ToLowerInvariant();
            }
            if (request.Username != null)
            {
                request.Username = request.Username.Trim().ToLowerInvariant();
            }

            await _updateValidator.ValidateAndThrowAsync(request);

            var entity = await _dbContext.Users.FindAsync(id);
            if (entity == null)
            {
                throw new KeyNotFoundException($"User with id {id} not found.");
            }

            // Check if email or username already exists
            if (await _dbContext.Users.AnyAsync(u => u.Email.ToLower() == request.Email && u.Id != id))
            {
                throw new InvalidOperationException($"Email '{request.Email}' is already in use.");
            }

            if (await _dbContext.Users.AnyAsync(u => u.Username.ToLower() == request.Username && u.Id != id))
            {
                throw new InvalidOperationException($"Username '{request.Username}' is already in use.");
            }

            MapUpdateRequestToEntity(request, entity);

            _dbContext.Users.Update(entity);
            await _dbContext.SaveChangesAsync();

            return _mapper.Map<UserResponse>(entity);
        }

        public async Task<UserSensitveResponse?> GetByUsernameAsync(string username)
        {
            // Despite the parameter name, this also matches by Email — the approved project scope
            // specifies "login via email + password" for the mobile app, but username-based login
            // already worked and plenty of people expect either to work, so this accepts both
            // instead of removing one.
            var normalized = username.Trim().ToLowerInvariant();
            var user = await _dbContext.Users
                .AsNoTracking()
                .Include(u => u.UserRoles)
                .ThenInclude(ur => ur.Role)
                .FirstOrDefaultAsync(u => u.Username.ToLower() == normalized || u.Email.ToLower() == normalized);

            UserSensitveResponse? response = null;

            if (user != null)
            {
                response = _mapper.Map<UserSensitveResponse>(user);
                response.Role = user.UserRoles.FirstOrDefault()?.Role.Name;
            }

            return response;
        }

        public async Task<UserResponse?> GetWithRoleByIdAsync(int id)
        {
            var user = await _dbContext.Users
               .AsNoTracking()
               .Include(u => u.UserRoles)
               .ThenInclude(ur => ur.Role)
               .FirstOrDefaultAsync(u => u.Id == id);

            UserResponse? response = null;

            if (user != null)
            {
                response = _mapper.Map<UserResponse>(user);
                response.Role = user.UserRoles.First().Role.Name;
            }

            return response;
        }

        public async Task ChangePasswordAsync(UserPasswordChangeRequest request)
        {
            await _passwordChangeValidator.ValidateAndThrowAsync(request);

            var userId = _userAccessor.GetUserId()
                ?? throw new ClientException("Authenticated user could not be resolved.");
            var user = _dbContext.Users.FirstOrDefault(u => u.Id == userId);

            if (user == null)
                throw new ClientException("User not found");

            if (!_cryptoService.Verify(user.PasswordHash, user.PasswordSalt, request.Password))
                throw new ClientException("Trenutna lozinka nije tačna.");

            if (!request.NewPassword.Equals(request.ConfirmNewPassword))
                throw new ClientException("Nova lozinka i potvrda lozinke se ne podudaraju.");

            user.PasswordSalt = _cryptoService.GenerateSalt();
            user.PasswordHash = _cryptoService.GenerateHash(request.NewPassword, user.PasswordSalt);


            _dbContext.Users.Update(user);
            await _dbContext.SaveChangesAsync();
        }

        // Doesn't reveal whether the email exists — always returns normally either way, so an
        // attacker can't use this endpoint to enumerate registered emails.
        public async Task ForgotPasswordAsync(ForgotPasswordRequest request)
        {
            await _forgotPasswordValidator.ValidateAndThrowAsync(request);

            var user = await _dbContext.Users.FirstOrDefaultAsync(u => u.Email == request.Email);
            if (user == null)
            {
                return;
            }

            // A fresh request invalidates any earlier unused code for this user — only the most
            // recently requested one should work.
            var previousTokens = await _dbContext.PasswordResetTokens
                .Where(t => t.UserId == user.Id && t.UsedAt == null)
                .ToListAsync();
            _dbContext.PasswordResetTokens.RemoveRange(previousTokens);

            // 6-digit numeric code, emailed rather than a clickable link — no mobile deep-link
            // handling needed. RandomNumberGenerator (not System.Random) for the actual randomness.
            var code = RandomNumberGenerator.GetInt32(0, 1_000_000).ToString("D6");

            _dbContext.PasswordResetTokens.Add(new PasswordResetToken
            {
                UserId = user.Id,
                CodeHash = HashResetCode(request.Email, code),
                ExpiresAt = DateTime.UtcNow.AddMinutes(15),
                CreatedAt = DateTime.UtcNow
            });
            await _dbContext.SaveChangesAsync();

            await _emailPublisher.PublishPasswordResetEmailAsync(new PasswordResetEmailRequest
            {
                ToEmail = user.Email,
                FirstName = user.FirstName,
                Code = code
            });
        }

        public async Task ResetPasswordAsync(ResetPasswordRequest request)
        {
            await _resetPasswordValidator.ValidateAndThrowAsync(request);

            if (!request.NewPassword.Equals(request.ConfirmNewPassword))
            {
                throw new ClientException("Nova lozinka i potvrda lozinke se ne podudaraju.");
            }

            var user = await _dbContext.Users.FirstOrDefaultAsync(u => u.Email == request.Email);
            var codeHash = user != null ? HashResetCode(request.Email, request.Code) : null;

            // Same "invalid code" message whether the email doesn't exist or the code is wrong/
            // expired/already used — doesn't tell an attacker which case they hit.
            var token = user == null
                ? null
                : await _dbContext.PasswordResetTokens
                    .Where(t => t.UserId == user.Id && t.CodeHash == codeHash
                        && t.UsedAt == null && t.ExpiresAt > DateTime.UtcNow)
                    .OrderByDescending(t => t.CreatedAt)
                    .FirstOrDefaultAsync();

            if (user == null || token == null)
            {
                throw new ClientException("Kod je neispravan ili je istekao.");
            }

            token.UsedAt = DateTime.UtcNow;
            user.PasswordSalt = _cryptoService.GenerateSalt();
            user.PasswordHash = _cryptoService.GenerateHash(request.NewPassword, user.PasswordSalt);

            await _dbContext.SaveChangesAsync();
        }

        // Codes are short (6 digits) and short-lived (15 min) — a fast, unsalted hash is fine here
        // (this is not password storage; SHA-256 just keeps the raw code out of the database, per
        // the "reset kodovi se ne smiju čuvati u plain text formatu" requirement). Salted with the
        // email so the same code for two different accounts never collides in the DB.
        private static string HashResetCode(string email, string code)
        {
            var bytes = Encoding.UTF8.GetBytes($"{email.ToLowerInvariant()}:{code}");
            return Convert.ToBase64String(SHA256.HashData(bytes));
        }
    }
}
