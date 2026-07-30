using PharmaInventory.Domain.Enums;

namespace PharmaInventory.Domain.Entities;

/// <summary>Tabla compras.</summary>
public class Compra
{
    public int IdCompra { get; set; }
    public DateTime FechaCompra { get; set; }
    public decimal Total { get; set; }
    public EstadoCompra Estado { get; set; }
    public int? IdProveedor { get; set; }
    public int? IdEmpleado { get; set; }
    public int? IdUsuario { get; set; }

    // Campos resueltos por join (vw_Compras).
    public string? NombreProveedor { get; set; }
    public string? NombreEmpleado { get; set; }
    public string? NombreUsuario { get; set; }
}

/// <summary>
/// Tabla detalle_compras. IdLote es NULL hasta que sp_Compra_Recibir procesa
/// la linea; IdDetalle es el que hay que reenviar (junto con IdLote real de
/// destino) al recibir -- ver bug B4 en 08_Compras.sql.
/// </summary>
public class DetalleCompra
{
    public int IdDetalle { get; set; }
    public int Cantidad { get; set; }
    public decimal PrecioUnitario { get; set; }
    public decimal Subtotal { get; set; }
    public int IdCompra { get; set; }
    public int IdProducto { get; set; }
    public int? IdLote { get; set; }

    // Campos resueltos por join (sp_Compra_ObtenerPorId).
    public string? NombreProducto { get; set; }
    public string? NumeroLote { get; set; }

    // Lote/fechas propuestos al registrar (antes de recibir) -- prefill para
    // sp_Compra_Recibir sin tener que volver a pedirlos. Una vez recibida la
    // compra, el lote REAL vive en NumeroLote (via join a lotes); estos campos
    // quedan como el registro historico de lo que se pidio originalmente.
    public string? NumeroLotePropuesto { get; set; }
    public DateTime? FechaFabricacionPropuesta { get; set; }
    public DateTime? FechaVencimientoPropuesta { get; set; }

    /// <summary>Vencimiento REAL del lote ya creado (via join a lotes) -- solo no-null despues de recibir.</summary>
    public DateTime? FechaVencimientoReal { get; set; }
}
