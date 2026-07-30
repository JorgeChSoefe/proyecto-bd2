using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using FluentValidation;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.IdentityModel.Tokens;
using PharmaInventory.Api.Auth;
using PharmaInventory.Api.Middleware;
using PharmaInventory.Api.Services;
using PharmaInventory.Application.Validators;
using PharmaInventory.Infrastructure;
using Scalar.AspNetCore;

var builder = WebApplication.CreateBuilder(args);

// ---- Configuracion ----
builder.Services.Configure<JwtOptions>(builder.Configuration.GetSection(JwtOptions.SectionName));
var jwtOptions = builder.Configuration.GetSection(JwtOptions.SectionName).Get<JwtOptions>()
    ?? throw new InvalidOperationException("Falta la seccion 'Jwt' en la configuracion.");
if (string.IsNullOrWhiteSpace(jwtOptions.SigningKey))
    throw new InvalidOperationException(
        "Falta Jwt:SigningKey. Configuralo con 'dotnet user-secrets set Jwt:SigningKey <valor>' " +
        "(desarrollo) o la variable de entorno Jwt__SigningKey (el resto de entornos).");

// ---- Capas de la aplicacion ----
builder.Services.AddInfrastructure();
builder.Services.AddValidatorsFromAssemblyContaining<LoginRequestValidator>();
builder.Services.AddSingleton<IJwtTokenService, JwtTokenService>();

// ---- Autenticacion / Autorizacion ----
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = jwtOptions.Issuer,
            ValidAudience = jwtOptions.Audience,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtOptions.SigningKey)),
            ClockSkew = TimeSpan.FromMinutes(1),
        };
    });

builder.Services.AddAuthorization();
builder.Services.AddSingleton<IAuthorizationPolicyProvider, PermisoPolicyProvider>();
builder.Services.AddSingleton<IAuthorizationHandler, PermisoAuthorizationHandler>();

// ---- Job de alertas (CLAUDE.md 5.5) ----
builder.Services.AddHostedService<AlertasBackgroundService>();

// ---- Mvc / OpenApi ----
// Sin esto, System.Text.Json serializa los enums de Domain (EstadoVenta,
// TipoMovimientoKardex, ViaAdministracion, TipoAlerta) como su valor
// numerico ordinal (0,1,2...) -- fragil e ilegible en el JSON. SnakeCaseLower
// los deja como 'completada'/'entrada'/'oral'/'vencimiento_proximo', igual
// vocabulario que usa la BD (StringEnumTypeHandler en Infrastructure hace la
// conversion analoga del lado de Dapper, esto es la analoga del lado HTTP).
builder.Services.AddControllers(options => options.Filters.Add<PharmaInventory.Api.Middleware.ValidationFilter>())
    .AddJsonOptions(options =>
        options.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter(JsonNamingPolicy.SnakeCaseLower)));
builder.Services.AddOpenApi();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.MapScalarApiReference();
}

app.UseMiddleware<ExceptionHandlingMiddleware>();

app.UseHttpsRedirection();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();

// Para WebApplicationFactory<Program> en los tests de integracion.
public partial class Program;
