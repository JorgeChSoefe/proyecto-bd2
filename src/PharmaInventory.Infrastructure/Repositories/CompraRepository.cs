using System.Data;
using Dapper;
using PharmaInventory.Application.Abstractions;
using PharmaInventory.Application.Common;
using PharmaInventory.Application.Dtos;
using PharmaInventory.Domain.Entities;
using PharmaInventory.Domain.Enums;
using PharmaInventory.Infrastructure.Persistence;

namespace PharmaInventory.Infrastructure.Repositories;

public sealed class CompraRepository(IDbConnectionFactory factory) : RepositoryBase(factory), ICompraRepository
{
    public Task<int> RegistrarAsync(CompraRequest request, int idUsuario, CancellationToken ct = default) => RunAsync(async conn =>
    {
        var p = new DynamicParameters();
        p.Add("@id_proveedor", request.IdProveedor);
        p.Add("@id_empleado", request.IdEmpleado);
        p.Add("@id_usuario", idUsuario);
        p.Add("@detalle", TvpBuilder.DetalleCompraRegistro(request.Detalle));
        p.Add("@id_compra_creada", dbType: DbType.Int32, direction: ParameterDirection.Output);
        await conn.ExecuteAsync(new CommandDefinition("sp_Compra_Registrar", p, commandType: CommandType.StoredProcedure, cancellationToken: ct));
        return p.Get<int>("@id_compra_creada");
    });

    public Task RecibirAsync(int idCompra, CompraRecibirRequest request, int idUsuario, CancellationToken ct = default) => RunAsync(conn =>
        conn.ExecuteAsync(new CommandDefinition("sp_Compra_Recibir",
            new { id_compra = idCompra, id_usuario = idUsuario, detalle = TvpBuilder.DetalleCompraRecepcion(request.Detalle) },
            commandType: CommandType.StoredProcedure, cancellationToken: ct, commandTimeout: 60)));

    public Task AnularAsync(int idCompra, CancellationToken ct = default) => RunAsync(conn =>
        conn.ExecuteAsync(new CommandDefinition("sp_Compra_Anular", new { id_compra = idCompra }, commandType: CommandType.StoredProcedure, cancellationToken: ct)));

    public Task<CompraDetalleDto?> ObtenerPorIdAsync(int id, CancellationToken ct = default) => RunAsync(async conn =>
    {
        using var multi = await conn.QueryMultipleAsync(new CommandDefinition("sp_Compra_ObtenerPorId",
            new { id_compra = id }, commandType: CommandType.StoredProcedure, cancellationToken: ct));

        var compra = await multi.ReadSingleOrDefaultAsync<Compra>();
        if (compra is null) return null;

        var lineas = (await multi.ReadAsync<DetalleCompra>()).ToList();
        return new CompraDetalleDto(compra, lineas);
    });

    public Task<PagedResult<Compra>> ListarAsync(
        PaginacionQuery query, EstadoCompra? estado = null,
        DateOnly? fechaDesde = null, DateOnly? fechaHasta = null, CancellationToken ct = default) => RunAsync(async conn =>
    {
        using var multi = await conn.QueryMultipleAsync(new CommandDefinition("sp_Compra_Listar",
            new
            {
                pagina = query.Pagina, tamano = query.Tamano, estado = EnumSnakeCase.ToSnakeOrNull(estado),
                fecha_desde = fechaDesde?.ToDateTime(TimeOnly.MinValue),
                fecha_hasta = fechaHasta?.ToDateTime(TimeOnly.MinValue),
            },
            commandType: CommandType.StoredProcedure, cancellationToken: ct));
        var items = (await multi.ReadAsync<Compra>()).ToList();
        var total = await multi.ReadSingleAsync<int>();
        return new PagedResult<Compra> { Items = items, Total = total, Pagina = query.Pagina, Tamano = query.Tamano };
    });
}
