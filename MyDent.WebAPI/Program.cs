using MyDent.Common.Services.CryptoService;
using MyDent.Model.Requests;
using MyDent.Model.Responses;
using MyDent.Services;
using MyDent.Services.Database;
using MyDent.Services.Messaging;
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

builder.Services.AddMemoryCache();
builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<IAuthenticatedUserAccessor, HttpAuthenticatedUserAccessor>();

builder.Services.AddControllers(
   options => options.Filters.Add<ExceptionFilter>()
);

// Both clients are native apps (Flutter Windows/Android), not browser-based, so CORS never
// actually gates a real request here — this exists so Swagger/Scalar (served from the API's own
// origin, still same-origin) and any future browser-based tool against this API have an explicit,
// single, named policy rather than none at all or an implicit AllowAnyOrigin.
builder.Services.AddCors(options =>
{
    options.AddPolicy("MyDentCors", policy =>
    {
        policy.WithOrigins("http://localhost:5126", "http://127.0.0.1:5126")
            .AllowAnyHeader()
            .AllowAnyMethod();
    });
});

// Add Entity Framework Core DbContext
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
builder.Services.AddDbContext<MyDentDbContext>(options =>
    options.UseSqlServer(connectionString)
);

// Stripe.net reads this static config on every API call it makes (PaymentService), so it only
// needs to be set once here rather than passed around.
Stripe.StripeConfiguration.ApiKey = builder.Configuration["Stripe:SecretKey"];

// QuestPDF requires this to be set once at startup — Community is free (no watermark) for a
// project like this (open-source / non-commercial, well under the revenue threshold).
QuestPDF.Settings.License = QuestPDF.Infrastructure.LicenseType.Community;

// RabbitMQ connection settings, all from .env — the publisher itself is registered as a
// Singleton below so its connection is opened once (lazily, on first publish) and reused.
var rabbitMqOptions = new RabbitMqOptions
{
    HostName = builder.Configuration["RabbitMQ:HostName"] ?? "localhost",
    Port = int.Parse(builder.Configuration["RabbitMQ:Port"] ?? "5672"),
    UserName = builder.Configuration["RabbitMQ:UserName"] ?? "guest",
    Password = builder.Configuration["RabbitMQ:Password"] ?? "guest",
    NotificationsQueueName = builder.Configuration["RabbitMQ:NotificationsQueueName"] ?? "appointment-notifications",
    PasswordResetEmailQueueName = builder.Configuration["RabbitMQ:PasswordResetEmailQueueName"] ?? "password-reset-emails"
};
builder.Services.AddSingleton(rabbitMqOptions);
builder.Services.AddSingleton<IAppointmentEventPublisher, RabbitMqAppointmentEventPublisher>();
builder.Services.AddSingleton<IEmailEventPublisher, RabbitMqEmailEventPublisher>();

// register Mapster for object mapping
builder.Services.AddMapster();

// configure a few mappings explicitly if needed (optional)
// Mapster will automatically map same-named properties, but configuration
// ensures any custom rules or future needs can be added here.
TypeAdapterConfig<User, UserResponse>.NewConfig().IgnoreNullValues(true)
    .Map(dest => dest.Role, src => src.UserRoles != null && src.UserRoles.Any() ? src.UserRoles.First().Role.Name : string.Empty);
TypeAdapterConfig<UserUpdateRequest, User>.NewConfig().IgnoreNullValues(true);
// ReviewUpdateRequest fields are all nullable (Rating/Comment for the patient, IsApproved for
// Admin — each side only sends what it's allowed to touch). Without this, Mapster maps an
// omitted (null) field onto the entity's non-nullable property as its default (false/0),
// silently wiping whatever was already there.
TypeAdapterConfig<ReviewUpdateRequest, Review>.NewConfig().IgnoreNullValues(true);
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
// Review has no direct FK to Doctor/Patient/DentalService — these are reached through the
// Appointment navigation, which is itself only populated when .Include(...) was used, so every
// level of the chain needs its own null check.
TypeAdapterConfig<Review, ReviewResponse>.NewConfig()
    .Map(dest => dest.DoctorName, src => src.Appointment != null && src.Appointment.Doctor != null ? src.Appointment.Doctor.FirstName + " " + src.Appointment.Doctor.LastName : string.Empty)
    .Map(dest => dest.DentalServiceName, src => src.Appointment != null && src.Appointment.DentalService != null ? src.Appointment.DentalService.Name : string.Empty)
    .Map(dest => dest.PatientName, src => src.Appointment != null && src.Appointment.Patient != null ? src.Appointment.Patient.FirstName + " " + src.Appointment.Patient.LastName : string.Empty);
TypeAdapterConfig<Notification, NotificationResponse>.NewConfig()
    .Map(dest => dest.UserName, src => src.User != null ? src.User.FirstName + " " + src.User.LastName : string.Empty)
    .Map(dest => dest.ServiceCategoryName, src => src.ServiceCategory != null ? src.ServiceCategory.Name : string.Empty);
TypeAdapterConfig<News, NewsResponse>.NewConfig()
    .Map(dest => dest.CreatedByUserName, src => src.CreatedByUser != null ? src.CreatedByUser.FirstName + " " + src.CreatedByUser.LastName : string.Empty);
TypeAdapterConfig<Payment, PaymentResponse>.NewConfig()
    .Map(dest => dest.PatientName, src => src.Appointment != null && src.Appointment.Patient != null ? src.Appointment.Patient.FirstName + " " + src.Appointment.Patient.LastName : string.Empty)
    .Map(dest => dest.DoctorName, src => src.Appointment != null && src.Appointment.Doctor != null ? src.Appointment.Doctor.FirstName + " " + src.Appointment.Doctor.LastName : string.Empty);

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
builder.Services.AddScoped<IReviewService, ReviewService>();
builder.Services.AddScoped<INotificationService, NotificationService>();

builder.Services.AddScoped<INewsService, NewsService>();
builder.Services.AddScoped<IPaymentService, PaymentService>();
builder.Services.AddScoped<IRecommenderService, RecommenderService>();
builder.Services.AddScoped<IReportService, ReportService>();

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
builder.Services.AddScoped<IValidator<ReviewInsertRequest>, ReviewInsertValidator>();
builder.Services.AddScoped<IValidator<ReviewUpdateRequest>, ReviewUpdateValidator>();
builder.Services.AddScoped<IValidator<NotificationInsertRequest>, NotificationInsertValidator>();
builder.Services.AddScoped<IValidator<NewsInsertRequest>, NewsInsertValidator>();
builder.Services.AddScoped<IValidator<NewsUpdateRequest>, NewsUpdateValidator>();
builder.Services.AddScoped<IValidator<PaymentCreateIntentRequest>, PaymentCreateIntentValidator>();
builder.Services.AddScoped<IValidator<ForgotPasswordRequest>, ForgotPasswordValidator>();
builder.Services.AddScoped<IValidator<ResetPasswordRequest>, ResetPasswordValidator>();
builder.Services.AddScoped<IValidator<UserPasswordChangeRequest>, UserPasswordChangeValidator>();

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

// Applying pending migrations on startup (idempotent — no-op if the DB is already current) so
// `docker-compose up` brings up a working app without the reviewer running `dotnet ef database
// update` by hand from outside the container.
using (var scope = app.Services.CreateScope())
{
    var dbContext = scope.ServiceProvider.GetRequiredService<MyDentDbContext>();
    dbContext.Database.Migrate();

    // EF Core compiles each *distinct query shape* the first time it runs, not just the model
    // once overall — a plain "Take(1)" warms the model but not the specific Include/join shapes
    // Login and the dashboard's two big fetches actually use, so those still paid this cost on
    // whoever hit them first (almost always the very next real Login, then whoever opened
    // Početna). Warming those exact shapes here instead. Failures here must never block startup —
    // worst case, the first real request just pays the cost it would have paid anyway.
    try
    {
        // Same shape as UserService.GetByUsernameAsync (the Login query).
        await dbContext.Users.AsNoTracking()
            .Include(u => u.UserRoles).ThenInclude(ur => ur.Role)
            .FirstOrDefaultAsync(u => u.Username == "__warmup__");

        // Same shape as the desktop dashboard's two "pageSize:2000" fetches.
        await dbContext.Appointments.AsNoTracking()
            .Include(a => a.Patient).Include(a => a.Doctor).Include(a => a.DentalService)
            .Take(1).ToListAsync();
        await dbContext.Payments.AsNoTracking()
            .Include(p => p.Appointment).ThenInclude(a => a.Patient)
            .Include(p => p.Appointment).ThenInclude(a => a.Doctor)
            .Take(1).ToListAsync();
    }
    catch
    {
        // Ignored — see comment above.
    }
}

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.MapScalarApiReference();

    app.UseSwagger();
    app.UseSwaggerUI();
}

// Deliberately no UseHttpsRedirection() — the API runs plain HTTP (see docker-compose.yml),
// which avoids self-signed cert expiry issues for local/grading runs; both Flutter clients
// point at http:// directly.

app.UseCors("MyDentCors");

app.UseAuthentication();

app.UseAuthorization();

app.MapControllers();

app.Run();
