using PharmaInventory.Domain.Enums;

namespace PharmaInventory.Domain.Entities;

/// <summary>
/// Tabla productos. stock_actual y precio_promedio_pond son de solo lectura
/// desde la Api: unicamente sp_Kardex_RegistrarMovimiento los mueve (ver
/// CLAUDE.md seccion 5.3) -- sp_Producto_Actualizar nunca los toca.
/// </summary>
public class Producto
{
    public int IdProducto { get; set; }
    public string Nombre { get; set; } = string.Empty;
    public string? NombreGenerico { get; set; }
    public string? CodigoSku { get; set; }
    public string? CodigoBarras { get; set; }
    public decimal PrecioCosto { get; set; }
    public decimal PrecioVenta { get; set; }
    public int StockActual { get; set; }
    public decimal PrecioPromedioPond { get; set; }
    public int StockMinimo { get; set; }
    public bool RequiereReceta { get; set; }
    public int? IdCategoria { get; set; }
    public int? IdProveedor { get; set; }
    public int? IdLaboratorio { get; set; }
    public int? IdPresentacion { get; set; }

    // Campos resueltos por join (vw_Productos / sp_Producto_ObtenerPorId) -- null en INSERT/UPDATE.
    public string? NombreCategoria { get; set; }
    public string? Proveedor { get; set; }
    public string? Laboratorio { get; set; }
    public string? Presentacion { get; set; }
}

/// <summary>
/// Tabla medicamentos. IdMedicamento es 1:1 con IdProducto (misma PK, sin
/// IDENTITY propia -- ver sp_Medicamento_Insertar).
/// </summary>
public class Medicamento
{
    public int IdMedicamento { get; set; }
    public int IdProducto { get; set; }
    public string? Concentracion { get; set; }
    public ViaAdministracion ViaAdministracion { get; set; }
    public string? CondicionesAlmacenamiento { get; set; }
    public bool Controlado { get; set; }
    public string? NumeroRegistroSanitario { get; set; }
    public string? Indicaciones { get; set; }
    public string? Contraindicaciones { get; set; }
    public string? EfectosSecundarios { get; set; }
    public string? Interacciones { get; set; }
}

/// <summary>Tabla medicamento_principios (N:M medicamento &lt;-&gt; principio activo).</summary>
public class MedicamentoPrincipio
{
    public int IdMedicamento { get; set; }
    public int IdPrincipio { get; set; }
    public decimal? CantidadPorDosis { get; set; }
    public string? Unidad { get; set; }

    // Campos resueltos por join (vw_ProductosMedicamentos).
    public string? NombreInn { get; set; }
    public string? GrupoTerapeutico { get; set; }
}
