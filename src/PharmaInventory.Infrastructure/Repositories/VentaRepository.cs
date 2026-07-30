using System.Data;
using Dapper;
using PharmaInventory.Application.Abstractions;
using PharmaInventory.Application.Common;
using PharmaInventory.Application.Dtos;
using PharmaInventory.Domain.Entities;
using PharmaInventory.Domain.Enums;
using PharmaInventory.Infrastructure.Persistence;

namespace PharmaInventory.Infrastructure.Repositories;

public sealed class VentaRepository(IDbConnectionFactory factory) : RepositoryBase(factory), IVentaRepository
{
    public Task<int> RegistrarAsync(VentaRequest request, int idUsuario, CancellationToken ct = default) => RunAsync(async conn =>
    {
        var p = new DynamicParameters();
        p.Add("@id_empleado", request.IdEmpleado);
        p.Add("@id_cliente", request.IdCliente);
        p.Add("@id_usuario", idUsuario);
        p.Add("@id_receta", request.IdReceta);
        p.Add("@detalle", TvpBuilder.DetalleVenta(request.Detalle));
        p.Add("@id_venta_creada", dbType: DbType.Int32, direction: ParameterDirection.Output);
        await conn.ExecuteAsync(new CommandDefinition("sp_Venta_Registrar", p, commandType: CommandType.StoredProcedure, cancellationToken: ct, commandTimeout: 60));
        return p.Get<int>("@id_venta_creada");
    });

    public Task AnularAsync(int idVenta, int idUsuario, CancellationToken ct = default) => RunAsync(conn =>
        conn.ExecuteAsync(new CommandDefinition("sp_Venta_Anular",
            new { id_venta = idVenta, id_usuario = idUsuario }, commandType: CommandType.StoredProcedure, cancellationToken: ct, commandTimeout: 60)));

    public Task<VentaDetalleDto?> ObtenerPorIdAsync(int id, CancellationToken ct = default) => RunAsync(async conn =>
    {
        using var multi = await conn.QueryMultipleAsync(new CommandDefinition("sp_Venta_ObtenerPorId",
            new { id_venta = id }, commandType: CommandType.StoredProcedure, cancellationToken: ct));

        var venta = await multi.ReadSingleOrDefaultAsync<Venta>();
        if (venta is null) return null;

        var lineas = (await multi.ReadAsync<DetalleVenta>()).ToList();
        return new VentaDetalleDto(venta, lineas);
    });

    public Task<PagedResult<Venta>> ListarAsync(
        PaginacionQuery query, EstadoVenta? estado = null,
        DateOnly? fechaDesde = null, DateOnly? fechaHasta = null, CancellationToken ct = default) => RunAsync(async conn =>
    {
        using var multi = await conn.QueryMultipleAsync(new CommandDefinition("sp_Venta_Listar",
            new
            {
                pagina = query.Pagina, tamano = query.Tamano, estado = EnumSnakeCase.ToSnakeOrNull(estado),
                fecha_desde = fechaDesde?.ToDateTime(TimeOnly.MinValue),
                fecha_hasta = fechaHasta?.ToDateTime(TimeOnly.MinValue),
            },
            commandType: CommandType.StoredProcedure, cancellationToken: ct));
        var items = (await multi.ReadAsync<Venta>()).ToList();
        var total = await multi.ReadSingleAsync<int>();
        return new PagedResult<Venta> { Items = items, Total = total, Pagina = query.Pagina, Tamano = query.Tamano };
    });
}
