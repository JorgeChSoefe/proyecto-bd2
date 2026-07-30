using System.Data;
using Dapper;
using PharmaInventory.Application.Abstractions;
using PharmaInventory.Application.Common;
using PharmaInventory.Application.Dtos;
using PharmaInventory.Domain.Entities;
using PharmaInventory.Infrastructure.Persistence;

namespace PharmaInventory.Infrastructure.Repositories;

// Los 5 catalogos base (categorias, proveedores, laboratorios,
// principios_activos, presentaciones) son CRUD identico contra su propio
// SP/vista (ver 03_Catalogos.sql) -- cada repo es un wrapper delgado 1:1,
// sin logica propia. CommandType.StoredProcedure siempre; nunca SQL ad-hoc.

public sealed class CategoriaRepository(IDbConnectionFactory factory) : RepositoryBase(factory), ICategoriaRepository
{
    public Task<int> InsertarAsync(CategoriaRequest request, CancellationToken ct = default) => RunAsync(async conn =>
    {
        var p = new DynamicParameters();
        p.Add("@nombre_categoria", request.NombreCategoria);
        p.Add("@descripcion", request.Descripcion);
        p.Add("@id_creado", dbType: DbType.Int32, direction: ParameterDirection.Output);
        await conn.ExecuteAsync(new CommandDefinition("sp_Categoria_Insertar", p, commandType: CommandType.StoredProcedure, cancellationToken: ct));
        return p.Get<int>("@id_creado");
    });

    public Task ActualizarAsync(int id, CategoriaRequest request, CancellationToken ct = default) => RunAsync(conn =>
        conn.ExecuteAsync(new CommandDefinition("sp_Categoria_Actualizar",
            new { id_categoria = id, nombre_categoria = request.NombreCategoria, descripcion = request.Descripcion },
            commandType: CommandType.StoredProcedure, cancellationToken: ct)));

    public Task EliminarAsync(int id, CancellationToken ct = default) => RunAsync(conn =>
        conn.ExecuteAsync(new CommandDefinition("sp_Categoria_Eliminar", new { id_categoria = id }, commandType: CommandType.StoredProcedure, cancellationToken: ct)));

    public Task<Categoria?> ObtenerPorIdAsync(int id, CancellationToken ct = default) => RunAsync(conn =>
        conn.QuerySingleOrDefaultAsync<Categoria>(new CommandDefinition("sp_Categoria_ObtenerPorId", new { id_categoria = id }, commandType: CommandType.StoredProcedure, cancellationToken: ct)));

    public Task<PagedResult<Categoria>> ListarAsync(PaginacionQuery query, CancellationToken ct = default) => RunAsync(async conn =>
    {
        using var multi = await conn.QueryMultipleAsync(new CommandDefinition("sp_Categoria_Listar",
            new { pagina = query.Pagina, tamano = query.Tamano, busqueda = query.Busqueda }, commandType: CommandType.StoredProcedure, cancellationToken: ct));
        var items = (await multi.ReadAsync<Categoria>()).ToList();
        var total = await multi.ReadSingleAsync<int>();
        return new PagedResult<Categoria> { Items = items, Total = total, Pagina = query.Pagina, Tamano = query.Tamano };
    });
}

public sealed class ProveedorRepository(IDbConnectionFactory factory) : RepositoryBase(factory), IProveedorRepository
{
    public Task<int> InsertarAsync(ProveedorRequest request, CancellationToken ct = default) => RunAsync(async conn =>
    {
        var p = new DynamicParameters();
        p.Add("@nombre_empresa", request.NombreEmpresa);
        p.Add("@contacto_nombre", request.ContactoNombre);
        p.Add("@telefono", request.Telefono);
        p.Add("@email", request.Email);
        p.Add("@id_creado", dbType: DbType.Int32, direction: ParameterDirection.Output);
        await conn.ExecuteAsync(new CommandDefinition("sp_Proveedor_Insertar", p, commandType: CommandType.StoredProcedure, cancellationToken: ct));
        return p.Get<int>("@id_creado");
    });

    public Task ActualizarAsync(int id, ProveedorRequest request, CancellationToken ct = default) => RunAsync(conn =>
        conn.ExecuteAsync(new CommandDefinition("sp_Proveedor_Actualizar",
            new
            {
                id_proveedor = id, nombre_empresa = request.NombreEmpresa,
                contacto_nombre = request.ContactoNombre, telefono = request.Telefono, email = request.Email,
            },
            commandType: CommandType.StoredProcedure, cancellationToken: ct)));

    public Task EliminarAsync(int id, CancellationToken ct = default) => RunAsync(conn =>
        conn.ExecuteAsync(new CommandDefinition("sp_Proveedor_Eliminar", new { id_proveedor = id }, commandType: CommandType.StoredProcedure, cancellationToken: ct)));

    public Task<Proveedor?> ObtenerPorIdAsync(int id, CancellationToken ct = default) => RunAsync(conn =>
        conn.QuerySingleOrDefaultAsync<Proveedor>(new CommandDefinition("sp_Proveedor_ObtenerPorId", new { id_proveedor = id }, commandType: CommandType.StoredProcedure, cancellationToken: ct)));

    public Task<PagedResult<Proveedor>> ListarAsync(PaginacionQuery query, CancellationToken ct = default) => RunAsync(async conn =>
    {
        using var multi = await conn.QueryMultipleAsync(new CommandDefinition("sp_Proveedor_Listar",
            new { pagina = query.Pagina, tamano = query.Tamano, busqueda = query.Busqueda }, commandType: CommandType.StoredProcedure, cancellationToken: ct));
        var items = (await multi.ReadAsync<Proveedor>()).ToList();
        var total = await multi.ReadSingleAsync<int>();
        return new PagedResult<Proveedor> { Items = items, Total = total, Pagina = query.Pagina, Tamano = query.Tamano };
    });
}

public sealed class LaboratorioRepository(IDbConnectionFactory factory) : RepositoryBase(factory), ILaboratorioRepository
{
    public Task<int> InsertarAsync(LaboratorioRequest request, CancellationToken ct = default) => RunAsync(async conn =>
    {
        var p = new DynamicParameters();
        p.Add("@nombre", request.Nombre);
        p.Add("@pais_origen", request.PaisOrigen);
        p.Add("@telefono", request.Telefono);
        p.Add("@email", request.Email);
        p.Add("@sitio_web", request.SitioWeb);
        p.Add("@id_creado", dbType: DbType.Int32, direction: ParameterDirection.Output);
        await conn.ExecuteAsync(new CommandDefinition("sp_Laboratorio_Insertar", p, commandType: CommandType.StoredProcedure, cancellationToken: ct));
        return p.Get<int>("@id_creado");
    });

    public Task ActualizarAsync(int id, LaboratorioRequest request, CancellationToken ct = default) => RunAsync(conn =>
        conn.ExecuteAsync(new CommandDefinition("sp_Laboratorio_Actualizar",
            new
            {
                id_laboratorio = id, nombre = request.Nombre, pais_origen = request.PaisOrigen,
                telefono = request.Telefono, email = request.Email, sitio_web = request.SitioWeb,
            },
            commandType: CommandType.StoredProcedure, cancellationToken: ct)));

    public Task EliminarAsync(int id, CancellationToken ct = default) => RunAsync(conn =>
        conn.ExecuteAsync(new CommandDefinition("sp_Laboratorio_Eliminar", new { id_laboratorio = id }, commandType: CommandType.StoredProcedure, cancellationToken: ct)));

    public Task<Laboratorio?> ObtenerPorIdAsync(int id, CancellationToken ct = default) => RunAsync(conn =>
        conn.QuerySingleOrDefaultAsync<Laboratorio>(new CommandDefinition("sp_Laboratorio_ObtenerPorId", new { id_laboratorio = id }, commandType: CommandType.StoredProcedure, cancellationToken: ct)));

    public Task<PagedResult<Laboratorio>> ListarAsync(PaginacionQuery query, CancellationToken ct = default) => RunAsync(async conn =>
    {
        using var multi = await conn.QueryMultipleAsync(new CommandDefinition("sp_Laboratorio_Listar",
            new { pagina = query.Pagina, tamano = query.Tamano, busqueda = query.Busqueda }, commandType: CommandType.StoredProcedure, cancellationToken: ct));
        var items = (await multi.ReadAsync<Laboratorio>()).ToList();
        var total = await multi.ReadSingleAsync<int>();
        return new PagedResult<Laboratorio> { Items = items, Total = total, Pagina = query.Pagina, Tamano = query.Tamano };
    });
}

public sealed class PrincipioActivoRepository(IDbConnectionFactory factory) : RepositoryBase(factory), IPrincipioActivoRepository
{
    public Task<int> InsertarAsync(PrincipioActivoRequest request, CancellationToken ct = default) => RunAsync(async conn =>
    {
        var p = new DynamicParameters();
        p.Add("@nombre_inn", request.NombreInn);
        p.Add("@grupo_terapeutico", request.GrupoTerapeutico);
        p.Add("@descripcion", request.Descripcion);
        p.Add("@id_creado", dbType: DbType.Int32, direction: ParameterDirection.Output);
        await conn.ExecuteAsync(new CommandDefinition("sp_PrincipioActivo_Insertar", p, commandType: CommandType.StoredProcedure, cancellationToken: ct));
        return p.Get<int>("@id_creado");
    });

    public Task ActualizarAsync(int id, PrincipioActivoRequest request, CancellationToken ct = default) => RunAsync(conn =>
        conn.ExecuteAsync(new CommandDefinition("sp_PrincipioActivo_Actualizar",
            new { id_principio = id, nombre_inn = request.NombreInn, grupo_terapeutico = request.GrupoTerapeutico, descripcion = request.Descripcion },
            commandType: CommandType.StoredProcedure, cancellationToken: ct)));

    public Task EliminarAsync(int id, CancellationToken ct = default) => RunAsync(conn =>
        conn.ExecuteAsync(new CommandDefinition("sp_PrincipioActivo_Eliminar", new { id_principio = id }, commandType: CommandType.StoredProcedure, cancellationToken: ct)));

    public Task<PrincipioActivo?> ObtenerPorIdAsync(int id, CancellationToken ct = default) => RunAsync(conn =>
        conn.QuerySingleOrDefaultAsync<PrincipioActivo>(new CommandDefinition("sp_PrincipioActivo_ObtenerPorId", new { id_principio = id }, commandType: CommandType.StoredProcedure, cancellationToken: ct)));

    public Task<PagedResult<PrincipioActivo>> ListarAsync(PaginacionQuery query, CancellationToken ct = default) => RunAsync(async conn =>
    {
        using var multi = await conn.QueryMultipleAsync(new CommandDefinition("sp_PrincipioActivo_Listar",
            new { pagina = query.Pagina, tamano = query.Tamano, busqueda = query.Busqueda }, commandType: CommandType.StoredProcedure, cancellationToken: ct));
        var items = (await multi.ReadAsync<PrincipioActivo>()).ToList();
        var total = await multi.ReadSingleAsync<int>();
        return new PagedResult<PrincipioActivo> { Items = items, Total = total, Pagina = query.Pagina, Tamano = query.Tamano };
    });
}

public sealed class PresentacionRepository(IDbConnectionFactory factory) : RepositoryBase(factory), IPresentacionRepository
{
    public Task<int> InsertarAsync(PresentacionRequest request, CancellationToken ct = default) => RunAsync(async conn =>
    {
        var p = new DynamicParameters();
        p.Add("@forma", request.Forma);
        p.Add("@unidad_medida", request.UnidadMedida);
        p.Add("@id_creado", dbType: DbType.Int32, direction: ParameterDirection.Output);
        await conn.ExecuteAsync(new CommandDefinition("sp_Presentacion_Insertar", p, commandType: CommandType.StoredProcedure, cancellationToken: ct));
        return p.Get<int>("@id_creado");
    });

    public Task ActualizarAsync(int id, PresentacionRequest request, CancellationToken ct = default) => RunAsync(conn =>
        conn.ExecuteAsync(new CommandDefinition("sp_Presentacion_Actualizar",
            new { id_presentacion = id, forma = request.Forma, unidad_medida = request.UnidadMedida },
            commandType: CommandType.StoredProcedure, cancellationToken: ct)));

    public Task EliminarAsync(int id, CancellationToken ct = default) => RunAsync(conn =>
        conn.ExecuteAsync(new CommandDefinition("sp_Presentacion_Eliminar", new { id_presentacion = id }, commandType: CommandType.StoredProcedure, cancellationToken: ct)));

    public Task<Presentacion?> ObtenerPorIdAsync(int id, CancellationToken ct = default) => RunAsync(conn =>
        conn.QuerySingleOrDefaultAsync<Presentacion>(new CommandDefinition("sp_Presentacion_ObtenerPorId", new { id_presentacion = id }, commandType: CommandType.StoredProcedure, cancellationToken: ct)));

    public Task<PagedResult<Presentacion>> ListarAsync(PaginacionQuery query, CancellationToken ct = default) => RunAsync(async conn =>
    {
        using var multi = await conn.QueryMultipleAsync(new CommandDefinition("sp_Presentacion_Listar",
            new { pagina = query.Pagina, tamano = query.Tamano, busqueda = query.Busqueda }, commandType: CommandType.StoredProcedure, cancellationToken: ct));
        var items = (await multi.ReadAsync<Presentacion>()).ToList();
        var total = await multi.ReadSingleAsync<int>();
        return new PagedResult<Presentacion> { Items = items, Total = total, Pagina = query.Pagina, Tamano = query.Tamano };
    });
}
