using PharmaInventory.Application.Common;
using PharmaInventory.Application.Dtos;
using PharmaInventory.Domain.Entities;

namespace PharmaInventory.Application.Abstractions;

public interface IRolRepository : ICatalogoRepository<Rol, RolRequest>;

public interface IPermisoRepository : ICatalogoRepository<Permiso, PermisoRequest>
{
    Task AsignarARolAsync(int idRol, int idPermiso, CancellationToken ct = default);
    Task RevocarDeRolAsync(int idRol, int idPermiso, CancellationToken ct = default);

    /// <summary>sp_Rol_ObtenerPermisos: permisos YA asignados a un rol (para pintar el estado real en el frontend).</summary>
    Task<IReadOnlyList<Permiso>> ObtenerPermisosDeRolAsync(int idRol, CancellationToken ct = default);
}

public interface IEmpleadoRepository : ICatalogoRepository<Empleado, EmpleadoRequest>;

/// <summary>
/// Autenticacion y gestion de usuarios. sp_Usuario_Autenticar solo retorna la
/// fila (incluyendo password_hash) para que la Api verifique con BCrypt --
/// la BD nunca ve la password en claro ni decide si el hash matchea.
/// </summary>
public interface IUsuarioRepository
{
    Task<int> InsertarAsync(UsuarioRequest request, CancellationToken ct = default);
    Task ActualizarAsync(int id, UsuarioUpdateRequest request, CancellationToken ct = default);
    Task CambiarPasswordAsync(int id, string passwordHashNuevo, CancellationToken ct = default);
    Task DesactivarAsync(int id, CancellationToken ct = default);
    Task<Usuario?> AutenticarAsync(string nombreUsuario, CancellationToken ct = default);
    Task ActualizarUltimoAccesoAsync(int id, CancellationToken ct = default);
    Task<Usuario?> ObtenerPorIdAsync(int id, CancellationToken ct = default);
    Task<PagedResult<Usuario>> ListarAsync(PaginacionQuery query, CancellationToken ct = default);

    /// <summary>Permisos efectivos (vw_UsuarioPermisos) para armar los claims del JWT.</summary>
    Task<IReadOnlyList<Permiso>> ObtenerPermisosAsync(int idUsuario, CancellationToken ct = default);
}
