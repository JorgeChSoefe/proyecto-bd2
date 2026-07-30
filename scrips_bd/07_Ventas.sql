/* ============================================================
   07. VENTAS — el proceso transaccional mas critico
   Tablas: ventas, detalle_ventas
   ============================================================ */

-- Bug B5 (corregido en 3 partes, marcadas abajo):
--   1) Solo se validaba que existiera ALGUNA receta vigente, sin comprobar
--      que fuera del cliente correcto ni que cubriera cada producto
--      controlado/con receta con cantidad prescrita suficiente.
--   2) fn_ObtenerLoteFEFOTabla no puede tomar locks (es una funcion); dos
--      ventas concurrentes del mismo producto podian pasar la validacion de
--      stock resolviendo los mismos lotes. Se agrega un bloqueo explicito
--      (UPDLOCK, HOLDLOCK) sobre los lotes del producto ANTES de resolver FEFO.
--      Ademas la TVF se llamaba dos veces por linea (una para sumar
--      disponible, otra para iterar); ahora se materializa una sola vez.
--   3) Si el mismo producto aparecia en 2+ lineas del detalle,
--      sp_Receta_MarcarDispensada se llamaba con la cantidad PARCIAL de cada
--      linea; como cantidad_prescrita <= cantidad_vendida nunca se cumplia
--      con una cantidad parcial, la receta quedaba pendiente para siempre.
--      Ahora se llama una sola vez por producto con el TOTAL vendido en la venta.
CREATE OR ALTER PROCEDURE sp_Venta_Registrar
    @id_empleado    INT,
    @id_cliente     INT = NULL,
    @id_usuario     INT,
    @id_receta      INT = NULL,
    @detalle        dbo.TipoDetalleVenta READONLY,
    @id_venta_creada INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Totales por producto: @detalle es READONLY, se calcula una vez y se
    -- reutiliza tanto en las validaciones de receta como al cerrar la venta.
    DECLARE @totales_por_producto TABLE (id_producto INT PRIMARY KEY, cantidad_total INT);
    INSERT INTO @totales_por_producto (id_producto, cantidad_total)
    SELECT id_producto, SUM(cantidad) FROM @detalle GROUP BY id_producto;

    -- ---- Validaciones previas (fuera de la transaccion principal) ----
    IF @id_receta IS NOT NULL AND dbo.fn_RecetaVigente(@id_receta) = 0
        THROW 50050, 'La receta no existe o esta vencida.', 1;

    -- Si algun producto requiere receta/controlado, exigir @id_receta
    IF EXISTS (
        SELECT 1
        FROM @detalle d
        INNER JOIN productos p ON p.id_producto = d.id_producto
        LEFT JOIN medicamentos m ON m.id_producto = p.id_producto
        WHERE (p.requiere_receta = 1 OR m.controlado = 1)
    ) AND @id_receta IS NULL
        THROW 50051, 'Uno o mas productos requieren receta medica vigente.', 1;

    IF @id_receta IS NOT NULL
    BEGIN
        DECLARE @id_cliente_receta INT;
        SELECT @id_cliente_receta = id_cliente FROM recetas WHERE id_receta = @id_receta;

        IF @id_cliente IS NOT NULL AND @id_cliente_receta <> @id_cliente
            THROW 50055, 'La receta no pertenece al cliente indicado.', 1;

        IF EXISTS (
            SELECT 1
            FROM @totales_por_producto t
            INNER JOIN productos p ON p.id_producto = t.id_producto
            LEFT JOIN medicamentos m ON m.id_producto = p.id_producto
            LEFT JOIN (
                SELECT id_producto, SUM(cantidad_prescrita) AS cantidad_prescrita_total
                FROM detalle_recetas WHERE id_receta = @id_receta
                GROUP BY id_producto
            ) dr ON dr.id_producto = t.id_producto
            WHERE (p.requiere_receta = 1 OR m.controlado = 1)
              AND (dr.id_producto IS NULL OR dr.cantidad_prescrita_total < t.cantidad_total)
        )
            THROW 50056, 'La receta no cubre alguno de los productos controlados/con receta requerida en la cantidad solicitada.', 1;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @total DECIMAL(18,2) =
            (SELECT SUM(cantidad * precio_unitario) FROM @detalle);

        INSERT INTO ventas (fecha_venta, total, estado, id_empleado, id_cliente, id_usuario, id_receta)
        VALUES (GETDATE(), @total, 'pendiente', @id_empleado, @id_cliente, @id_usuario, @id_receta);

        SET @id_venta_creada = SCOPE_IDENTITY();

        -- ---- Recorrer cada linea del detalle ----
        DECLARE @id_producto INT, @cantidad INT, @precio_unitario DECIMAL(18,2);

        -- Bug (encontrado durante el smoke test, confirmado empiricamente
        -- contra SQL Server real): un DECLARE dentro de un WHILE NO reinicia
        -- la variable en cada vuelta -- ni escalares ni de tabla. Re-ejecutar
        -- "DECLARE @lotes_fefo TABLE(...)" dentro del loop es un NO-OP en la
        -- 2a vuelta en adelante: las filas de la linea anterior seguian ahi,
        -- se sumaban a las del producto actual y detalle_ventas/kardex
        -- terminaban con lotes de OTRO producto mezclados. Por eso se declara
        -- UNA vez aqui afuera y se vacia con DELETE al tope de cada vuelta.
        DECLARE @lotes_fefo TABLE (id_lote INT, cantidad_a_tomar INT, costo_unitario_lote DECIMAL(18,2));

        DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
            SELECT id_producto, cantidad, precio_unitario FROM @detalle;

        OPEN cur;
        FETCH NEXT FROM cur INTO @id_producto, @cantidad, @precio_unitario;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Bloqueo preventivo: retiene locks U sobre los lotes activos de
            -- este producto hasta el COMMIT, serializando ventas concurrentes
            -- del mismo producto para que no resuelvan FEFO sobre el mismo
            -- stock "libre".
            DECLARE @lock_dummy INT;
            SELECT @lock_dummy = id_lote FROM lotes WITH (UPDLOCK, HOLDLOCK)
            WHERE id_producto = @id_producto AND activo = 1;

            DELETE FROM @lotes_fefo;
            INSERT INTO @lotes_fefo (id_lote, cantidad_a_tomar, costo_unitario_lote)
            SELECT id_lote, cantidad_a_tomar, costo_unitario_lote
            FROM dbo.fn_ObtenerLoteFEFOTabla(@id_producto, @cantidad);

            DECLARE @cantidad_resuelta INT;
            SELECT @cantidad_resuelta = ISNULL(SUM(cantidad_a_tomar), 0) FROM @lotes_fefo;

            IF @cantidad_resuelta < @cantidad
            BEGIN
                DECLARE @msg NVARCHAR(400) =
                    CONCAT('Stock insuficiente para el producto id=', @id_producto,
                           ' (solicitado ', @cantidad, ', disponible ', @cantidad_resuelta, ').');
                THROW 50052, @msg, 1;
            END

            -- Una fila de detalle_ventas por cada lote FEFO afectado
            INSERT INTO detalle_ventas (cantidad, precio_unitario, subtotal, id_venta, id_producto, id_lote)
            SELECT cantidad_a_tomar, @precio_unitario, cantidad_a_tomar * @precio_unitario,
                   @id_venta_creada, @id_producto, id_lote
            FROM @lotes_fefo;

            -- Un EXEC de kardex por lote afectado (tipicamente 1-2 filas por linea)
            DECLARE @id_lote INT, @cant_tomar INT, @costo_lote DECIMAL(18,2);
            DECLARE cur_lotes CURSOR LOCAL FAST_FORWARD FOR
                SELECT id_lote, cantidad_a_tomar, costo_unitario_lote FROM @lotes_fefo;

            OPEN cur_lotes;
            FETCH NEXT FROM cur_lotes INTO @id_lote, @cant_tomar, @costo_lote;

            WHILE @@FETCH_STATUS = 0
            BEGIN
                DECLARE @id_mov INT;
                EXEC sp_Kardex_RegistrarMovimiento
                    @tipo_movimiento = 'salida',
                    @id_producto = @id_producto,
                    @id_lote = @id_lote,
                    @cantidad_entrada = 0,
                    @cantidad_salida = @cant_tomar,
                    @costo_unitario = @costo_lote,
                    @referencia_doc = 'venta',
                    @id_referencia_doc = @id_venta_creada,
                    @id_usuario = @id_usuario,
                    @id_movimiento_creado = @id_mov OUTPUT;

                FETCH NEXT FROM cur_lotes INTO @id_lote, @cant_tomar, @costo_lote;
            END
            CLOSE cur_lotes;
            DEALLOCATE cur_lotes;

            FETCH NEXT FROM cur INTO @id_producto, @cantidad, @precio_unitario;
        END
        CLOSE cur;
        DEALLOCATE cur;

        -- Marcar receta dispensada UNA VEZ por producto, con el total vendido
        -- en esta venta (ver nota B5-3 arriba).
        IF @id_receta IS NOT NULL
        BEGIN
            DECLARE @id_producto_disp INT, @cantidad_disp INT;
            DECLARE cur_disp CURSOR LOCAL FAST_FORWARD FOR
                SELECT id_producto, cantidad_total FROM @totales_por_producto;

            OPEN cur_disp;
            FETCH NEXT FROM cur_disp INTO @id_producto_disp, @cantidad_disp;
            WHILE @@FETCH_STATUS = 0
            BEGIN
                EXEC sp_Receta_MarcarDispensada
                    @id_receta = @id_receta, @id_producto = @id_producto_disp,
                    @cantidad_vendida = @cantidad_disp;
                FETCH NEXT FROM cur_disp INTO @id_producto_disp, @cantidad_disp;
            END
            CLOSE cur_disp;
            DEALLOCATE cur_disp;
        END

        UPDATE ventas SET estado = 'completada' WHERE id_venta = @id_venta_creada;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

-- ---------- Anular venta (reversa de stock) ----------
-- Bug B3 (corregido): se pasaba dv.precio_unitario (precio de VENTA) como
-- costo del movimiento de reversa 'entrada', inflando precio_promedio_pond al
-- precio de venta cada vez que se anulaba algo. Ahora se recupera el
-- costo_unitario ORIGINAL desde el kardex de salida que genero esta misma
-- venta, pareando cada fila de detalle_ventas con su fila de kardex 1:1 por
-- (producto, lote, orden de insercion) -- ambas se insertan en el mismo orden
-- dentro de sp_Venta_Registrar, asi que ROW_NUMBER() las empareja aunque el
-- mismo producto+lote se repita en mas de una linea original.
-- Tambien agrega la ventana de dias para anular (spec 3.6) y revierte la
-- dispensacion de receta si esta venta la cubria.
CREATE OR ALTER PROCEDURE sp_Venta_Anular
    @id_venta           INT,
    @id_usuario         INT,
    @dias_max_anulacion INT = 3
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @estado NVARCHAR(255), @fecha_venta DATETIME2(0), @id_receta INT;
    SELECT @estado = estado, @fecha_venta = fecha_venta, @id_receta = id_receta
    FROM ventas WHERE id_venta = @id_venta;

    IF @estado IS NULL
        THROW 50053, 'La venta no existe.', 1;
    IF @estado = 'anulada'
        THROW 50054, 'La venta ya esta anulada.', 1;
    IF DATEDIFF(DAY, @fecha_venta, GETDATE()) > @dias_max_anulacion
        THROW 50057, 'La venta ya no se puede anular: supera la ventana de dias permitida.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @id_detalle INT, @id_producto INT, @id_lote INT, @cantidad INT, @costo DECIMAL(18,2);

        DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
            WITH dv_num AS (
                SELECT dv.id_detalle, dv.id_producto, dv.id_lote, dv.cantidad,
                       ROW_NUMBER() OVER (PARTITION BY dv.id_producto, dv.id_lote ORDER BY dv.id_detalle) AS rn
                FROM detalle_ventas dv
                WHERE dv.id_venta = @id_venta
            ),
            kx_num AS (
                SELECT k.id_movimiento, k.id_producto, k.id_lote, k.costo_unitario,
                       ROW_NUMBER() OVER (PARTITION BY k.id_producto, k.id_lote ORDER BY k.id_movimiento) AS rn
                FROM kardex k
                WHERE k.referencia_doc = 'venta' AND k.id_referencia_doc = @id_venta AND k.tipo_movimiento = 'salida'
            )
            SELECT dv.id_detalle, dv.id_producto, dv.id_lote, dv.cantidad, kx.costo_unitario
            FROM dv_num dv
            INNER JOIN kx_num kx
                ON kx.id_producto = dv.id_producto AND kx.id_lote = dv.id_lote AND kx.rn = dv.rn;

        OPEN cur;
        FETCH NEXT FROM cur INTO @id_detalle, @id_producto, @id_lote, @cantidad, @costo;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            DECLARE @id_mov INT;
            -- Reversa: regresa el stock como 'entrada' referenciando la venta anulada
            EXEC sp_Kardex_RegistrarMovimiento
                @tipo_movimiento = 'entrada',
                @id_producto = @id_producto,
                @id_lote = @id_lote,
                @cantidad_entrada = @cantidad,
                @cantidad_salida = 0,
                @costo_unitario = @costo,
                @referencia_doc = 'venta_anulada',
                @id_referencia_doc = @id_venta,
                @id_usuario = @id_usuario,
                @id_movimiento_creado = @id_mov OUTPUT;

            FETCH NEXT FROM cur INTO @id_detalle, @id_producto, @id_lote, @cantidad, @costo;
        END
        CLOSE cur;
        DEALLOCATE cur;

        UPDATE ventas SET estado = 'anulada' WHERE id_venta = @id_venta;

        IF @id_receta IS NOT NULL
        BEGIN
            UPDATE detalle_recetas SET dispensada = 0
            WHERE id_receta = @id_receta
              AND id_producto IN (SELECT id_producto FROM detalle_ventas WHERE id_venta = @id_venta);

            UPDATE recetas SET dispensada = 0 WHERE id_receta = @id_receta;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE sp_Venta_ObtenerPorId
    @id_venta INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM ventas WHERE id_venta = @id_venta;

    SELECT dv.*, p.nombre AS nombre_producto, l.numero_lote
    FROM detalle_ventas dv
    INNER JOIN productos p ON p.id_producto = dv.id_producto
    LEFT JOIN lotes l      ON l.id_lote = dv.id_lote
    WHERE dv.id_venta = @id_venta;
END
GO

CREATE OR ALTER VIEW vw_Ventas
AS
    SELECT
        v.id_venta, v.fecha_venta, v.total, v.estado,
        e.nombre_completo AS nombre_empleado, c.nombre_completo AS nombre_cliente,
        u.nombre_usuario, v.id_receta
    FROM ventas v
    LEFT JOIN empleados e ON e.id_empleado = v.id_empleado
    LEFT JOIN clientes c  ON c.id_cliente = v.id_cliente
    LEFT JOIN usuarios u  ON u.id_usuario = v.id_usuario;
GO

CREATE OR ALTER PROCEDURE sp_Venta_Listar
    @pagina         INT = 1,
    @tamano         INT = 50,
    @estado         NVARCHAR(255) = NULL,
    @fecha_desde    DATE = NULL,
    @fecha_hasta    DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @pagina < 1 SET @pagina = 1;
    IF @tamano < 1 SET @tamano = 50;

    SELECT * FROM vw_Ventas
    WHERE (@estado IS NULL OR estado = @estado)
      AND (@fecha_desde IS NULL OR fecha_venta >= @fecha_desde)
      AND (@fecha_hasta IS NULL OR fecha_venta < DATEADD(DAY, 1, @fecha_hasta))
    ORDER BY fecha_venta DESC
    OFFSET (@pagina - 1) * @tamano ROWS FETCH NEXT @tamano ROWS ONLY;

    SELECT COUNT(*) AS total FROM vw_Ventas
    WHERE (@estado IS NULL OR estado = @estado)
      AND (@fecha_desde IS NULL OR fecha_venta >= @fecha_desde)
      AND (@fecha_hasta IS NULL OR fecha_venta < DATEADD(DAY, 1, @fecha_hasta));
END
GO

CREATE OR ALTER VIEW vw_VentasDetalladas
AS
    SELECT
        v.id_venta, v.fecha_venta, v.estado,
        dv.id_detalle, dv.cantidad, dv.precio_unitario, dv.subtotal,
        p.id_producto, p.nombre AS nombre_producto, l.numero_lote
    FROM ventas v
    INNER JOIN detalle_ventas dv ON dv.id_venta = v.id_venta
    INNER JOIN productos p       ON p.id_producto = dv.id_producto
    LEFT JOIN lotes l            ON l.id_lote = dv.id_lote;
GO
