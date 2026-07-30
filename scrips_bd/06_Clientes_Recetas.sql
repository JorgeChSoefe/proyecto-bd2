/* ============================================================
   06. CLIENTES Y RECETAS
   Tablas: clientes, recetas, detalle_recetas
   ============================================================ */

CREATE OR ALTER PROCEDURE sp_Cliente_Insertar
    @nombre_completo NVARCHAR(255), @identificacion NVARCHAR(255),
    @telefono NVARCHAR(255) = NULL, @fecha_nacimiento DATE = NULL, @email NVARCHAR(255) = NULL,
    @id_creado INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM clientes WHERE identificacion = @identificacion)
        THROW 50040, 'Ya existe un cliente con esa identificacion.', 1;

    INSERT INTO clientes (nombre_completo, identificacion, telefono, fecha_nacimiento, email)
    VALUES (@nombre_completo, @identificacion, @telefono, @fecha_nacimiento, @email);
    SET @id_creado = SCOPE_IDENTITY();
END
GO

CREATE OR ALTER PROCEDURE sp_Cliente_Actualizar
    @id_cliente INT, @nombre_completo NVARCHAR(255), @telefono NVARCHAR(255) = NULL,
    @fecha_nacimiento DATE = NULL, @email NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE clientes
       SET nombre_completo = @nombre_completo, telefono = @telefono,
           fecha_nacimiento = @fecha_nacimiento, email = @email
     WHERE id_cliente = @id_cliente;
END
GO

CREATE OR ALTER PROCEDURE sp_Cliente_Eliminar
    @id_cliente INT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM ventas WHERE id_cliente = @id_cliente)
        THROW 50041, 'No se puede eliminar: el cliente tiene ventas registradas.', 1;
    DELETE FROM clientes WHERE id_cliente = @id_cliente;
END
GO

CREATE OR ALTER VIEW vw_Clientes
AS
    SELECT id_cliente, nombre_completo, identificacion, telefono, fecha_nacimiento, email FROM clientes;
GO

CREATE OR ALTER PROCEDURE sp_Cliente_Listar
    @pagina INT = 1, @tamano INT = 50, @busqueda NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @pagina < 1 SET @pagina = 1;
    IF @tamano < 1 SET @tamano = 50;

    SELECT * FROM vw_Clientes
    WHERE @busqueda IS NULL OR nombre_completo LIKE '%' + @busqueda + '%' OR identificacion LIKE '%' + @busqueda + '%'
    ORDER BY nombre_completo
    OFFSET (@pagina - 1) * @tamano ROWS FETCH NEXT @tamano ROWS ONLY;

    SELECT COUNT(*) AS total FROM vw_Clientes
    WHERE @busqueda IS NULL OR nombre_completo LIKE '%' + @busqueda + '%' OR identificacion LIKE '%' + @busqueda + '%';
END
GO

CREATE OR ALTER PROCEDURE sp_Cliente_ObtenerPorId
    @id_cliente INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM vw_Clientes WHERE id_cliente = @id_cliente;
END
GO

-- ---------- FUNCION: vigencia de receta ----------
CREATE OR ALTER FUNCTION fn_RecetaVigente (@id_receta INT)
RETURNS BIT
AS
BEGIN
    DECLARE @vigente BIT = 0;
    SELECT @vigente = CASE
                         WHEN fecha_vencimiento IS NULL THEN 1
                         WHEN fecha_vencimiento >= CAST(GETDATE() AS DATE) THEN 1
                         ELSE 0
                       END
    FROM recetas WHERE id_receta = @id_receta;

    RETURN ISNULL(@vigente, 0);
END
GO

-- ---------- Registrar receta + detalle (transaccional) ----------
CREATE OR ALTER PROCEDURE sp_Receta_Registrar
    @numero_receta      NVARCHAR(255),
    @id_cliente         INT,
    @nombre_medico      NVARCHAR(255),
    @num_colegio_medico NVARCHAR(255) = NULL,
    @fecha_emision      DATE,
    @fecha_vencimiento  DATE = NULL,
    @notas              NVARCHAR(MAX) = NULL,
    @detalle            dbo.TipoDetalleReceta READONLY,
    @id_receta_creada   INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO recetas
            (numero_receta, id_cliente, nombre_medico, num_colegio_medico,
             fecha_emision, fecha_vencimiento, dispensada, notas, creado_en)
        VALUES
            (@numero_receta, @id_cliente, @nombre_medico, @num_colegio_medico,
             @fecha_emision, @fecha_vencimiento, 0, @notas, GETDATE());

        SET @id_receta_creada = SCOPE_IDENTITY();

        INSERT INTO detalle_recetas (id_receta, id_producto, cantidad_prescrita, dosis, duracion_tratamiento, dispensada)
        SELECT @id_receta_creada, id_producto, cantidad_prescrita, dosis, duracion_tratamiento, 0
        FROM @detalle;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE sp_Receta_ObtenerPorId
    @id_receta INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT r.*, c.nombre_completo AS nombre_cliente
    FROM recetas r
    INNER JOIN clientes c ON c.id_cliente = r.id_cliente
    WHERE r.id_receta = @id_receta;

    SELECT dr.*, p.nombre AS nombre_producto
    FROM detalle_recetas dr
    INNER JOIN productos p ON p.id_producto = dr.id_producto
    WHERE dr.id_receta = @id_receta;
END
GO

-- ---------- Marcar receta/detalle como dispensada ----------
-- Llamado internamente desde sp_Venta_Registrar cuando la venta cubre @id_receta.
CREATE OR ALTER PROCEDURE sp_Receta_MarcarDispensada
    @id_receta      INT,
    @id_producto    INT,
    @cantidad_vendida INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE detalle_recetas
       SET dispensada = 1
     WHERE id_receta = @id_receta
       AND id_producto = @id_producto
       AND cantidad_prescrita <= @cantidad_vendida;

    -- La receta cabecera se marca dispensada solo si TODO el detalle esta dispensado
    IF NOT EXISTS (SELECT 1 FROM detalle_recetas WHERE id_receta = @id_receta AND dispensada = 0)
        UPDATE recetas SET dispensada = 1 WHERE id_receta = @id_receta;
END
GO

CREATE OR ALTER VIEW vw_RecetasPendientes
AS
    SELECT r.*, c.nombre_completo AS nombre_cliente
    FROM recetas r
    INNER JOIN clientes c ON c.id_cliente = r.id_cliente
    WHERE r.dispensada = 0
      AND (r.fecha_vencimiento IS NULL OR r.fecha_vencimiento >= CAST(GETDATE() AS DATE));
GO

CREATE OR ALTER PROCEDURE sp_Receta_ListarPendientes
    @pagina INT = 1, @tamano INT = 50, @id_cliente INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @pagina < 1 SET @pagina = 1;
    IF @tamano < 1 SET @tamano = 50;

    SELECT * FROM vw_RecetasPendientes
    WHERE @id_cliente IS NULL OR id_cliente = @id_cliente
    ORDER BY fecha_emision DESC
    OFFSET (@pagina - 1) * @tamano ROWS FETCH NEXT @tamano ROWS ONLY;

    SELECT COUNT(*) AS total FROM vw_RecetasPendientes
    WHERE @id_cliente IS NULL OR id_cliente = @id_cliente;
END
GO
