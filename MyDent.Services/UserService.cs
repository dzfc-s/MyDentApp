using MyDent.Common.Services.CryptoService;
using MyDent.Model.Access;
using MyDent.Model.Exceptions;
using MyDent.Model.Requests;
using MyDent.Model.Responses;
using MyDent.Model.SearchObjects;
using MyDent.Services.Database;
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
        public UserService(MyDentDbContext dbContext, MapsterMapper.IMapper mapper, IValidator<UserInsertRequest> insertValidator, IValidator<UserUpdateRequest> updateValidator, ICryptoService cryptoService, IAuthenticatedUserAccessor userAccessor)
            : base(dbContext, mapper, insertValidator, updateValidator)
        {
            _cryptoService = cryptoService;
            _userAccessor = userAccessor;
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
            // let FluentValidation throw if the request isn't valid; the exception filter will
            // convert the resulting ValidationException into the standard error format.
            await _insertValidator.ValidateAndThrowAsync(request);

            // Check if email or username already exists
            if (await _dbContext.Users.AnyAsync(u => u.Email == request.Email))
            {
                throw new InvalidOperationException($"Email '{request.Email}' is already in use.");
            }

            if (await _dbContext.Users.AnyAsync(u => u.Username == request.Username))
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

            await _updateValidator.ValidateAndThrowAsync(request);

            var entity = await _dbContext.Users.FindAsync(id);
            if (entity == null)
            {
                throw new KeyNotFoundException($"User with id {id} not found.");
            }

            // Check if email or username already exists
            if (await _dbContext.Users.AnyAsync(u => u.Email == request.Email && u.Id != id))
            {
                throw new InvalidOperationException($"Email '{request.Email}' is already in use.");
            }

            if (await _dbContext.Users.AnyAsync(u => u.Username == request.Username && u.Id != id))
            {
                throw new InvalidOperationException($"Username '{request.Username}' is already in use.");
            }

            MapUpdateRequestToEntity(request, entity);

            _dbContext.Users.Update(entity);
            await _dbContext.SaveChangesAsync();

            return _mapper.Map<UserResponse>(entity);
        }

        public override async Task DeleteAsync(int id)
        {
            var entity = await _dbContext.Users.FirstOrDefaultAsync(u => u.Id == id);
            if (entity == null)
            {
                throw new KeyNotFoundException($"User with id {id} not found.");
            }

            _dbContext.Users.Remove(entity);
            await _dbContext.SaveChangesAsync();
        }

        public async Task<UserSensitveResponse?> GetByUsernameAsync(string username)
        {
            var user = await _dbContext.Users
                .AsNoTracking()
                .Include(u => u.UserRoles)
                .ThenInclude(ur => ur.Role)
                .FirstOrDefaultAsync(u => u.Username == username);

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
            var userId = _userAccessor.GetUserId()
                ?? throw new ClientException("Authenticated user could not be resolved.");
            var user = _dbContext.Users.FirstOrDefault(u => u.Id == userId);

            if (user == null)
                throw new ClientException("User not found");

            if (!_cryptoService.Verify(user.PasswordHash, user.PasswordSalt, request.Password))
                throw new ClientException("Wrong credential");

            if (!request.NewPassword.Equals(request.ConfirmNewPassword))
                throw new ClientException("Password confirmation doesn't match new password");

            user.PasswordSalt = _cryptoService.GenerateSalt();
            user.PasswordHash = _cryptoService.GenerateHash(request.NewPassword, user.PasswordSalt);


            _dbContext.Users.Update(user);
            await _dbContext.SaveChangesAsync();
        }
    }
}
