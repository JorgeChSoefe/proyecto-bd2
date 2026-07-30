using PharmaInventory.Application.Common;
using PharmaInventory.Application.Dtos;
using PharmaInventory.Domain.Entities;
using PharmaInventory.Domain.Enums;

namespace PharmaInventory.Application.Abstractions;

public interface IVentaRepository
{
    /// <summary>sp_Venta_Registrar (transaccional, FEFO). Retorna id_venta_creada.</summary>
    Task<int> RegistrarAsync(VentaRequest request, int idUsuario, CancellationToken ct = default);

    /// <summary>sp_Venta_Anular (reversa de stock, ventana de dias, revierte dispensacion de receta).</summary>
    Task AnularAsync(int idVenta, int idUsuario, CancellationToken ct = default);

    Task<VentaDetalleDto?> ObtenerPorIdAsync(int id, CancellationToken ct = default);

    Task<PagedResult<Venta>> ListarAsync(
        PaginacionQuery query, EstadoVenta? estado = null,
        DateOnly? fechaDesde = null, DateOnly? fechaHasta = null, CancellationToken ct = default);
}
