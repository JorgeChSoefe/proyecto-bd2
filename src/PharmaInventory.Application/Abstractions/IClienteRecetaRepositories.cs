using PharmaInventory.Application.Common;
using PharmaInventory.Application.Dtos;
using PharmaInventory.Domain.Entities;

namespace PharmaInventory.Application.Abstractions;

public interface IClienteRepository : ICatalogoRepository<Cliente, ClienteRequest>;

public interface IRecetaRepository
{
    /// <summary>sp_Receta_Registrar (transaccional: cabecera + detalle en un TVP). Retorna id_receta_creada.</summary>
    Task<int> RegistrarAsync(RecetaRequest request, CancellationToken ct = default);
    Task<RecetaDetalleDto?> ObtenerPorIdAsync(int id, CancellationToken ct = default);
    Task<PagedResult<Receta>> ListarPendientesAsync(PaginacionQuery query, int? idCliente = null, CancellationToken ct = default);
}
