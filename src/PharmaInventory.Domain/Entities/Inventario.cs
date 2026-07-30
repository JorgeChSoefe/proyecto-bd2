using PharmaInventory.Domain.Enums;

namespace PharmaInventory.Domain.Entities;

/// <summary>
/// Tabla lotes. CantidadActual es de solo lectura desde la Api -- solo la
/// mueve sp_Kardex_RegistrarMovimiento (dentro de compras/ventas/ajustes).
/// </summary>
public class Lote
{
    public int IdLote { get; set; }
    public string NumeroLote { get; set; } = string.Empty;
    public int IdProducto { get; set; }
    public int? IdCompra { get; set; }
    public DateTime? FechaFabricacion { get; set; }
    public DateTime FechaVencimiento { get; set; }
    public int CantidadInicial { get; set; }
    public int CantidadActual { get; set; }
    public decimal? PrecioCostoLote { get; set; }
    public bool Activo { get; set; }
    public DateTime CreadoEn { get; set; }
}

/// <summary>
/// Tabla kardex. Fila de solo lectura desde la Api: se genera exclusivamente
/// dentro de sp_Kardex_RegistrarMovimiento (nunca INSERT directo, ver
/// CLAUDE.md seccion 5.3, trazabilidad).
/// </summary>
public class MovimientoKardex
{
    public int IdMovimiento { get; set; }
    public DateTime FechaMovimiento { get; set; }
    public TipoMovimientoKardex TipoMovimiento { get; set; }
    public string? ReferenciaDoc { get; set; }
    public int? IdReferenciaDoc { get; set; }
    public int CantidadEntrada { get; set; }
    public int CantidadSalida { get; set; }
    public int SaldoStock { get; set; }
    public decimal? CostoUnitario { get; set; }
    public decimal? CostoTotalMov { get; set; }
    public decimal? PrecioPromedioPond { get; set; }
    public decimal? SaldoValorado { get; set; }
    public int IdProducto { get; set; }
    public int? IdLote { get; set; }
    public int? IdUsuario { get; set; }
    /// <summary>Motivo del ajuste manual (mermas, conteos fisicos) -- ver sp_Inventario_AjusteManual.</summary>
    public string? Observaciones { get; set; }

    // Campo resuelto por join (vw_KardexProducto).
    public string? NombreUsuario { get; set; }
}

/// <summary>Tabla alertas_stock.</summary>
public class AlertaStock
{
    public int IdAlerta { get; set; }

    // string, no el enum TipoAlerta: Dapper materializa enums de columnas
    // string llamando Enum.Parse directo (ignora el StringEnumTypeHandler
    // registrado) para CUALQUIER valor -- funciona por coincidencia con los
    // otros 4 enums (una sola palabra, ej. "completada" == "Completada"
    // ignorando mayusculas) pero revienta con snake_case de mas de una
    // palabra como "vencimiento_proximo" (ArgumentException: value not
    // found). El wire format no cambia: System.Text.Json serializa un string
    // plano identico al que ya viajaba, y el TipoAlerta del front (union de
    // los mismos 3 literales) sigue siendo compatible sin tocar nada alla.
    public string TipoAlerta { get; set; } = string.Empty;
    public int? IdProducto { get; set; }
    public int? IdLote { get; set; }
    public string? Mensaje { get; set; }
    public DateTime FechaAlerta { get; set; }
    public bool Resuelta { get; set; }
    public DateTime? FechaResolucion { get; set; }
    public int? IdUsuarioResolucion { get; set; }

    // Campo resuelto por join (vw_AlertasActivas).
    public string? NombreProducto { get; set; }
}
