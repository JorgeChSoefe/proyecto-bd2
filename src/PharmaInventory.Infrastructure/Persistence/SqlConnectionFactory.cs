using System.Data;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;

namespace PharmaInventory.Infrastructure.Persistence;

public sealed class SqlConnectionFactory : IDbConnectionFactory
{
    private readonly string _connectionString;

    public SqlConnectionFactory(IConfiguration configuration)
    {
        _connectionString = configuration.GetConnectionString("PharmaDb")
            ?? throw new InvalidOperationException(
                "Falta la cadena de conexion 'PharmaDb'. Configurala con " +
                "dotnet user-secrets (desarrollo) o la variable de entorno " +
                "ConnectionStrings__PharmaDb (el resto de entornos).");
    }

    public IDbConnection Create() => new SqlConnection(_connectionString);
}
