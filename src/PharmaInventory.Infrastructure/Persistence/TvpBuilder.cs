using System.Data;
using Dapper;
using PharmaInventory.Application.Dtos;

namespace PharmaInventory.Infrastructure.Persistence;

/// <summary>
/// Arma los DataTable que Dapper envia como Table-Valued Parameters, en el
/// mismo orden de columnas que los tipos definidos en 01_Tipos_Tabla_TVP.sql.
/// Cada metodo retorna un ICustomQueryParameter listo para
/// DynamicParameters.Add("@detalle", ...).
/// </summary>
public static class TvpBuilder
{
    public static SqlMapper.ICustomQueryParameter DetalleVenta(IEnumerable<LineaVentaRequest> lineas)
    {
        var dt = new DataTable();
        dt.Columns.Add("id_producto", typeof(int));
        dt.Columns.Add("cantidad", typeof(int));
        dt.Columns.Add("precio_unitario", typeof(decimal));
        foreach (var l in lineas)
            dt.Rows.Add(l.IdProducto, l.Cantidad, l.PrecioUnitario);
        return dt.AsTableValuedParameter("dbo.TipoDetalleVenta");
    }

    /// <summary>Para sp_Compra_Registrar: id_detalle aun no existe (DBNull).</summary>
    public static SqlMapper.ICustomQueryParameter DetalleCompraRegistro(IEnumerable<LineaCompraRequest> lineas)
    {
        var dt = NuevaTablaDetalleCompra();
        foreach (var l in lineas)
            dt.Rows.Add(DBNull.Value, l.IdProducto, l.Cantidad, l.PrecioUnitario, l.NumeroLote,
                (object?)l.FechaFabricacion ?? DBNull.Value, l.FechaVencimiento);
        return dt.AsTableValuedParameter("dbo.TipoDetalleCompra");
    }

    /// <summary>Para sp_Compra_Recibir: id_detalle es obligatorio (bug B4, ver 08_Compras.sql).</summary>
    public static SqlMapper.ICustomQueryParameter DetalleCompraRecepcion(IEnumerable<LineaRecepcionRequest> lineas)
    {
        var dt = NuevaTablaDetalleCompra();
        foreach (var l in lineas)
            dt.Rows.Add(l.IdDetalle, l.IdProducto, l.Cantidad, l.PrecioUnitario, l.NumeroLote,
                (object?)l.FechaFabricacion ?? DBNull.Value, l.FechaVencimiento);
        return dt.AsTableValuedParameter("dbo.TipoDetalleCompra");
    }

    public static SqlMapper.ICustomQueryParameter DetalleReceta(IEnumerable<LineaRecetaRequest> lineas)
    {
        var dt = new DataTable();
        dt.Columns.Add("id_producto", typeof(int));
        dt.Columns.Add("cantidad_prescrita", typeof(int));
        dt.Columns.Add("dosis", typeof(string));
        dt.Columns.Add("duracion_tratamiento", typeof(string));
        foreach (var l in lineas)
            dt.Rows.Add(l.IdProducto, l.CantidadPrescrita, (object?)l.Dosis ?? DBNull.Value, (object?)l.DuracionTratamiento ?? DBNull.Value);
        return dt.AsTableValuedParameter("dbo.TipoDetalleReceta");
    }

    private static DataTable NuevaTablaDetalleCompra()
    {
        var dt = new DataTable();
        dt.Columns.Add("id_detalle", typeof(int));
        dt.Columns.Add("id_producto", typeof(int));
        dt.Columns.Add("cantidad", typeof(int));
        dt.Columns.Add("precio_unitario", typeof(decimal));
        dt.Columns.Add("numero_lote", typeof(string));
        dt.Columns.Add("fecha_fabricacion", typeof(DateTime));
        dt.Columns.Add("fecha_vencimiento", typeof(DateTime));
        return dt;
    }
}
