namespace PharmaInventory.Domain.Enums;

// Los valores reflejan exactamente los CHECK constraints del esquema
// (ver 10_Schema_Tablas.sql). La conversion enum <-> string de BD (snake_case)
// la hace StringEnumTypeHandler<T> en Infrastructure -- el Domain no sabe nada de SQL.

/// <summary>ventas.estado / CK_ventas_estado</summary>
public enum EstadoVenta
{
    Pendiente,
    Completada,
    Anulada,
}

/// <summary>compras.estado / CK_compras_estado</summary>
public enum EstadoCompra
{
    Pendiente,
    Recibida,
    Anulada,
}

/// <summary>kardex.tipo_movimiento / CK_kardex_tipo</summary>
public enum TipoMovimientoKardex
{
    Entrada,
    Salida,
    Ajuste,
}

/// <summary>medicamentos.via_administracion / CK_medicamentos_via</summary>
public enum ViaAdministracion
{
    Oral,
    Topica,
    Intravenosa,
    Intramuscular,
    Subcutanea,
    Inhalatoria,
    Oftalmica,
    Otica,
    Nasal,
    Rectal,
    Sublingual,
}

/// <summary>alertas_stock.tipo_alerta / CK_alertas_tipo</summary>
public enum TipoAlerta
{
    VencimientoProximo,
    StockMinimo,
    LoteAgotado,
}
