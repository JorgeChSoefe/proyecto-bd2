using PharmaInventory.Application.Common;

namespace PharmaInventory.Application.Abstractions;

/// <summary>
/// Forma comun a todos los catalogos simples (roles, permisos, empleados,
/// categorias, proveedores, laboratorios, principios_activos,
/// presentaciones): Insertar/Actualizar/Eliminar/ObtenerPorId/Listar, cada
/// uno invocando exactamente el SP homonimo del modulo (sp_&lt;Entidad&gt;_Insertar,
/// etc). TRequest es el DTO de entrada (sin Id); TEntity es la entidad de
/// Domain que ya trae los campos resueltos por join de la vista.
/// </summary>
public interface ICatalogoRepository<TEntity, in TRequest>
{
    Task<int> InsertarAsync(TRequest request, CancellationToken ct = default);
    Task ActualizarAsync(int id, TRequest request, CancellationToken ct = default);
    Task EliminarAsync(int id, CancellationToken ct = default);
    Task<TEntity?> ObtenerPorIdAsync(int id, CancellationToken ct = default);
    Task<PagedResult<TEntity>> ListarAsync(PaginacionQuery query, CancellationToken ct = default);
}
