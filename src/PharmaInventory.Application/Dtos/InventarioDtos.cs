namespace PharmaInventory.Application.Dtos;

// StockActualDto/ProductoPorVencerDto/FichaMedicamentoDto (en ProductoDtos.cs)
// son "forma larga" (propiedades init, no record posicional) A PROPOSITO:
// Dapper materializa filas de QueryAsync<T>/GridReader via constructor
// matching por NOMBRE, y ese matching NO aplica el MatchNamesWithUnderscores
// de DapperBootstrap -- con un record posicional (constructor generado) tira
// "no parameterless constructor" en runtime. La forma larga genera un
// constructor vacio implicito y Dapper cae al binding por propiedades, que
// si respeta MatchNamesWithUnderscores. Los DTOs de REQUEST (ej.
// AjusteManualRequest) no tienen este problema: los bindea System.Text.Json,
// no Dapper, y esos si pueden quedarse posicionales.

/// <summary>Una fila de vw_StockActual.</summary>
public sealed record StockActualDto
{
    public int IdProducto { get; init; }
    public string Nombre { get; init; } = string.Empty;
    public string? CodigoSku { get; init; }
    public int StockActual { get; init; }
    public int StockMinimo { get; init; }
    public decimal PrecioPromedioPond { get; init; }
    public bool BajoStockMinimo { get; init; }
}

/// <summary>Una fila de vw_ProductosPorVencer (ya filtrada por sp_Inventario_ProductosPorVencer @dias).</summary>
public sealed record ProductoPorVencerDto
{
    public int IdLote { get; init; }
    public string NumeroLote { get; init; } = string.Empty;
    public DateTime FechaVencimiento { get; init; }
    public int CantidadActual { get; init; }
    public int IdProducto { get; init; }
    public string Nombre { get; init; } = string.Empty;
    public string? CodigoSku { get; init; }
    public int DiasParaVencer { get; init; }
}

/// <summary>
/// POST /api/inventario/ajustes. IdUsuario NO viaja aqui -- lo resuelve el
/// controller desde el claim del JWT, nunca lo elige el cliente.
/// </summary>
public sealed record AjusteManualRequest(int IdProducto, int? IdLote, int Cantidad, string Motivo);

/// <summary>Una fila de sp_Lote_ListarPorProducto -- lotes activos con stock, para el selector de lote del ajuste manual.</summary>
public sealed record LoteDisponibleDto
{
    public int IdLote { get; init; }
    public string NumeroLote { get; init; } = string.Empty;
    public DateTime FechaVencimiento { get; init; }
    public int CantidadActual { get; init; }
}
