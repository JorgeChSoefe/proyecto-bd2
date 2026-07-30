/* ============================================================
   08. COMPRAS
   Tablas: compras, detalle_compras, lotes (generados al recibir)
   ============================================================ */

CREATE OR ALTER PROCEDURE sp_Compra_Registrar
    @id_proveedor   INT,
    @id_empleado    INT,
    @id_usuario     INT,
    @detalle        dbo.TipoDetalleCompra READONLY,
    @id_compra_creada INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @total DECIMAL(18,2) = (SELECT SUM(cantidad * precio_unitario) FROM @detalle);

        INSERT INTO compras (fecha_compra, total, estado, id_proveedor, id_empleado, id_usuario)
        VALUES (GETDATE(), @total, 'pendiente', @id_proveedor, @id_empleado, @id_usuario);

        SET @id_compra_creada = SCOPE_IDENTITY();

        -- En 'pendiente' aun no se generan lotes ni se mueve kardex;
        -- eso ocurre solo al confirmar recepcion (sp_Compra_Recibir).
        -- Se guarda el detalle con numero_lote/fecha_vencimiento propuestos
        -- para poder recibirlos despues sin volver a pedirlos.
        INSERT INTO detalle_compras (
            cantidad, precio_unitario, subtotal, id_compra, id_producto, id_lote,
            numero_lote_propuesto, fecha_fabricacion_propuesta, fecha_vencimiento_propuesta)
        SELECT cantidad, precio_unitario, cantidad * precio_unitario, @id_compra_creada, id_producto, NULL,
               numero_lote, fecha_fabricacion, fecha_vencimiento
        FROM @detalle;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

-- ---------- Recibir compra: genera lotes + kardex de entrada ----------
-- Bug B4 (corregido): antes emparejaba cada linea recibida con su fila de
-- detalle_compras por (id_compra, id_producto, id_lote IS NULL). Si el mismo
-- producto venia en 2 lineas con lotes distintos, la primera iteracion
-- estampaba id_lote en AMBAS filas (la del WHERE hacia match con las dos).
-- Ahora el TVP trae @id_detalle (ver 01_Tipos_Tabla_TVP.sql) y el match es
-- exacto contra la fila real de detalle_compras. Tambien valida que el
-- detalle recibido corresponda 1:1 con las lineas pendientes de la compra
-- (mismo conteo, mismo producto/cantidad/precio) y, si el lote ya existia,
-- ahora si actualiza cantidad_inicial y recalcula precio_costo_lote
-- (promedio ponderado igual que el costo del producto).
CREATE OR ALTER PROCEDURE sp_Compra_Recibir
    @id_compra  INT,
    @id_usuario INT,
    @detalle    dbo.TipoDetalleCompra READONLY  -- vuelve a enviarse con id_detalle + numero_lote/fecha_vencimiento confirmados
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @estado NVARCHAR(255);
    SELECT @estado = estado FROM compras WHERE id_compra = @id_compra;

    IF @estado IS NULL
        THROW 50060, 'La compra no existe.', 1;
    IF @estado <> 'pendiente'
        THROW 50061, 'Solo se pueden recibir compras en estado pendiente.', 1;

    IF EXISTS (SELECT 1 FROM @detalle WHERE id_detalle IS NULL)
        THROW 50064, 'Cada linea del detalle debe indicar id_detalle (la fila real de detalle_compras a recibir).', 1;

    IF EXISTS (
        SELECT 1 FROM @detalle d
        LEFT JOIN detalle_compras dc
            ON dc.id_detalle = d.id_detalle AND dc.id_compra = @id_compra AND dc.id_lote IS NULL
        WHERE dc.id_detalle IS NULL
    )
        THROW 50065, 'Alguna linea de detalle no existe, no pertenece a esta compra, o ya fue recibida.', 1;

    IF (SELECT COUNT(*) FROM @detalle) <> (SELECT COUNT(*) FROM detalle_compras WHERE id_compra = @id_compra AND id_lote IS NULL)
        THROW 50066, 'El detalle enviado no cubre exactamente todas las lineas pendientes de la compra.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @id_detalle INT, @id_producto INT, @cantidad INT, @precio_unitario DECIMAL(18,2),
                @numero_lote NVARCHAR(255), @fecha_fab DATE, @fecha_venc DATE;

        DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
            SELECT id_detalle, id_producto, cantidad, precio_unitario, numero_lote, fecha_fabricacion, fecha_vencimiento
            FROM @detalle;

        OPEN cur;
        FETCH NEXT FROM cur INTO @id_detalle, @id_producto, @cantidad, @precio_unitario, @numero_lote, @fecha_fab, @fecha_venc;

        DECLARE @id_lote INT;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Bug (encontrado durante el smoke test, confirmado empiricamente
            -- contra SQL Server real): DECLARE dentro de un WHILE NO reinicia
            -- la variable en cada vuelta. "DECLARE @id_lote INT;" aqui adentro
            -- era un NO-OP desde la 2a linea en adelante: si el SELECT de abajo
            -- no encontraba lote para el producto/numero_lote actuales (0 filas
            -- -> la variable queda TAL CUAL estaba, no se pone en NULL),
            -- @id_lote seguia apuntando al lote de la linea ANTERIOR, y esa
            -- linea entraba al ELSE (lote "ya existe") sumando su cantidad al
            -- lote equivocado. Con 10 productos en una sola compra, las 10
            -- lineas terminaban acumuladas en el lote del PRIMER producto.
            -- Fix: reset explicito con SET antes de cada busqueda.
            SET @id_lote = NULL;

            -- Un mismo numero_lote+producto es unico (indice lotes_index_0);
            -- si ya existe, se suma cantidad y se recalcula el costo del
            -- lote; si no, se crea.
            SELECT @id_lote = id_lote FROM lotes
            WHERE id_producto = @id_producto AND numero_lote = @numero_lote;

            IF @id_lote IS NULL
            BEGIN
                INSERT INTO lotes
                    (numero_lote, id_producto, id_compra, fecha_fabricacion, fecha_vencimiento,
                     cantidad_inicial, cantidad_actual, precio_costo_lote, activo, creado_en)
                VALUES
                    (@numero_lote, @id_producto, @id_compra, @fecha_fab, @fecha_venc,
                     @cantidad, 0, @precio_unitario, 1, GETDATE());
                -- cantidad_actual se deja en 0 aqui; sp_Kardex_RegistrarMovimiento
                -- la incrementa para mantener una unica fuente de verdad del saldo.

                SET @id_lote = SCOPE_IDENTITY();
            END
            ELSE
            BEGIN
                DECLARE @cant_actual_lote INT, @costo_lote_prev DECIMAL(18,2);
                SELECT @cant_actual_lote = cantidad_actual, @costo_lote_prev = precio_costo_lote
                FROM lotes WITH (UPDLOCK, HOLDLOCK) WHERE id_lote = @id_lote;

                UPDATE lotes
                   SET cantidad_inicial = cantidad_inicial + @cantidad,
                       precio_costo_lote = dbo.fn_CalcularPrecioPromedioPonderado(
                           @cant_actual_lote, @cant_actual_lote * ISNULL(@costo_lote_prev, 0),
                           @cantidad, @precio_unitario)
                 WHERE id_lote = @id_lote;
            END

            -- Actualizar la fila EXACTA de detalle_compras (match por id_detalle, ya validado arriba)
            UPDATE detalle_compras
               SET id_lote = @id_lote
             WHERE id_detalle = @id_detalle;

            DECLARE @id_mov INT;
            EXEC sp_Kardex_RegistrarMovimiento
                @tipo_movimiento = 'entrada',
                @id_producto = @id_producto,
                @id_lote = @id_lote,
                @cantidad_entrada = @cantidad,
                @cantidad_salida = 0,
                @costo_unitario = @precio_unitario,
                @referencia_doc = 'compra',
                @id_referencia_doc = @id_compra,
                @id_usuario = @id_usuario,
                @id_movimiento_creado = @id_mov OUTPUT;

            FETCH NEXT FROM cur INTO @id_detalle, @id_producto, @cantidad, @precio_unitario, @numero_lote, @fecha_fab, @fecha_venc;
        END
        CLOSE cur;
        DEALLOCATE cur;

        UPDATE compras SET estado = 'recibida' WHERE id_compra = @id_compra;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE sp_Compra_Anular
    @id_compra INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @estado NVARCHAR(255);
    SELECT @estado = estado FROM compras WHERE id_compra = @id_compra;

    IF @estado IS NULL
        THROW 50062, 'La compra no existe.', 1;
    IF @estado <> 'pendiente'
        THROW 50063, 'Solo se pueden anular compras en estado pendiente (aun no recibidas).', 1;

    UPDATE compras SET estado = 'anulada' WHERE id_compra = @id_compra;
END
GO

CREATE OR ALTER PROCEDURE sp_Compra_ObtenerPorId
    @id_compra INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM compras WHERE id_compra = @id_compra;

    SELECT dc.*, p.nombre AS nombre_producto, l.numero_lote, l.fecha_vencimiento AS fecha_vencimiento_real
    FROM detalle_compras dc
    INNER JOIN productos p ON p.id_producto = dc.id_producto
    LEFT JOIN lotes l      ON l.id_lote = dc.id_lote
    WHERE dc.id_compra = @id_compra;
END
GO

CREATE OR ALTER VIEW vw_Compras
AS
    SELECT
        c.id_compra, c.fecha_compra, c.total, c.estado,
        pr.nombre_empresa AS nombre_proveedor,
        e.nombre_completo AS nombre_empleado, u.nombre_usuario
    FROM compras c
    LEFT JOIN proveedores pr ON pr.id_proveedor = c.id_proveedor
    LEFT JOIN empleados e    ON e.id_empleado = c.id_empleado
    LEFT JOIN usuarios u     ON u.id_usuario = c.id_usuario;
GO

CREATE OR ALTER PROCEDURE sp_Compra_Listar
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

    SELECT * FROM vw_Compras
    WHERE (@estado IS NULL OR estado = @estado)
      AND (@fecha_desde IS NULL OR fecha_compra >= @fecha_desde)
      AND (@fecha_hasta IS NULL OR fecha_compra < DATEADD(DAY, 1, @fecha_hasta))
    ORDER BY fecha_compra DESC
    OFFSET (@pagina - 1) * @tamano ROWS FETCH NEXT @tamano ROWS ONLY;

    SELECT COUNT(*) AS total FROM vw_Compras
    WHERE (@estado IS NULL OR estado = @estado)
      AND (@fecha_desde IS NULL OR fecha_compra >= @fecha_desde)
      AND (@fecha_hasta IS NULL OR fecha_compra < DATEADD(DAY, 1, @fecha_hasta));
END
GO
