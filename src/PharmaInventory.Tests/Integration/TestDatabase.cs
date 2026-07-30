using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using Xunit;

namespace PharmaInventory.Tests.Integration;

/// <summary>
/// Los tests de integracion pegan contra el SQL Server real (no hay
/// contenedor/testcontainers en este entorno) -- misma conexion que usa la
/// Api via user-secrets/env vars. Si no hay conectividad (CI sin la BD
/// configurada, red caida, etc), los tests se SKIPEAN en vez de fallar.
/// </summary>
public static class TestDatabase
{
    private static bool? _isReachable;

    public static IConfiguration Configuration { get; } = new ConfigurationBuilder()
        .AddUserSecrets(typeof(Program).Assembly)
        .AddEnvironmentVariables()
        .Build();

    public static bool IsReachable()
    {
        if (_isReachable.HasValue) return _isReachable.Value;

        var connectionString = Configuration.GetConnectionString("PharmaDb");
        if (string.IsNullOrWhiteSpace(connectionString))
        {
            _isReachable = false;
            return false;
        }

        try
        {
            using var connection = new SqlConnection(connectionString);
            connection.Open();
            _isReachable = true;
        }
        catch
        {
            _isReachable = false;
        }

        return _isReachable.Value;
    }
}

/// <summary>
/// [RequiresDatabaseFact] en vez de [Fact] -- reporta "Skipped" (no
/// "Failed") cuando TestDatabase.IsReachable() es false, usando el soporte
/// nativo de xunit para Skip (sin depender de un paquete extra).
/// </summary>
public sealed class RequiresDatabaseFactAttribute : FactAttribute
{
    public RequiresDatabaseFactAttribute()
    {
        if (!TestDatabase.IsReachable())
            Skip = "No hay conexion a PharmaInventory (ConnectionStrings:PharmaDb via user-secrets o env var).";
    }
}
