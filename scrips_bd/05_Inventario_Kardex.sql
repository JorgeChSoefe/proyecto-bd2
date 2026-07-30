/* ============================================================
   05. INVENTARIO — nucleo del sistema
   Tablas: lotes, kardex, alertas_stock
   ============================================================ */

-- ---------- FEFO: resuelve que lote(s) descontar ----------
-- Bug B6 (corregido): la version original recorria los lotes con un CURSOR.
-- Reescrita como TVF inline (una sola sentencia) con suma acumulada por
-- ventana -- mejor plan, sargable contra IX_lotes_fefo, sin estado de cursor.
-- Devuelve, para el producto y cantidad solicitados, las lineas de lote
-- a descontar ordenadas por fecha_vencimiento ASC (First-Expired-First-Out).
-- Nota de concurrencia: esta funcion NO toma locks (las TVF no pueden). El
-- llamador (sp_Venta_Registrar) es responsable de bloquear los lotes del
-- producto ANTES de invocarla -- ver bug B5 en 07_Ventas.sql.
CREATE OR ALTER FUNCTION fn_ObtenerLoteFEFOTabla (@id_producto INT, @cantidad_requerida INT)
RETURNS TABLE
AS
RETURN
(
    SELECT
        id_lote,
        CAST(CASE
                WHEN acumulado_previo + cantidad_actual <= @cantidad_requerida THEN cantidad_actual
                ELSE @cantidad_requerida - acumulado_previo
             END AS INT) AS cantidad_a_tomar,
        costo_unitario_lote
    FROM (
        SELECT
            id_lote,
            cantidad_actual,
            precio_costo_lote AS costo_unitario_lote,
            SUM(cantidad_actual) OVER (ORDER BY fecha_vencimiento ASC, id_lote ASC
                                        ROWS UNBOUNDED PRECEDING) - cantidad_actual AS acumulado_previo
        FROM lotes
        WHERE id_producto = @id_producto
          AND activo = 1
          AND cantidad_actual > 0
    ) t
    WHERE acumulado_previo < @cantidad_requerida
);
GO

-- Lotes disponibles de un producto -- lo usa el frontend para el selector de
-- lote en el ajuste manual (antes no habia forma limpia de listar lotes por
-- producto, habia que inferirlos leyendo el kardex).
CREATE OR ALTER PROCEDURE sp_Lote_ListarPorProducto
    @id_producto INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT id_lote, numero_lote, fecha_vencimiento, cantidad_actual
    FROM lotes
    WHERE id_producto = @id_producto
      AND activo = 1
      AND cantidad_actual > 0
    ORDER BY fecha_vencimiento ASC;
END
GO

-- ---------- Costo promedio ponderado ----------
CREATE OR ALTER FUNCTION fn_CalcularPrecioPromedioPonderado
(
    @saldo_stock_actual     INT,
    @saldo_valorado_actual  DECIMAL(18,2),
    @cantidad_entrada       INT,
    @costo_entrada_unitario DECIMAL(18,2)
)
RETURNS DECIMAL(18,4)
AS
BEGIN
    DECLARE @nuevo_stock INT = @saldo_stock_actual + @cantidad_entrada;
    IF @nuevo_stock <= 0
        RETURN @costo_entrada_unitario;

    RETURN ( (@saldo_valorado_actual + (@cantidad_entrada * @costo_entrada_unitario))
             / @nuevo_stock );
END
GO

-- ---------- Movimiento de kardex (llamado internamente por ventas/compras/ajustes) ----------
-- Bug B1 (corregido): antes ramificaba por @tipo_movimiento = 'entrada' vs
-- ELSE; un 'ajuste' positivo (+cantidad) caia en la rama ELSE (salida) y
-- @nuevo_saldo_stock quedaba igual al previo -- el ajuste manual nunca subia
-- el stock. Ahora ramifica por cual de @cantidad_entrada/@cantidad_salida
-- viene con valor, que es lo que realmente determina el signo del movimiento.
--
-- Bug B2 (corregido): la lectura de stock_actual/precio_promedio_pond se
-- hacia ANTES de BEGIN TRANSACTION y sin locks -- dos movimientos concurrentes
-- del mismo producto leian el mismo saldo previo y el segundo UPDATE pisaba
-- al primero. Ademas el SP siempre abria su propia transaccion aunque el
-- llamador (sp_Venta_Registrar/sp_Compra_Recibir) ya tuviera una abierta; si
-- fallaba aqui adentro, su ROLLBACK mataba la transaccion del padre entero.
-- Ahora: la lectura del saldo va WITH (UPDLOCK, HOLDLOCK) dentro de la
-- transaccion, y solo abre/cierra su propia transaccion si @@TRANCOUNT = 0
-- al entrar (respeta la transaccion del llamador si ya existe una).
CREATE OR ALTER PROCEDURE sp_Kardex_RegistrarMovimiento
    @tipo_movimiento    NVARCHAR(255),   -- 'entrada' | 'salida' | 'ajuste'
    @id_producto        INT,
    @id_lote            INT = NULL,
    @cantidad_entrada   INT = 0,
    @cantidad_salida    INT = 0,
    @costo_unitario     DECIMAL(18,2) = NULL,
    @referencia_doc     NVARCHAR(255) = NULL,   -- 'venta' | 'compra' | 'ajuste'
    @id_referencia_doc  INT = NULL,
    @id_usuario         INT,
    @observaciones      NVARCHAR(500) = NULL,
    @id_movimiento_creado INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @tipo_movimiento NOT IN ('entrada','salida','ajuste')
        THROW 50030, 'Tipo de movimiento invalido.', 1;

    IF NOT ( (@cantidad_entrada > 0 AND @cantidad_salida = 0)
          OR (@cantidad_salida > 0 AND @cantidad_entrada = 0) )
        THROW 50033, 'Debe indicar cantidad_entrada o cantidad_salida (exactamente una, mayor a cero).', 1;

    DECLARE @tran_propia BIT = 0;
    IF @@TRANCOUNT = 0
        SET @tran_propia = 1;

    BEGIN TRY
        IF @tran_propia = 1 BEGIN TRANSACTION;

        DECLARE @stock_actual_prev INT, @saldo_valorado_prev DECIMAL(18,2), @ppp_prev DECIMAL(18,4);

        SELECT @stock_actual_prev = stock_actual, @ppp_prev = precio_promedio_pond
        FROM productos WITH (UPDLOCK, HOLDLOCK)
        WHERE id_producto = @id_producto;

        IF @stock_actual_prev IS NULL
            THROW 50031, 'Producto no existe.', 1;

        SET @saldo_valorado_prev = @stock_actual_prev * ISNULL(@ppp_prev, 0);

        DECLARE @nuevo_saldo_stock INT;
        DECLARE @nuevo_ppp DECIMAL(18,4) = @ppp_prev;
        DECLARE @costo_total_mov DECIMAL(18,2);
        DECLARE @nuevo_saldo_valorado DECIMAL(18,2);

        IF @cantidad_entrada > 0
        BEGIN
            SET @nuevo_saldo_stock = @stock_actual_prev + @cantidad_entrada;
            SET @nuevo_ppp = dbo.fn_CalcularPrecioPromedioPonderado(
                                @stock_actual_prev, @saldo_valorado_prev, @cantidad_entrada, @costo_unitario);
            SET @costo_total_mov = @cantidad_entrada * @costo_unitario;
        END
        ELSE -- cantidad_salida > 0: 'salida' o 'ajuste' negativo se manejan igual
        BEGIN
            IF @stock_actual_prev < @cantidad_salida
                THROW 50032, 'Stock insuficiente para el movimiento.', 1;

            SET @nuevo_saldo_stock = @stock_actual_prev - @cantidad_salida;
            SET @nuevo_ppp = @ppp_prev; -- una salida no recalcula el promedio
            SET @costo_total_mov = @cantidad_salida * ISNULL(@ppp_prev, 0);
        END

        SET @nuevo_saldo_valorado = @nuevo_saldo_stock * ISNULL(@nuevo_ppp, 0);

        INSERT INTO kardex
            (fecha_movimiento, tipo_movimiento, referencia_doc, id_referencia_doc,
             cantidad_entrada, cantidad_salida, saldo_stock, costo_unitario,
             costo_total_mov, precio_promedio_pond, saldo_valorado,
             id_producto, id_lote, id_usuario, observaciones)
        VALUES
            (GETDATE(), @tipo_movimiento, @referencia_doc, @id_referencia_doc,
             @cantidad_entrada, @cantidad_salida, @nuevo_saldo_stock, @costo_unitario,
             @costo_total_mov, @nuevo_ppp, @nuevo_saldo_valorado,
             @id_producto, @id_lote, @id_usuario, @observaciones);

        SET @id_movimiento_creado = SCOPE_IDENTITY();

        UPDATE productos
           SET stock_actual = @nuevo_saldo_stock,
               precio_promedio_pond = @nuevo_ppp
         WHERE id_producto = @id_producto;

        -- Si el movimiento afecta un lote especifico, actualizar su cantidad_actual
        IF @id_lote IS NOT NULL
        BEGIN
            IF @cantidad_entrada > 0
                UPDATE lotes SET cantidad_actual = cantidad_actual + @cantidad_entrada WHERE id_lote = @id_lote;
            ELSE
                UPDATE lotes SET cantidad_actual = cantidad_actual - @cantidad_salida WHERE id_lote = @id_lote;
        END

        IF @tran_propia = 1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @tran_propia = 1 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

-- ---------- Ajuste manual (mermas, conteos fisicos) ----------
-- Bug B1 (corregido, ver arriba): un @cantidad positivo ahora si sube el stock.
-- @motivo ya no se descarta: viaja como @observaciones hasta kardex.observaciones
-- (columna agregada en 10_Schema_Tablas.sql) para que la merma/conteo quede auditable.
CREATE OR ALTER PROCEDURE sp_Inventario_AjusteManual
    @id_producto    INT,
    @id_lote        INT = NULL,
    @cantidad       INT,             -- positivo = entrada, negativo = salida
    @motivo         NVARCHAR(MAX),
    @id_usuario     INT,
    @id_movimiento_creado INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF @cantidad = 0
        THROW 50034, 'La cantidad del ajuste no puede ser cero.', 1;

    DECLARE @entrada INT = 0, @salida INT = 0, @costo DECIMAL(18,2);

    SELECT @costo = precio_promedio_pond FROM productos WHERE id_producto = @id_producto;

    IF @cantidad > 0
        SET @entrada = @cantidad;
    ELSE
        SET @salida = ABS(@cantidad);

    EXEC sp_Kardex_RegistrarMovimiento
        @tipo_movimiento = 'ajuste',
        @id_producto = @id_producto,
        @id_lote = @id_lote,
        @cantidad_entrada = @entrada,
        @cantidad_salida = @salida,
        @costo_unitario = @costo,
        @referencia_doc = 'ajuste',
        @id_referencia_doc = NULL,
        @id_usuario = @id_usuario,
        @observaciones = @motivo,
        @id_movimiento_creado = @id_movimiento_creado OUTPUT;
END
GO

-- ---------- Vistas de inventario ----------
CREATE OR ALTER VIEW vw_StockActual
AS
    SELECT
        p.id_producto, p.nombre, p.codigo_sku, p.stock_actual, p.stock_minimo,
        p.precio_promedio_pond,
        CASE WHEN p.stock_actual <= p.stock_minimo THEN 1 ELSE 0 END AS bajo_stock_minimo
    FROM productos p;
GO

CREATE OR ALTER PROCEDURE sp_Inventario_StockActual_Listar
    @pagina             INT = 1,
    @tamano             INT = 50,
    @busqueda           NVARCHAR(255) = NULL,
    @solo_bajo_minimo   BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    IF @pagina < 1 SET @pagina = 1;
    IF @tamano < 1 SET @tamano = 50;

    SELECT * FROM vw_StockActual
    WHERE (@busqueda IS NULL OR nombre LIKE '%' + @busqueda + '%' OR codigo_sku LIKE '%' + @busqueda + '%')
      AND (@solo_bajo_minimo = 0 OR bajo_stock_minimo = 1)
    ORDER BY nombre
    OFFSET (@pagina - 1) * @tamano ROWS FETCH NEXT @tamano ROWS ONLY;

    SELECT COUNT(*) AS total FROM vw_StockActual
    WHERE (@busqueda IS NULL OR nombre LIKE '%' + @busqueda + '%' OR codigo_sku LIKE '%' + @busqueda + '%')
      AND (@solo_bajo_minimo = 0 OR bajo_stock_minimo = 1);
END
GO

-- Bug B7 (corregido): la vista no filtraba por dias, dejando el comentario
-- "el WHERE lo hace la API" -- eso obliga a la API a escribir SQL ad-hoc
-- contra la vista, violando la regla de oro del proyecto. Ahora el filtro
-- vive en este SP.
CREATE OR ALTER VIEW vw_ProductosPorVencer
AS
    SELECT
        l.id_lote, l.numero_lote, l.fecha_vencimiento, l.cantidad_actual,
        p.id_producto, p.nombre, p.codigo_sku,
        DATEDIFF(DAY, GETDATE(), l.fecha_vencimiento) AS dias_para_vencer
    FROM lotes l
    INNER JOIN productos p ON p.id_producto = l.id_producto
    WHERE l.activo = 1 AND l.cantidad_actual > 0;
GO

CREATE OR ALTER PROCEDURE sp_Inventario_ProductosPorVencer
    @dias INT = 30
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM vw_ProductosPorVencer
    WHERE dias_para_vencer <= @dias
    ORDER BY dias_para_vencer ASC;
END
GO

CREATE OR ALTER VIEW vw_KardexProducto
AS
    SELECT
        k.id_movimiento, k.fecha_movimiento, k.tipo_movimiento, k.referencia_doc,
        k.id_referencia_doc, k.cantidad_entrada, k.cantidad_salida, k.saldo_stock,
        k.costo_unitario, k.costo_total_mov, k.precio_promedio_pond, k.saldo_valorado,
        k.id_producto, k.id_lote, k.id_usuario, u.nombre_usuario, k.observaciones
    FROM kardex k
    LEFT JOIN usuarios u ON u.id_usuario = k.id_usuario;
GO

CREATE OR ALTER PROCEDURE sp_Kardex_ListarPorProducto
    @id_producto    INT,
    @pagina         INT = 1,
    @tamano         INT = 50
AS
BEGIN
    SET NOCOUNT ON;
    IF @pagina < 1 SET @pagina = 1;
    IF @tamano < 1 SET @tamano = 50;

    SELECT * FROM vw_KardexProducto
    WHERE id_producto = @id_producto
    ORDER BY fecha_movimiento DESC, id_movimiento DESC
    OFFSET (@pagina - 1) * @tamano ROWS FETCH NEXT @tamano ROWS ONLY;

    SELECT COUNT(*) AS total FROM vw_KardexProducto WHERE id_producto = @id_producto;
END
GO

-- ---------- Alertas ----------
CREATE OR ALTER PROCEDURE sp_Alerta_GenerarPorStockMinimo
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO alertas_stock (tipo_alerta, id_producto, mensaje, fecha_alerta, resuelta)
    SELECT
        'stock_minimo', p.id_producto,
        CONCAT('Stock actual (', p.stock_actual, ') por debajo del minimo (', p.stock_minimo, ') para ', p.nombre),
        GETDATE(), 0
    FROM productos p
    WHERE p.stock_actual <= p.stock_minimo
      AND NOT EXISTS (
            SELECT 1 FROM alertas_stock a
            WHERE a.id_producto = p.id_producto
              AND a.tipo_alerta = 'stock_minimo'
              AND a.resuelta = 0
      );
END
GO

CREATE OR ALTER PROCEDURE sp_Alerta_GenerarPorVencimiento
    @dias_anticipacion INT = 30
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO alertas_stock (tipo_alerta, id_producto, id_lote, mensaje, fecha_alerta, resuelta)
    SELECT
        'vencimiento_proximo', l.id_producto, l.id_lote,
        CONCAT('Lote ', l.numero_lote, ' vence el ', CONVERT(VARCHAR, l.fecha_vencimiento, 103)),
        GETDATE(), 0
    FROM lotes l
    WHERE l.activo = 1 AND l.cantidad_actual > 0
      AND DATEDIFF(DAY, GETDATE(), l.fecha_vencimiento) <= @dias_anticipacion
      AND NOT EXISTS (
            SELECT 1 FROM alertas_stock a
            WHERE a.id_lote = l.id_lote
              AND a.tipo_alerta = 'vencimiento_proximo'
              AND a.resuelta = 0
      );
END
GO

CREATE OR ALTER PROCEDURE sp_Alerta_Resolver
    @id_alerta          INT,
    @id_usuario_resolucion INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE alertas_stock
       SET resuelta = 1, fecha_resolucion = GETDATE(), id_usuario_resolucion = @id_usuario_resolucion
     WHERE id_alerta = @id_alerta;
END
GO

CREATE OR ALTER VIEW vw_AlertasActivas
AS
    SELECT a.*, p.nombre AS nombre_producto
    FROM alertas_stock a
    LEFT JOIN productos p ON p.id_producto = a.id_producto
    WHERE a.resuelta = 0;
GO

CREATE OR ALTER PROCEDURE sp_Alerta_Listar
    @pagina         INT = 1,
    @tamano         INT = 50,
    @tipo_alerta    NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @pagina < 1 SET @pagina = 1;
    IF @tamano < 1 SET @tamano = 50;

    SELECT * FROM vw_AlertasActivas
    WHERE @tipo_alerta IS NULL OR tipo_alerta = @tipo_alerta
    ORDER BY fecha_alerta DESC
    OFFSET (@pagina - 1) * @tamano ROWS FETCH NEXT @tamano ROWS ONLY;

    SELECT COUNT(*) AS total FROM vw_AlertasActivas
    WHERE @tipo_alerta IS NULL OR tipo_alerta = @tipo_alerta;
END
GO
