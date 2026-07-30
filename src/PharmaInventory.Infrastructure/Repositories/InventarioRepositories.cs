using System.Data;
using Dapper;
using PharmaInventory.Application.Abstractions;
using PharmaInventory.Application.Common;
using PharmaInventory.Application.Dtos;
using PharmaInventory.Domain.Entities;
using PharmaInventory.Domain.Enums;
using PharmaInventory.Infrastructure.Persistence;

namespace PharmaInventory.Infrastructure.Repositories;

public sealed class InventarioRepository(IDbConnectionFactory factory) : RepositoryBase(factory), IInventarioRepository
{
    public Task<PagedResult<StockActualDto>> ListarStockAsync(PaginacionQuery query, bool soloBajoMinimo = false, CancellationToken ct = default) => RunAsync(async conn =>
    {
        using var multi = await conn.QueryMultipleAsync(new CommandDefinition("sp_Inventario_StockActual_Listar",
            new { pagina = query.Pagina, tamano = query.Tamano, busqueda = query.Busqueda, solo_bajo_minimo = soloBajoMinimo },
            commandType: CommandType.StoredProcedure, cancellationToken: ct));
        var items = (await multi.ReadAsync<StockActualDto>()).ToList();
        var total = await multi.ReadSingleAsync<int>();
        return new PagedResult<StockActualDto> { Items = items, Total = total, Pagina = query.Pagina, Tamano = query.Tamano };
    });

    public Task<IReadOnlyList<ProductoPorVencerDto>> ListarPorVencerAsync(int dias = 30, CancellationToken ct = default) => RunAsync(async conn =>
    {
        var rows = await conn.QueryAsync<ProductoPorVencerDto>(new CommandDefinition(
            "sp_Inventario_ProductosPorVencer", new { dias }, commandType: CommandType.StoredProcedure, cancellationToken: ct));
        return (IReadOnlyList<ProductoPorVencerDto>)rows.ToList();
    });

    public Task<PagedResult<MovimientoKardex>> ListarKardexPorProductoAsync(int idProducto, PaginacionQuery query, CancellationToken ct = default) => RunAsync(async conn =>
    {
        using var multi = await conn.QueryMultipleAsync(new CommandDefinition("sp_Kardex_ListarPorProducto",
            new { id_producto = idProducto, pagina = query.Pagina, tamano = query.Tamano },
            commandType: CommandType.StoredProcedure, cancellationToken: ct));
        var items = (await multi.ReadAsync<MovimientoKardex>()).ToList();
        var total = await multi.ReadSingleAsync<int>();
        return new PagedResult<MovimientoKardex> { Items = items, Total = total, Pagina = query.Pagina, Tamano = query.Tamano };
    });

    public Task<int> AjusteManualAsync(AjusteManualRequest request, int idUsuario, CancellationToken ct = default) => RunAsync(async conn =>
    {
        var p = new DynamicParameters();
        p.Add("@id_producto", request.IdProducto);
        p.Add("@id_lote", request.IdLote);
        p.Add("@cantidad", request.Cantidad);
        p.Add("@motivo", request.Motivo);
        p.Add("@id_usuario", idUsuario);
        p.Add("@id_movimiento_creado", dbType: DbType.Int32, direction: ParameterDirection.Output);
        await conn.ExecuteAsync(new CommandDefinition("sp_Inventario_AjusteManual", p, commandType: CommandType.StoredProcedure, cancellationToken: ct));
        return p.Get<int>("@id_movimiento_creado");
    });

    public Task<IReadOnlyList<LoteDisponibleDto>> ListarLotesPorProductoAsync(int idProducto, CancellationToken ct = default) => RunAsync(async conn =>
    {
        var rows = await conn.QueryAsync<LoteDisponibleDto>(new CommandDefinition("sp_Lote_ListarPorProducto",
            new { id_producto = idProducto }, commandType: CommandType.StoredProcedure, cancellationToken: ct));
        return (IReadOnlyList<LoteDisponibleDto>)rows.ToList();
    });
}

public sealed class AlertaRepository(IDbConnectionFactory factory) : RepositoryBase(factory), IAlertaRepository
{
    public Task<PagedResult<AlertaStock>> ListarAsync(PaginacionQuery query, TipoAlerta? tipo = null, CancellationToken ct = default) => RunAsync(async conn =>
    {
        using var multi = await conn.QueryMultipleAsync(new CommandDefinition("sp_Alerta_Listar",
            new { pagina = query.Pagina, tamano = query.Tamano, tipo_alerta = EnumSnakeCase.ToSnakeOrNull(tipo) },
            commandType: CommandType.StoredProcedure, cancellationToken: ct));
        var items = (await multi.ReadAsync<AlertaStock>()).ToList();
        var total = await multi.ReadSingleAsync<int>();
        return new PagedResult<AlertaStock> { Items = items, Total = total, Pagina = query.Pagina, Tamano = query.Tamano };
    });

    public Task ResolverAsync(int idAlerta, int idUsuarioResolucion, CancellationToken ct = default) => RunAsync(conn =>
        conn.ExecuteAsync(new CommandDefinition("sp_Alerta_Resolver",
            new { id_alerta = idAlerta, id_usuario_resolucion = idUsuarioResolucion }, commandType: CommandType.StoredProcedure, cancellationToken: ct)));

    public Task GenerarPorStockMinimoAsync(CancellationToken ct = default) => RunAsync(conn =>
        conn.ExecuteAsync(new CommandDefinition("sp_Alerta_GenerarPorStockMinimo", commandType: CommandType.StoredProcedure, cancellationToken: ct)));

    public Task GenerarPorVencimientoAsync(int diasAnticipacion = 30, CancellationToken ct = default) => RunAsync(conn =>
        conn.ExecuteAsync(new CommandDefinition("sp_Alerta_GenerarPorVencimiento", new { dias_anticipacion = diasAnticipacion }, commandType: CommandType.StoredProcedure, cancellationToken: ct)));
}
