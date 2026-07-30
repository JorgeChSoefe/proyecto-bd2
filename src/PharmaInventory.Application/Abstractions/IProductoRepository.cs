using PharmaInventory.Application.Common;
using PharmaInventory.Application.Dtos;
using PharmaInventory.Domain.Entities;

namespace PharmaInventory.Application.Abstractions;

public interface IProductoRepository
{
    Task<int> InsertarAsync(ProductoRequest request, CancellationToken ct = default);
    Task ActualizarAsync(int id, ProductoUpdateRequest request, CancellationToken ct = default);
    Task EliminarAsync(int id, CancellationToken ct = default);
    Task<ProductoDetalleDto?> ObtenerPorIdAsync(int id, CancellationToken ct = default);
    Task<PagedResult<Producto>> ListarAsync(PaginacionQuery query, int? idCategoria = null, CancellationToken ct = default);
}

public interface IMedicamentoRepository
{
    Task InsertarAsync(MedicamentoRequest request, CancellationToken ct = default);
    Task ActualizarAsync(int idMedicamento, MedicamentoUpdateRequest request, CancellationToken ct = default);
    Task AsignarPrincipioAsync(MedicamentoPrincipioRequest request, CancellationToken ct = default);
    Task QuitarPrincipioAsync(int idMedicamento, int idPrincipio, CancellationToken ct = default);

    /// <summary>vw_ProductosMedicamentos: ficha tecnica completa (una fila por principio activo asignado).</summary>
    Task<IReadOnlyList<FichaMedicamentoDto>> ObtenerFichaPorProductoAsync(int idProducto, CancellationToken ct = default);
}
