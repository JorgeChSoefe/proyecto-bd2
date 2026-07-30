using PharmaInventory.Application.Common;
using PharmaInventory.Application.Dtos;
using PharmaInventory.Domain.Entities;
using PharmaInventory.Domain.Enums;

namespace PharmaInventory.Application.Abstractions;

public interface ICompraRepository
{
    /// <summary>sp_Compra_Registrar. Deja la compra en 'pendiente', sin lotes ni kardex. Retorna id_compra_creada.</summary>
    Task<int> RegistrarAsync(CompraRequest request, int idUsuario, CancellationToken ct = default);

    /// <summary>sp_Compra_Recibir. Genera/actualiza lotes y kardex de entrada; pasa la compra a 'recibida'.</summary>
    Task RecibirAsync(int idCompra, CompraRecibirRequest request, int idUsuario, CancellationToken ct = default);

    /// <summary>sp_Compra_Anular. Solo permitido si la compra sigue 'pendiente'.</summary>
    Task AnularAsync(int idCompra, CancellationToken ct = default);

    Task<CompraDetalleDto?> ObtenerPorIdAsync(int id, CancellationToken ct = default);

    Task<PagedResult<Compra>> ListarAsync(
        PaginacionQuery query, EstadoCompra? estado = null,
        DateOnly? fechaDesde = null, DateOnly? fechaHasta = null, CancellationToken ct = default);
}
