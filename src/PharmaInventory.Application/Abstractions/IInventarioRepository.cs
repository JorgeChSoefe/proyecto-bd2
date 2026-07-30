using PharmaInventory.Application.Common;
using PharmaInventory.Application.Dtos;
using PharmaInventory.Domain.Entities;
using PharmaInventory.Domain.Enums;

namespace PharmaInventory.Application.Abstractions;

public interface IInventarioRepository
{
    Task<PagedResult<StockActualDto>> ListarStockAsync(PaginacionQuery query, bool soloBajoMinimo = false, CancellationToken ct = default);
    Task<IReadOnlyList<ProductoPorVencerDto>> ListarPorVencerAsync(int dias = 30, CancellationToken ct = default);
    Task<PagedResult<MovimientoKardex>> ListarKardexPorProductoAsync(int idProducto, PaginacionQuery query, CancellationToken ct = default);

    /// <summary>sp_Inventario_AjusteManual. Retorna el id_movimiento de kardex creado.</summary>
    Task<int> AjusteManualAsync(AjusteManualRequest request, int idUsuario, CancellationToken ct = default);

    /// <summary>sp_Lote_ListarPorProducto: lotes activos con stock, para el selector de lote del ajuste manual.</summary>
    Task<IReadOnlyList<LoteDisponibleDto>> ListarLotesPorProductoAsync(int idProducto, CancellationToken ct = default);
}

public interface IAlertaRepository
{
    Task<PagedResult<AlertaStock>> ListarAsync(PaginacionQuery query, TipoAlerta? tipo = null, CancellationToken ct = default);
    Task ResolverAsync(int idAlerta, int idUsuarioResolucion, CancellationToken ct = default);

    /// <summary>Invocados por AlertasBackgroundService (ver CLAUDE.md 5.5) -- no expuestos como endpoint.</summary>
    Task GenerarPorStockMinimoAsync(CancellationToken ct = default);
    Task GenerarPorVencimientoAsync(int diasAnticipacion = 30, CancellationToken ct = default);
}
