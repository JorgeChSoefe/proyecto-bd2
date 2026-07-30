using System.Data;
using System.Text;
using Dapper;

namespace PharmaInventory.Infrastructure.Persistence;

/// <summary>
/// Conversion PascalCase &lt;-&gt; snake_case compartida por StringEnumTypeHandler
/// (lectura, materializando filas) y por los repositorios que necesitan pasar un
/// enum de Domain como PARAMETRO de un SP (escritura) -- ver el comentario en
/// StringEnumTypeHandler sobre por que la escritura no puede depender del
/// TypeHandler registrado.
/// </summary>
public static class EnumSnakeCase
{
    public static string ToSnake<TEnum>(TEnum value) where TEnum : struct, Enum => ToSnakeCase(value.ToString());

    /// <summary>Para parametros opcionales de filtro (ej. `EstadoVenta? estado`) -- null pasa como NULL de SQL.</summary>
    public static string? ToSnakeOrNull<TEnum>(TEnum? value) where TEnum : struct, Enum => value.HasValue ? ToSnake(value.Value) : null;

    public static string ToPascal(string snakeCase)
    {
        var parts = snakeCase.Split('_', StringSplitOptions.RemoveEmptyEntries);
        var sb = new StringBuilder(snakeCase.Length);
        foreach (var part in parts)
            sb.Append(char.ToUpperInvariant(part[0])).Append(part[1..]);
        return sb.ToString();
    }

    private static string ToSnakeCase(string pascalCase)
    {
        var sb = new StringBuilder(pascalCase.Length + 4);
        for (var i = 0; i < pascalCase.Length; i++)
        {
            var c = pascalCase[i];
            if (char.IsUpper(c))
            {
                if (i > 0) sb.Append('_');
                sb.Append(char.ToLowerInvariant(c));
            }
            else
            {
                sb.Append(c);
            }
        }
        return sb.ToString();
    }
}

/// <summary>
/// Convierte un enum de Domain (PascalCase, ej. VencimientoProximo) hacia/desde
/// el string snake_case que realmente vive en la columna (ej.
/// 'vencimiento_proximo'), que es el formato que usan los CHECK constraints
/// del esquema. Un solo handler generico sirve para los 5 enums de Domain
/// (EstadoVenta, EstadoCompra, TipoMovimientoKardex, ViaAdministracion,
/// TipoAlerta) -- se registra una vez por tipo en DependencyInjection.cs.
///
/// OJO -- esto SOLO cubre la lectura (Dapper materializando una fila hacia un
/// POCO tipado, QueryAsync&lt;T&gt;). Para escritura, Dapper reasigna el tipo del
/// parametro a su subyacente (Enum.GetUnderlyingType, o sea int) ANTES de
/// buscar en su tabla de TypeHandlers -- este handler nunca se dispara para un
/// enum plano pasado en un objeto anonimo/DynamicParameters, y el int crudo
/// termina violando el CHECK constraint de la columna (viola_administracion,
/// estado, etc.). Cualquier parametro de ESCRITURA con uno de estos 5 enums
/// debe convertirse a mano con EnumSnakeCase.ToSnake/ToSnakeOrNull antes de
/// pasarlo a Dapper -- ver ProductoRepository/VentaRepository/CompraRepository/
/// InventarioRepositories para los casos ya corregidos.
/// </summary>
public sealed class StringEnumTypeHandler<TEnum> : SqlMapper.TypeHandler<TEnum>
    where TEnum : struct, Enum
{
    public override void SetValue(IDbDataParameter parameter, TEnum value)
    {
        parameter.DbType = DbType.String;
        parameter.Value = EnumSnakeCase.ToSnake(value);
    }

    public override TEnum Parse(object value) => Enum.Parse<TEnum>(EnumSnakeCase.ToPascal((string)value), ignoreCase: true);
}
