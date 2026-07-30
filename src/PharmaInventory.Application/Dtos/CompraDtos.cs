using PharmaInventory.Domain.Entities;

namespace PharmaInventory.Application.Dtos;

/// <summary>Una linea del TVP dbo.TipoDetalleCompra al REGISTRAR (id_detalle aun no existe).</summary>
public sealed record LineaCompraRequest(
    int IdProducto, int Cantidad, decimal PrecioUnitario,
    string NumeroLote, DateTime? FechaFabricacion, DateTime FechaVencimiento);

/// <summary>POST /api/compras. IdUsuario lo resuelve el controller desde el JWT.</summary>
public sealed record CompraRequest(int IdProveedor, int IdEmpleado, IReadOnlyList<LineaCompraRequest> Detalle);

/// <summary>
/// Una linea del TVP dbo.TipoDetalleCompra al RECIBIR. IdDetalle es
/// OBLIGATORIO aqui -- identifica la fila real de detalle_compras a recibir
/// (bug B4: el match por producto+lote-nulo era ambiguo con 2+ lineas del
/// mismo producto). El front lo obtiene de GET /api/compras/{id} tras
/// registrar.
/// </summary>
public sealed record LineaRecepcionRequest(
    int IdDetalle, int IdProducto, int Cantidad, decimal PrecioUnitario,
    string NumeroLote, DateTime? FechaFabricacion, DateTime FechaVencimiento);

public sealed record CompraRecibirRequest(IReadOnlyList<LineaRecepcionRequest> Detalle);

/// <summary>Resultado de sp_Compra_ObtenerPorId: cabecera + lineas (con id_lote una vez recibida).</summary>
public sealed record CompraDetalleDto(Compra Compra, IReadOnlyList<DetalleCompra> Lineas);
