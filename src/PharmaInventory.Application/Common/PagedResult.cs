namespace PharmaInventory.Application.Common;

/// <summary>
/// Envoltorio de paginacion para los SPs `_Listar` (patron unico: primer
/// resultset = filas de la pagina, segundo resultset = @total). Ver B9 en
/// CLAUDE.md / los .sql -- todo listado paginado sigue esta forma.
/// </summary>
public sealed class PagedResult<T>
{
    public required IReadOnlyList<T> Items { get; init; }
    public required int Total { get; init; }
    public required int Pagina { get; init; }
    public required int Tamano { get; init; }
}

/// <summary>Parametros comunes de paginacion/busqueda para los endpoints GET de listado.</summary>
public sealed class PaginacionQuery
{
    private int _pagina = 1;
    private int _tamano = 50;

    public int Pagina
    {
        get => _pagina;
        set => _pagina = value < 1 ? 1 : value;
    }

    public int Tamano
    {
        get => _tamano;
        set => _tamano = value switch { < 1 => 50, > 200 => 200, _ => value };
    }

    public string? Busqueda { get; set; }
}
