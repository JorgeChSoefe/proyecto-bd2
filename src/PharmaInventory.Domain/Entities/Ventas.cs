using PharmaInventory.Domain.Enums;

namespace PharmaInventory.Domain.Entities;

/// <summary>Tabla ventas.</summary>
public class Venta
{
    public int IdVenta { get; set; }
    public DateTime FechaVenta { get; set; }
    public decimal Total { get; set; }
    public EstadoVenta Estado { get; set; }
    public int? IdEmpleado { get; set; }
    public int? IdCliente { get; set; }
    public int? IdUsuario { get; set; }
    public int? IdReceta { get; set; }

    // Campos resueltos por join (vw_Ventas).
    public string? NombreEmpleado { get; set; }
    public string? NombreCliente { get; set; }
    public string? NombreUsuario { get; set; }
}

/// <summary>Tabla detalle_ventas. IdLote es el lote FEFO efectivamente despachado.</summary>
public class DetalleVenta
{
    public int IdDetalle { get; set; }
    public int Cantidad { get; set; }
    public decimal PrecioUnitario { get; set; }
    public decimal Subtotal { get; set; }
    public int IdVenta { get; set; }
    public int IdProducto { get; set; }
    public int? IdLote { get; set; }

    // Campos resueltos por join (sp_Venta_ObtenerPorId / vw_VentasDetalladas).
    public string? NombreProducto { get; set; }
    public string? NumeroLote { get; set; }
}
