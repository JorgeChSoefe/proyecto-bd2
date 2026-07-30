using System.Data;
using Dapper;
using PharmaInventory.Application.Abstractions;
using PharmaInventory.Application.Common;
using PharmaInventory.Application.Dtos;
using PharmaInventory.Domain.Entities;
using PharmaInventory.Infrastructure.Persistence;

namespace PharmaInventory.Infrastructure.Repositories;

public sealed class RolRepository(IDbConnectionFactory factory) : RepositoryBase(factory), IRolRepository
{
    public Task<int> InsertarAsync(RolRequest request, CancellationToken ct = default) => RunAsync(async conn =>
    {
        var p = new DynamicParameters();
        p.Add("@nombre_rol", request.NombreRol);
        p.Add("@descripcion", request.Descripcion);
        p.Add("@id_rol_creado", dbType: DbType.Int32, direction: ParameterDirection.Output);
        await conn.ExecuteAsync(new CommandDefinition("sp_Rol_Insertar", p, commandType: CommandType.StoredProcedure, cancellationToken: ct));
        return p.Get<int>("@id_rol_creado");
    });

    public Task ActualizarAsync(int id, RolRequest request, CancellationToken ct = default) => RunAsync(conn =>
        conn.ExecuteAsync(new CommandDefinition("sp_Rol_Actualizar",
            new { id_rol = id, nombre_rol = request.NombreRol, descripcion = request.Descripcion },
            commandType: CommandType.StoredProcedure, cancellationToken: ct)));

    public Task EliminarAsync(int id, CancellationToken ct = default) => RunAsync(conn =>
        conn.ExecuteAsync(new CommandDefinition("sp_Rol_Eliminar", new { id_rol = id }, commandType: CommandType.StoredProcedure, cancellationToken: ct)));

    public Task<Rol?> ObtenerPorIdAsync(int id, CancellationToken ct = default) => RunAsync(conn =>
        conn.QuerySingleOrDefaultAsync<Rol>(new CommandDefinition("sp_Rol_ObtenerPorId", new { id_rol = id }, commandType: CommandType.StoredProcedure, cancellationToken: ct)));

    public Task<PagedResult<Rol>> ListarAsync(PaginacionQuery query, CancellationToken ct = default) => RunAsync(async conn =>
    {
        using var multi = await conn.QueryMultipleAsync(new CommandDefinition("sp_Rol_Listar",
            new { pagina = query.Pagina, tamano = query.Tamano, busqueda = query.Busqueda }, commandType: CommandType.StoredProcedure, cancellationToken: ct));
        var items = (await multi.ReadAsync<Rol>()).ToList();
        var total = await multi.ReadSingleAsync<int>();
        return new PagedResult<Rol> { Items = items, Total = total, Pagina = query.Pagina, Tamano = query.Tamano };
    });
}

public sealed class PermisoRepository(IDbConnectionFactory factory) : RepositoryBase(factory), IPermisoRepository
{
    public Task<int> InsertarAsync(PermisoRequest request, CancellationToken ct = default) => RunAsync(async conn =>
    {
        var p = new DynamicParameters();
        p.Add("@modulo", request.Modulo);
        p.Add("@accion", request.Accion);
        p.Add("@descripcion", request.Descripcion);
        p.Add("@id_permiso_creado", dbType: DbType.Int32, direction: ParameterDirection.Output);
        await conn.ExecuteAsync(new CommandDefinition("sp_Permiso_Insertar", p, commandType: CommandType.StoredProcedure, cancellationToken: ct));
        return p.Get<int>("@id_permiso_creado");
    });

    public Task ActualizarAsync(int id, PermisoRequest request, CancellationToken ct = default) => RunAsync(conn =>
        conn.ExecuteAsync(new CommandDefinition("sp_Permiso_Actualizar",
            new { id_permiso = id, modulo = request.Modulo, accion = request.Accion, descripcion = request.Descripcion },
            commandType: CommandType.StoredProcedure, cancellationToken: ct)));

    public Task EliminarAsync(int id, CancellationToken ct = default) => RunAsync(conn =>
        conn.ExecuteAsync(new CommandDefinition("sp_Permiso_Eliminar", new { id_permiso = id }, commandType: CommandType.StoredProcedure, cancellationToken: ct)));

    public Task<Permiso?> ObtenerPorIdAsync(int id, CancellationToken ct = default) => RunAsync(conn =>
        conn.QuerySingleOrDefaultAsync<Permiso>(new CommandDefinition("sp_Permiso_ObtenerPorId", new { id_permiso = id }, commandType: CommandType.StoredProcedure, cancellationToken: ct)));

    public Task<PagedResult<Permiso>> ListarAsync(PaginacionQuery query, CancellationToken ct = default) => RunAsync(async conn =>
    {
        using var multi = await conn.QueryMultipleAsync(new CommandDefinition("sp_Permiso_Listar",
            new { pagina = query.Pagina, tamano = query.Tamano, busqueda = query.Busqueda }, commandType: CommandType.StoredProcedure, cancellationToken: ct));
        var items = (await multi.ReadAsync<Permiso>()).ToList();
        var total = await multi.ReadSingleAsync<int>();
        return new PagedResult<Permiso> { Items = items, Total = total, Pagina = query.Pagina, Tamano = query.Tamano };
    });

    public Task AsignarARolAsync(int idRol, int idPermiso, CancellationToken ct = default) => RunAsync(conn =>
        conn.ExecuteAsync(new CommandDefinition("sp_Permiso_AsignarARol", new { id_rol = idRol, id_permiso = idPermiso }, commandType: CommandType.StoredProcedure, cancellationToken: ct)));

    public Task RevocarDeRolAsync(int idRol, int idPermiso, CancellationToken ct = default) => RunAsync(conn =>
        conn.ExecuteAsync(new CommandDefinition("sp_Permiso_RevocarDeRol", new { id_rol = idRol, id_permiso = idPermiso }, commandType: CommandType.StoredProcedure, cancellationToken: ct)));

    public Task<IReadOnlyList<Permiso>> ObtenerPermisosDeRolAsync(int idRol, CancellationToken ct = default) => RunAsync(async conn =>
    {
        var rows = await conn.QueryAsync<Permiso>(new CommandDefinition("sp_Rol_ObtenerPermisos",
            new { id_rol = idRol }, commandType: CommandType.StoredProcedure, cancellationToken: ct));
        return (IReadOnlyList<Permiso>)rows.ToList();
    });
}

public sealed class EmpleadoRepository(IDbConnectionFactory factory) : RepositoryBase(factory), IEmpleadoRepository
{
    public Task<int> InsertarAsync(EmpleadoRequest request, CancellationToken ct = default) => RunAsync(async conn =>
    {
        var p = new DynamicParameters();
        p.Add("@nombre_completo", request.NombreCompleto);
        p.Add("@cargo", request.Cargo);
        p.Add("@email", request.Email);
        p.Add("@id_empleado_creado", dbType: DbType.Int32, direction: ParameterDirection.Output);
        await conn.ExecuteAsync(new CommandDefinition("sp_Empleado_Insertar", p, commandType: CommandType.StoredProcedure, cancellationToken: ct));
        return p.Get<int>("@id_empleado_creado");
    });

    public Task ActualizarAsync(int id, EmpleadoRequest request, CancellationToken ct = default) => RunAsync(conn =>
        conn.ExecuteAsync(new CommandDefinition("sp_Empleado_Actualizar",
            new { id_empleado = id, nombre_completo = request.NombreCompleto, cargo = request.Cargo, email = request.Email },
            commandType: CommandType.StoredProcedure, cancellationToken: ct)));

    public Task EliminarAsync(int id, CancellationToken ct = default) => RunAsync(conn =>
        conn.ExecuteAsync(new CommandDefinition("sp_Empleado_Eliminar", new { id_empleado = id }, commandType: CommandType.StoredProcedure, cancellationToken: ct)));

    public Task<Empleado?> ObtenerPorIdAsync(int id, CancellationToken ct = default) => RunAsync(conn =>
        conn.QuerySingleOrDefaultAsync<Empleado>(new CommandDefinition("sp_Empleado_ObtenerPorId", new { id_empleado = id }, commandType: CommandType.StoredProcedure, cancellationToken: ct)));

    public Task<PagedResult<Empleado>> ListarAsync(PaginacionQuery query, CancellationToken ct = default) => RunAsync(async conn =>
    {
        using var multi = await conn.QueryMultipleAsync(new CommandDefinition("sp_Empleado_Listar",
            new { pagina = query.Pagina, tamano = query.Tamano, busqueda = query.Busqueda }, commandType: CommandType.StoredProcedure, cancellationToken: ct));
        var items = (await multi.ReadAsync<Empleado>()).ToList();
        var total = await multi.ReadSingleAsync<int>();
        return new PagedResult<Empleado> { Items = items, Total = total, Pagina = query.Pagina, Tamano = query.Tamano };
    });
}

/// <summary>
/// AutenticarAsync retorna la fila completa (incluye PasswordHash) SOLO para
/// que la capa Api verifique con BCrypt -- ningun otro metodo ni DTO expone
/// ese campo hacia afuera de Infrastructure.
/// </summary>
public sealed class UsuarioRepository(IDbConnectionFactory factory) : RepositoryBase(factory), IUsuarioRepository
{
    public Task<int> InsertarAsync(UsuarioRequest request, CancellationToken ct = default) => RunAsync(async conn =>
    {
        var p = new DynamicParameters();
        p.Add("@nombre_usuario", request.NombreUsuario);
        p.Add("@email", request.Email);
        p.Add("@password_hash", request.PasswordHash);
        p.Add("@id_rol", request.IdRol);
        p.Add("@id_empleado", request.IdEmpleado);
        p.Add("@id_usuario_creado", dbType: DbType.Int32, direction: ParameterDirection.Output);
        await conn.ExecuteAsync(new CommandDefinition("sp_Usuario_Insertar", p, commandType: CommandType.StoredProcedure, cancellationToken: ct));
        return p.Get<int>("@id_usuario_creado");
    });

    public Task ActualizarAsync(int id, UsuarioUpdateRequest request, CancellationToken ct = default) => RunAsync(conn =>
        conn.ExecuteAsync(new CommandDefinition("sp_Usuario_Actualizar",
            new { id_usuario = id, email = request.Email, id_rol = request.IdRol, id_empleado = request.IdEmpleado },
            commandType: CommandType.StoredProcedure, cancellationToken: ct)));

    public Task CambiarPasswordAsync(int id, string passwordHashNuevo, CancellationToken ct = default) => RunAsync(conn =>
        conn.ExecuteAsync(new CommandDefinition("sp_Usuario_CambiarPassword",
            new { id_usuario = id, password_hash_nuevo = passwordHashNuevo }, commandType: CommandType.StoredProcedure, cancellationToken: ct)));

    public Task DesactivarAsync(int id, CancellationToken ct = default) => RunAsync(conn =>
        conn.ExecuteAsync(new CommandDefinition("sp_Usuario_Desactivar", new { id_usuario = id }, commandType: CommandType.StoredProcedure, cancellationToken: ct)));

    public Task<Usuario?> AutenticarAsync(string nombreUsuario, CancellationToken ct = default) => RunAsync(conn =>
        conn.QuerySingleOrDefaultAsync<Usuario>(new CommandDefinition("sp_Usuario_Autenticar", new { nombre_usuario = nombreUsuario }, commandType: CommandType.StoredProcedure, cancellationToken: ct)));

    public Task ActualizarUltimoAccesoAsync(int id, CancellationToken ct = default) => RunAsync(conn =>
        conn.ExecuteAsync(new CommandDefinition("sp_Usuario_ActualizarUltimoAcceso", new { id_usuario = id }, commandType: CommandType.StoredProcedure, cancellationToken: ct)));

    public Task<Usuario?> ObtenerPorIdAsync(int id, CancellationToken ct = default) => RunAsync(conn =>
        conn.QuerySingleOrDefaultAsync<Usuario>(new CommandDefinition("sp_Usuario_ObtenerPorId", new { id_usuario = id }, commandType: CommandType.StoredProcedure, cancellationToken: ct)));

    public Task<PagedResult<Usuario>> ListarAsync(PaginacionQuery query, CancellationToken ct = default) => RunAsync(async conn =>
    {
        using var multi = await conn.QueryMultipleAsync(new CommandDefinition("sp_Usuario_Listar",
            new { pagina = query.Pagina, tamano = query.Tamano, busqueda = query.Busqueda }, commandType: CommandType.StoredProcedure, cancellationToken: ct));
        var items = (await multi.ReadAsync<Usuario>()).ToList();
        var total = await multi.ReadSingleAsync<int>();
        return new PagedResult<Usuario> { Items = items, Total = total, Pagina = query.Pagina, Tamano = query.Tamano };
    });

    public Task<IReadOnlyList<Permiso>> ObtenerPermisosAsync(int idUsuario, CancellationToken ct = default) => RunAsync(async conn =>
    {
        var rows = await conn.QueryAsync<Permiso>(new CommandDefinition(
            "sp_Usuario_ObtenerPermisos", new { id_usuario = idUsuario }, commandType: CommandType.StoredProcedure, cancellationToken: ct));
        return (IReadOnlyList<Permiso>)rows.ToList();
    });
}
