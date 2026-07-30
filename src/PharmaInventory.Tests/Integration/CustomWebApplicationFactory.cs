using System.Runtime.CompilerServices;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;

namespace PharmaInventory.Tests.Integration;

/// <summary>
/// Levanta la Api completa en memoria (TestServer) contra la BD real -- no
/// hay mocks de Infrastructure, es el mismo Program.cs / DI / SPs que
/// producirian. Necesita entorno "Development" para que
/// WebApplication.CreateBuilder cargue user-secrets (ahi vive
/// ConnectionStrings:PharmaDb y Jwt:SigningKey en este equipo) -- se fija la
/// variable de entorno del proceso ANTES de que exista cualquier factory,
/// porque CreateBuilder(args) la lee directo del entorno del proceso al
/// momento de correr Program.cs, antes de que ConfigureWebHost pueda tocar
/// nada.
/// </summary>
public sealed class CustomWebApplicationFactory : WebApplicationFactory<Program>
{
    [ModuleInitializer]
    internal static void FijarEntornoDeDesarrollo()
    {
        if (string.IsNullOrEmpty(Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT")))
            Environment.SetEnvironmentVariable("ASPNETCORE_ENVIRONMENT", "Development");
    }

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Development");
    }
}
