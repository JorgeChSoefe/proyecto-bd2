using System.Data;
using Dapper;
using PharmaInventory.Application.Abstractions;
using PharmaInventory.Application.Common;
using PharmaInventory.Application.Dtos;
using PharmaInventory.Domain.Entities;
using PharmaInventory.Infrastructure.Persistence;

namespace PharmaInventory.Infrastructure.Repositories;

public sealed class ClienteRepository(IDbConnectionFactory factory) : RepositoryBase(factory), IClienteRepository
{
    public Task<int> InsertarAsync(ClienteRequest request, CancellationToken ct = default) => RunAsync(async conn =>
    {
        var p = new DynamicParameters();
        p.Add("@nombre_completo", request.NombreCompleto);
        p.Add("@identificacion", request.Identificacion);
        p.Add("@telefono", request.Telefono);
        p.Add("@fecha_nacimiento", request.FechaNacimiento);
        p.Add("@email", request.Email);
        p.Add("@id_creado", dbType: DbType.Int32, direction: ParameterDirection.Output);
        await conn.ExecuteAsync(new CommandDefinition("sp_Cliente_Insertar", p, commandType: CommandType.StoredProcedure, cancellationToken: ct));
        return p.Get<int>("@id_creado");
    });

    public Task ActualizarAsync(int id, ClienteRequest request, CancellationToken ct = default) => RunAsync(conn =>
        conn.ExecuteAsync(new CommandDefinition("sp_Cliente_Actualizar",
            new
            {
                id_cliente = id, nombre_completo = request.NombreCompleto, telefono = request.Telefono,
                fecha_nacimiento = request.FechaNacimiento, email = request.Email,
            },
            commandType: CommandType.StoredProcedure, cancellationToken: ct)));

    public Task EliminarAsync(int id, CancellationToken ct = default) => RunAsync(conn =>
        conn.ExecuteAsync(new CommandDefinition("sp_Cliente_Eliminar", new { id_cliente = id }, commandType: CommandType.StoredProcedure, cancellationToken: ct)));

    public Task<Cliente?> ObtenerPorIdAsync(int id, CancellationToken ct = default) => RunAsync(conn =>
        conn.QuerySingleOrDefaultAsync<Cliente>(new CommandDefinition("sp_Cliente_ObtenerPorId", new { id_cliente = id }, commandType: CommandType.StoredProcedure, cancellationToken: ct)));

    public Task<PagedResult<Cliente>> ListarAsync(PaginacionQuery query, CancellationToken ct = default) => RunAsync(async conn =>
    {
        using var multi = await conn.QueryMultipleAsync(new CommandDefinition("sp_Cliente_Listar",
            new { pagina = query.Pagina, tamano = query.Tamano, busqueda = query.Busqueda }, commandType: CommandType.StoredProcedure, cancellationToken: ct));
        var items = (await multi.ReadAsync<Cliente>()).ToList();
        var total = await multi.ReadSingleAsync<int>();
        return new PagedResult<Cliente> { Items = items, Total = total, Pagina = query.Pagina, Tamano = query.Tamano };
    });
}

public sealed class RecetaRepository(IDbConnectionFactory factory) : RepositoryBase(factory), IRecetaRepository
{
    public Task<int> RegistrarAsync(RecetaRequest request, CancellationToken ct = default) => RunAsync(async conn =>
    {
        var p = new DynamicParameters();
        p.Add("@numero_receta", request.NumeroReceta);
        p.Add("@id_cliente", request.IdCliente);
        p.Add("@nombre_medico", request.NombreMedico);
        p.Add("@num_colegio_medico", request.NumColegioMedico);
        p.Add("@fecha_emision", request.FechaEmision);
        p.Add("@fecha_vencimiento", request.FechaVencimiento);
        p.Add("@notas", request.Notas);
        p.Add("@detalle", TvpBuilder.DetalleReceta(request.Detalle));
        p.Add("@id_receta_creada", dbType: DbType.Int32, direction: ParameterDirection.Output);
        await conn.ExecuteAsync(new CommandDefinition("sp_Receta_Registrar", p, commandType: CommandType.StoredProcedure, cancellationToken: ct));
        return p.Get<int>("@id_receta_creada");
    });

    public Task<RecetaDetalleDto?> ObtenerPorIdAsync(int id, CancellationToken ct = default) => RunAsync(async conn =>
    {
        using var multi = await conn.QueryMultipleAsync(new CommandDefinition("sp_Receta_ObtenerPorId",
            new { id_receta = id }, commandType: CommandType.StoredProcedure, cancellationToken: ct));

        var receta = await multi.ReadSingleOrDefaultAsync<Receta>();
        if (receta is null) return null;

        var lineas = (await multi.ReadAsync<DetalleReceta>()).ToList();
        return new RecetaDetalleDto(receta, lineas);
    });

    public Task<PagedResult<Receta>> ListarPendientesAsync(PaginacionQuery query, int? idCliente = null, CancellationToken ct = default) => RunAsync(async conn =>
    {
        using var multi = await conn.QueryMultipleAsync(new CommandDefinition("sp_Receta_ListarPendientes",
            new { pagina = query.Pagina, tamano = query.Tamano, id_cliente = idCliente }, commandType: CommandType.StoredProcedure, cancellationToken: ct));
        var items = (await multi.ReadAsync<Receta>()).ToList();
        var total = await multi.ReadSingleAsync<int>();
        return new PagedResult<Receta> { Items = items, Total = total, Pagina = query.Pagina, Tamano = query.Tamano };
    });
}
