using System.Data;
using Microsoft.Data.SqlClient;

namespace PharmaInventory.Infrastructure.Persistence;

/// <summary>
/// Base de todos los repos: abre/cierra la conexion y traduce errores de
/// negocio (SqlException.Number &gt;= 50000, ver SqlErrorMapper) a excepciones
/// tipadas de Domain. Los repos concretos nunca instancian SqlConnection ni
/// atrapan SqlException directamente -- siempre pasan por Run/RunAsync.
/// </summary>
public abstract class RepositoryBase(IDbConnectionFactory connectionFactory)
{
    protected async Task<T> RunAsync<T>(Func<IDbConnection, Task<T>> operation)
    {
        using var connection = connectionFactory.Create();
        try
        {
            return await operation(connection);
        }
        catch (SqlException ex) when (ex.Number >= 50000)
        {
            throw SqlErrorMapper.Map(ex);
        }
    }

    protected async Task RunAsync(Func<IDbConnection, Task> operation)
    {
        using var connection = connectionFactory.Create();
        try
        {
            await operation(connection);
        }
        catch (SqlException ex) when (ex.Number >= 50000)
        {
            throw SqlErrorMapper.Map(ex);
        }
    }
}
