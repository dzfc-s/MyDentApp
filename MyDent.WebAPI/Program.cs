using MyDent.Common.Services.CryptoService;
using MyDent.Model.Requests;
using MyDent.Model.Responses;
using MyDent.Services;
using MyDent.Services.Database;
using MyDent.Services.Validators;
using MyDent.WebAPI.Filters;
using MyDent.WebAPI.Services;
using MyDent.WebAPI.Services.AccessManager;
using DotNetEnv;
using FluentValidation;
using Mapster;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using Scalar.AspNetCore;
using System.Text;

// Loads .env into process environment vars (walks up from CWD to find it, so it
// works whether you run from repo root, MyDent.WebAPI/, or from Visual Studio).
// ASP.NET Core's default configuration already reads environment variables, and
// treats "__" as the section separator (e.g. JwtToken__SecretKey -> JwtToken:SecretKey).
Env.TraversePath().Load();

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<IAuthenticatedUserAccessor, HttpAuthenticatedUserAccessor>();

builder.Services.AddControllers(
   options => options.Filters.Add<ExceptionFilter>()
);

// Add Entity Framework Core DbContext
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
builder.Services.AddDbContext<MyDentDbContext>(options =>
    options.UseSqlServer(connectionString)
);

// register Mapster for object mapping
builder.Services.AddMapster();

// configure a few mappings explicitly if needed (optional)
// Mapster will automatically map same-named properties, but configuration
// ensures any custom rules or future needs can be added here.
TypeAdapterConfig<User, UserResponse>.NewConfig().IgnoreNullValues(true);
TypeAdapterConfig<UserUpdateRequest, User>.NewConfig().IgnoreNullValues(true);
TypeAdapterConfig<Asset, AssetResponse>.NewConfig().IgnoreNullValues(true);
TypeAdapterConfig<ServiceCategory, ServiceCategoryResponse>.NewConfig().IgnoreNullValues(true);
TypeAdapterConfig<Doctor, DoctorResponse>.NewConfig().IgnoreNullValues(true);
// Doctor/ServiceCategory navigation properties are only populated when the query
// used .Include(...) (true for GET, not right after Insert/Update) — guard against
// null so an immediate create/update response doesn't crash, it just shows "".
TypeAdapterConfig<DoctorSpecialty, DoctorSpecialtyResponse>.NewConfig()
    .Map(dest => dest.DoctorName, src => src.Doctor != null ? src.Doctor.FirstName + " " + src.Doctor.LastName : string.Empty)
    .Map(dest => dest.ServiceCategoryName, src => src.ServiceCategory != null ? src.ServiceCategory.Name : string.Empty);
TypeAdapterConfig<DoctorWorkingHours, DoctorWorkingHoursResponse>.NewConfig()
    .Map(dest => dest.DoctorName, src => src.Doctor != null ? src.Doctor.FirstName + " " + src.Doctor.LastName : string.Empty);
TypeAdapterConfig<DoctorAbsence, DoctorAbsenceResponse>.NewConfig()
    .Map(dest => dest.DoctorName, src => src.Doctor != null ? src.Doctor.FirstName + " " + src.Doctor.LastName : string.Empty);
TypeAdapterConfig<DentalService, DentalServiceResponse>.NewConfig()
    .Map(dest => dest.ServiceCategoryName, src => src.ServiceCategory != null ? src.ServiceCategory.Name : string.Empty);
TypeAdapterConfig<Appointment, AppointmentResponse>.NewConfig()
    .Map(dest => dest.PatientName, src => src.Patient != null ? src.Patient.FirstName + " " + src.Patient.LastName : string.Empty)
    .Map(dest => dest.DoctorName, src => src.Doctor != null ? src.Doctor.FirstName + " " + src.Doctor.LastName : string.Empty)
    .Map(dest => dest.DentalServiceName, src => src.DentalService != null ? src.DentalService.Name : string.Empty);
TypeAdapterConfig<AppointmentStatusHistory, AppointmentStatusHistoryResponse>.NewConfig()
    .Map(dest => dest.ChangedByUserName, src => src.ChangedByUser != null ? src.ChangedByUser.FirstName + " " + src.ChangedByUser.LastName : string.Empty);

// TODO: add TypeAdapterConfig entries for the remaining dental-domain entities (Review, Notification, News, Payment, ...) here

// register application services
builder.Services.AddScoped<IUserService, UserService>();

builder.Services.AddScoped<IAssetService, AssetService>();

builder.Services.AddScoped<IRefreshTokenService, RefreshTokenService>();

builder.Services.AddScoped<IAccessManager, AccessManager>();

builder.Services.AddScoped<ICryptoService, CryptoService>();

builder.Services.AddScoped<IServiceCategoryService, ServiceCategoryService>();
builder.Services.AddScoped<IDoctorService, DoctorService>();
builder.Services.AddScoped<IDoctorSpecialtyService, DoctorSpecialtyService>();
builder.Services.AddScoped<IDoctorWorkingHoursService, DoctorWorkingHoursService>();
builder.Services.AddScoped<IDoctorAbsenceService, DoctorAbsenceService>();
builder.Services.AddScoped<IDentalServiceService, DentalServiceService>();
builder.Services.AddScoped<IAppointmentService, AppointmentService>();

// TODO: register remaining dental-domain services (Review, Notification, News, Payment, ...) here

builder.Services.AddScoped<IValidator<UserInsertRequest>, UserInsertValidator>();
builder.Services.AddScoped<IValidator<UserUpdateRequest>, UserUpdateValidator>();
builder.Services.AddScoped<IValidator<AssetInsertRequest>, AssetInsertValidator>();
builder.Services.AddScoped<IValidator<AssetUpdateRequest>, AssetUpdateValidator>();

builder.Services.AddScoped<IValidator<ServiceCategoryInsertRequest>, ServiceCategoryInsertValidator>();
builder.Services.AddScoped<IValidator<ServiceCategoryUpdateRequest>, ServiceCategoryUpdateValidator>();

builder.Services.AddScoped<IValidator<DoctorInsertRequest>, DoctorInsertValidator>();
builder.Services.AddScoped<IValidator<DoctorUpdateRequest>, DoctorUpdateValidator>();
builder.Services.AddScoped<IValidator<DoctorSpecialtyInsertRequest>, DoctorSpecialtyInsertValidator>();
builder.Services.AddScoped<IValidator<DoctorSpecialtyUpdateRequest>, DoctorSpecialtyUpdateValidator>();
builder.Services.AddScoped<IValidator<DoctorWorkingHoursInsertRequest>, DoctorWorkingHoursInsertValidator>();
builder.Services.AddScoped<IValidator<DoctorWorkingHoursUpdateRequest>, DoctorWorkingHoursUpdateValidator>();
builder.Services.AddScoped<IValidator<DoctorAbsenceInsertRequest>, DoctorAbsenceInsertValidator>();
builder.Services.AddScoped<IValidator<DoctorAbsenceUpdateRequest>, DoctorAbsenceUpdateValidator>();
builder.Services.AddScoped<IValidator<DentalServiceInsertRequest>, DentalServiceInsertValidator>();
builder.Services.AddScoped<IValidator<DentalServiceUpdateRequest>, DentalServiceUpdateValidator>();
builder.Services.AddScoped<IValidator<AppointmentInsertRequest>, AppointmentInsertValidator>();

// TODO: register remaining dental-domain validators here

// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();

builder.Services.AddAuthentication(options => // dodavanje authentfikacije i autorizacije u projekat
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultScheme = JwtBearerDefaults.AuthenticationScheme;
}).AddJwtBearer(o =>
{
    o.TokenValidationParameters = new TokenValidationParameters
    {
        ValidIssuer = builder.Configuration["JwtToken:Issuer"],
        ValidAudience = builder.Configuration["JwtToken:Audience"],
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(builder.Configuration["JwtToken:SecretKey"] ?? string.Empty)),
        // AccessManager issues the role claim as "Role" (ClaimNames.Role), not the
        // ClaimTypes.Role URI ASP.NET Core's role checks (incl. [Authorize(Roles=...)] and
        // ClaimsPrincipal.IsInRole) expect by default. Without this, every role check silently
        // fails — nothing exercised [Authorize(Roles=...)] until the Appointments controller.
        RoleClaimType = ClaimNames.Role,
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ClockSkew = TimeSpan.Zero
    };
});
builder.Services.AddAuthorization();


builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(
    options =>
    {
        options.SwaggerDoc("v1", new Microsoft.OpenApi.Models.OpenApiInfo
        {
            Version = "v1",
            Title = "MyDent API",
            Description = "API for the MyDent dental clinic management application"
        });

        var xmlFile = $"{System.Reflection.Assembly.GetExecutingAssembly().GetName().Name}.xml";
        options.IncludeXmlComments(Path.Combine(AppContext.BaseDirectory, xmlFile));

        var jwtSecurityScheme = new OpenApiSecurityScheme
        {
            BearerFormat = "JWT",
            Name = "JWT Authentication",
            In = ParameterLocation.Header,
            Type = SecuritySchemeType.Http,
            Scheme = JwtBearerDefaults.AuthenticationScheme,
            Reference = new OpenApiReference
            {
                Id = JwtBearerDefaults.AuthenticationScheme,
                Type = ReferenceType.SecurityScheme
            }
        };

        options.AddSecurityDefinition(jwtSecurityScheme.Reference.Id, jwtSecurityScheme);
        options.AddSecurityRequirement(new OpenApiSecurityRequirement
                {
                    { jwtSecurityScheme, Array.Empty<string>() }
                });
    });

var app = builder.Build();

// Configure the HTTP request pipeline.
//if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.MapScalarApiReference();


    app.UseSwagger();
    app.UseSwaggerUI();
}

//app.UseHttpsRedirection();

app.UseAuthentication();

app.UseAuthorization();

app.MapControllers();

app.Run();
