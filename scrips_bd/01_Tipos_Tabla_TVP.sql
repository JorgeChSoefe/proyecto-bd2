/* ============================================================
   01. TIPOS DE TABLA (TVP) — usados para enviar detalle
   de ventas, compras y recetas en una sola llamada a SP

   CREATE TYPE no admite CREATE OR ALTER ni puede envolverse en un
   IF/BEGIN/END directamente (debe ser la unica sentencia del batch) --
   por eso cada uno va en EXEC(dynamic sql) guardado por TYPE_ID(), que si
   es re-ejecutable.
   ============================================================ */

IF TYPE_ID(N'dbo.TipoDetalleVenta') IS NULL
    EXEC('CREATE TYPE dbo.TipoDetalleVenta AS TABLE
    (
        id_producto     INT             NOT NULL,
        cantidad        INT             NOT NULL,
        precio_unitario DECIMAL(18,2)   NOT NULL
    )');
GO

-- id_detalle: NULL al registrar (aun no existe la fila en detalle_compras);
-- OBLIGATORIO al recibir (sp_Compra_Recibir), para casar cada linea del TVP
-- 1:1 con su fila real de detalle_compras y no confundir lotes cuando el
-- mismo producto aparece en mas de una linea (bug B4).
IF TYPE_ID(N'dbo.TipoDetalleCompra') IS NULL
    EXEC('CREATE TYPE dbo.TipoDetalleCompra AS TABLE
    (
        id_detalle          INT             NULL,
        id_producto         INT             NOT NULL,
        cantidad            INT             NOT NULL,
        precio_unitario     DECIMAL(18,2)   NOT NULL,
        numero_lote         NVARCHAR(255)   NOT NULL,
        fecha_fabricacion   DATE            NULL,
        fecha_vencimiento   DATE            NOT NULL
    )');
GO

IF TYPE_ID(N'dbo.TipoDetalleReceta') IS NULL
    EXEC('CREATE TYPE dbo.TipoDetalleReceta AS TABLE
    (
        id_producto             INT             NOT NULL,
        cantidad_prescrita      INT             NOT NULL,
        dosis                   NVARCHAR(255)   NULL,
        duracion_tratamiento    NVARCHAR(255)   NULL
    )');
GO
