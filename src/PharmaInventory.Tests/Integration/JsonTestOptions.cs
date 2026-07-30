using System.Text.Json;
using System.Text.Json.Serialization;

namespace PharmaInventory.Tests.Integration;

/// <summary>
/// La Api serializa en camelCase (default de ASP.NET Core); nuestros DTOs
/// estan en PascalCase. System.Net.Http.Json usa JsonSerializerOptions.Default
/// si no se le pasa nada, que es case-SENSITIVE -- sin esto, deserializar la
/// respuesta HTTP a los mismos DTOs de Application deja todo en su valor por
/// defecto (0/null) sin ningun error visible. Tambien espeja el
/// JsonStringEnumConverter(SnakeCaseLower) configurado en Program.cs -- sin
/// el mismo converter aca, deserializar un campo enum (ej. Venta.Estado)
/// desde el string 'completada' que ahora manda el servidor tira una
/// JsonException (el default de System.Text.Json solo acepta numeros).
/// </summary>
internal static class JsonTestOptions
{
    public static readonly JsonSerializerOptions CaseInsensitive = new()
    {
        PropertyNameCaseInsensitive = true,
        Converters = { new JsonStringEnumConverter(JsonNamingPolicy.SnakeCaseLower) },
    };
}
