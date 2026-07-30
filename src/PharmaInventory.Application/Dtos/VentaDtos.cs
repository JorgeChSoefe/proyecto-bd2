using PharmaInventory.Domain.Entities;

namespace PharmaInventory.Application.Dtos;

/// <summary>Una linea del TVP dbo.TipoDetalleVenta.</summary>
public sealed record LineaVentaRequest(int IdProducto, int Cantidad, decimal PrecioUnitario);

/// <summary>
/// POST /api/ventas. IdUsuario NO viaja aqui: lo resuelve el controller desde
/// el JWT. IdReceta es obligatorio si algun producto requiere receta o es
/// controlado (lo valida sp_Venta_Registrar, no la Api).
/// </summary>
public sealed record VentaRequest(int IdEmpleado, int? IdCliente, int? IdReceta, IReadOnlyList<LineaVentaRequest> Detalle);

/// <summary>Resultado de sp_Venta_ObtenerPorId: cabecera + lineas (una por lote FEFO afectado).</summary>
public sealed record VentaDetalleDto(Venta Venta, IReadOnlyList<DetalleVenta> Lineas);
