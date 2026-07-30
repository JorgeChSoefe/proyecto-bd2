using System.Data;

namespace PharmaInventory.Infrastructure.Persistence;

/// <summary>
/// Unica puerta de entrada a la cadena de conexion. Los repos nunca
/// construyen un SqlConnection directamente -- todos pasan por aqui, para
/// que la configuracion (Encrypt, TrustServerCertificate, etc) viva en un
/// solo lugar.
/// </summary>
public interface IDbConnectionFactory
{
    IDbConnection Create();
}
