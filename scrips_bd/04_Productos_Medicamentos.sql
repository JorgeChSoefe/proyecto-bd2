/* ============================================================
   04. PRODUCTOS Y MEDICAMENTOS
   Tablas: productos, medicamentos, medicamento_principios
   ============================================================ */

-- NOTA: el nombre es enganoso -- retorna 1 cuando el SKU YA EXISTE (no cuando
-- es valido). Los llamadores lo usan correctamente (THROW cuando = 1);
-- se documenta aqui en vez de renombrar para no romper los SPs existentes.
CREATE OR ALTER FUNCTION fn_ValidarSkuUnico (@codigo_sku NVARCHAR(255), @id_producto_excluir INT = NULL)
RETURNS BIT
AS
BEGIN
    DECLARE @existe BIT = 0;
    IF EXISTS (
        SELECT 1 FROM productos
        WHERE codigo_sku = @codigo_sku
          AND (@id_producto_excluir IS NULL OR id_producto <> @id_producto_excluir)
    )
        SET @existe = 1;

    RETURN @existe;
END
GO

-- Bug B8: codigo_barras tiene UNIQUE en la tabla pero nadie lo validaba antes
-- de insertar/actualizar -- el usuario recibia un 500 de violacion de indice
-- en vez de un error de negocio mapeable (50023).
CREATE OR ALTER FUNCTION fn_ValidarCodigoBarrasUnico (@codigo_barras NVARCHAR(255), @id_producto_excluir INT = NULL)
RETURNS BIT
AS
BEGIN
    DECLARE @existe BIT = 0;
    IF EXISTS (
        SELECT 1 FROM productos
        WHERE codigo_barras = @codigo_barras
          AND (@id_producto_excluir IS NULL OR id_producto <> @id_producto_excluir)
    )
        SET @existe = 1;

    RETURN @existe;
END
GO

CREATE OR ALTER PROCEDURE sp_Producto_Insertar
    @nombre             NVARCHAR(255),
    @nombre_generico    NVARCHAR(255) = NULL,
    @codigo_sku         NVARCHAR(255) = NULL,
    @codigo_barras      NVARCHAR(255) = NULL,
    @precio_costo       DECIMAL(18,2),
    @precio_venta       DECIMAL(18,2),
    @stock_minimo       INT = 0,
    @requiere_receta    BIT = 0,
    @id_categoria       INT = NULL,
    @id_proveedor       INT = NULL,
    @id_laboratorio     INT = NULL,
    @id_presentacion    INT = NULL,
    @id_producto_creado INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF @codigo_sku IS NOT NULL AND dbo.fn_ValidarSkuUnico(@codigo_sku, NULL) = 1
        THROW 50020, 'El codigo SKU ya existe.', 1;

    IF @codigo_barras IS NOT NULL AND dbo.fn_ValidarCodigoBarrasUnico(@codigo_barras, NULL) = 1
        THROW 50023, 'El codigo de barras ya existe.', 1;

    INSERT INTO productos
        (nombre, nombre_generico, codigo_sku, codigo_barras, precio_costo, precio_venta,
         stock_actual, precio_promedio_pond, stock_minimo, requiere_receta,
         id_categoria, id_proveedor, id_laboratorio, id_presentacion)
    VALUES
        (@nombre, @nombre_generico, @codigo_sku, @codigo_barras, @precio_costo, @precio_venta,
         0, @precio_costo, @stock_minimo, @requiere_receta,
         @id_categoria, @id_proveedor, @id_laboratorio, @id_presentacion);

    SET @id_producto_creado = SCOPE_IDENTITY();
END
GO

CREATE OR ALTER PROCEDURE sp_Producto_Actualizar
    @id_producto        INT,
    @nombre             NVARCHAR(255),
    @nombre_generico    NVARCHAR(255) = NULL,
    @codigo_sku         NVARCHAR(255) = NULL,
    @codigo_barras      NVARCHAR(255) = NULL,
    @precio_costo       DECIMAL(18,2),
    @precio_venta       DECIMAL(18,2),
    @stock_minimo       INT,
    @requiere_receta    BIT,
    @id_categoria       INT = NULL,
    @id_proveedor       INT = NULL,
    @id_laboratorio     INT = NULL,
    @id_presentacion    INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @codigo_sku IS NOT NULL AND dbo.fn_ValidarSkuUnico(@codigo_sku, @id_producto) = 1
        THROW 50020, 'El codigo SKU ya existe en otro producto.', 1;

    IF @codigo_barras IS NOT NULL AND dbo.fn_ValidarCodigoBarrasUnico(@codigo_barras, @id_producto) = 1
        THROW 50023, 'El codigo de barras ya existe en otro producto.', 1;

    -- NOTA: nunca se actualiza stock_actual ni precio_promedio_pond aqui;
    -- esos campos solo los mueve sp_Kardex_RegistrarMovimiento.
    UPDATE productos
       SET nombre = @nombre, nombre_generico = @nombre_generico,
           codigo_sku = @codigo_sku, codigo_barras = @codigo_barras,
           precio_costo = @precio_costo, precio_venta = @precio_venta,
           stock_minimo = @stock_minimo, requiere_receta = @requiere_receta,
           id_categoria = @id_categoria, id_proveedor = @id_proveedor,
           id_laboratorio = @id_laboratorio, id_presentacion = @id_presentacion
     WHERE id_producto = @id_producto;
END
GO

CREATE OR ALTER PROCEDURE sp_Producto_Eliminar
    @id_producto INT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM kardex WHERE id_producto = @id_producto)
        THROW 50021, 'No se puede eliminar: el producto tiene movimientos de inventario.', 1;

    DELETE FROM medicamento_principios WHERE id_medicamento IN
        (SELECT id_medicamento FROM medicamentos WHERE id_producto = @id_producto);
    DELETE FROM medicamentos WHERE id_producto = @id_producto;
    DELETE FROM productos WHERE id_producto = @id_producto;
END
GO

CREATE OR ALTER PROCEDURE sp_Producto_ObtenerPorId
    @id_producto INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT p.*, c.nombre_categoria, pr.nombre_empresa AS proveedor, l.nombre AS laboratorio,
           pres.forma AS presentacion_forma, pres.unidad_medida
    FROM productos p
    LEFT JOIN categorias c    ON c.id_categoria = p.id_categoria
    LEFT JOIN proveedores pr  ON pr.id_proveedor = p.id_proveedor
    LEFT JOIN laboratorios l  ON l.id_laboratorio = p.id_laboratorio
    LEFT JOIN presentaciones pres ON pres.id_presentacion = p.id_presentacion
    WHERE p.id_producto = @id_producto;

    -- Ficha clinica si aplica
    SELECT m.*
    FROM medicamentos m
    WHERE m.id_producto = @id_producto;

    -- Principios activos del medicamento (si existe)
    SELECT mp.id_principio, pa.nombre_inn, pa.grupo_terapeutico, mp.cantidad_por_dosis, mp.unidad
    FROM medicamento_principios mp
    INNER JOIN medicamentos m       ON m.id_medicamento = mp.id_medicamento
    INNER JOIN principios_activos pa ON pa.id_principio = mp.id_principio
    WHERE m.id_producto = @id_producto;
END
GO

CREATE OR ALTER VIEW vw_Productos
AS
    SELECT
        p.id_producto, p.nombre, p.nombre_generico, p.codigo_sku, p.codigo_barras,
        p.precio_costo, p.precio_venta, p.stock_actual, p.precio_promedio_pond,
        p.stock_minimo, p.requiere_receta,
        c.nombre_categoria, pr.nombre_empresa AS proveedor, l.nombre AS laboratorio,
        pres.forma AS presentacion
    FROM productos p
    LEFT JOIN categorias c   ON c.id_categoria = p.id_categoria
    LEFT JOIN proveedores pr ON pr.id_proveedor = p.id_proveedor
    LEFT JOIN laboratorios l ON l.id_laboratorio = p.id_laboratorio
    LEFT JOIN presentaciones pres ON pres.id_presentacion = p.id_presentacion;
GO

-- Filtra por id_categoria directo contra productos (vw_Productos no expone
-- las FKs, solo los nombres resueltos) para no comparar por nombre.
CREATE OR ALTER PROCEDURE sp_Producto_Listar
    @pagina         INT = 1,
    @tamano         INT = 50,
    @busqueda       NVARCHAR(255) = NULL,
    @id_categoria   INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @pagina < 1 SET @pagina = 1;
    IF @tamano < 1 SET @tamano = 50;

    SELECT v.* FROM vw_Productos v
    INNER JOIN productos p ON p.id_producto = v.id_producto
    WHERE (@busqueda IS NULL OR v.nombre LIKE '%' + @busqueda + '%' OR v.codigo_sku LIKE '%' + @busqueda + '%')
      AND (@id_categoria IS NULL OR p.id_categoria = @id_categoria)
    ORDER BY v.nombre
    OFFSET (@pagina - 1) * @tamano ROWS FETCH NEXT @tamano ROWS ONLY;

    SELECT COUNT(*) AS total
    FROM productos p
    WHERE (@busqueda IS NULL OR p.nombre LIKE '%' + @busqueda + '%' OR p.codigo_sku LIKE '%' + @busqueda + '%')
      AND (@id_categoria IS NULL OR p.id_categoria = @id_categoria);
END
GO

-- ---------- MEDICAMENTOS ----------
CREATE OR ALTER PROCEDURE sp_Medicamento_Insertar
    @id_producto                    INT,
    @concentracion                  NVARCHAR(255) = NULL,
    @via_administracion             NVARCHAR(255),
    @condiciones_almacenamiento     NVARCHAR(255) = NULL,
    @controlado                     BIT = 0,
    @numero_registro_sanitario      NVARCHAR(255) = NULL,
    @indicaciones                   NVARCHAR(MAX) = NULL,
    @contraindicaciones             NVARCHAR(MAX) = NULL,
    @efectos_secundarios            NVARCHAR(MAX) = NULL,
    @interacciones                  NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM medicamentos WHERE id_producto = @id_producto)
        THROW 50022, 'Este producto ya tiene ficha de medicamento.', 1;

    -- id_medicamento es PK sin identity en el esquema: se usa el mismo id_producto (relacion 1:1)
    INSERT INTO medicamentos
        (id_medicamento, id_producto, concentracion, via_administracion,
         condiciones_almacenamiento, controlado, numero_registro_sanitario,
         indicaciones, contraindicaciones, efectos_secundarios, interacciones)
    VALUES
        (@id_producto, @id_producto, @concentracion, @via_administracion,
         @condiciones_almacenamiento, @controlado, @numero_registro_sanitario,
         @indicaciones, @contraindicaciones, @efectos_secundarios, @interacciones);
END
GO

CREATE OR ALTER PROCEDURE sp_Medicamento_Actualizar
    @id_medicamento                 INT,
    @concentracion                  NVARCHAR(255) = NULL,
    @via_administracion             NVARCHAR(255),
    @condiciones_almacenamiento     NVARCHAR(255) = NULL,
    @controlado                     BIT,
    @numero_registro_sanitario      NVARCHAR(255) = NULL,
    @indicaciones                   NVARCHAR(MAX) = NULL,
    @contraindicaciones             NVARCHAR(MAX) = NULL,
    @efectos_secundarios            NVARCHAR(MAX) = NULL,
    @interacciones                  NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE medicamentos
       SET concentracion = @concentracion, via_administracion = @via_administracion,
           condiciones_almacenamiento = @condiciones_almacenamiento, controlado = @controlado,
           numero_registro_sanitario = @numero_registro_sanitario, indicaciones = @indicaciones,
           contraindicaciones = @contraindicaciones, efectos_secundarios = @efectos_secundarios,
           interacciones = @interacciones
     WHERE id_medicamento = @id_medicamento;
END
GO

CREATE OR ALTER PROCEDURE sp_MedicamentoPrincipio_Asignar
    @id_medicamento     INT,
    @id_principio       INT,
    @cantidad_por_dosis DECIMAL(18,4),
    @unidad             NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM medicamento_principios WHERE id_medicamento=@id_medicamento AND id_principio=@id_principio)
        UPDATE medicamento_principios
           SET cantidad_por_dosis = @cantidad_por_dosis, unidad = @unidad
         WHERE id_medicamento = @id_medicamento AND id_principio = @id_principio;
    ELSE
        INSERT INTO medicamento_principios (id_medicamento, id_principio, cantidad_por_dosis, unidad)
        VALUES (@id_medicamento, @id_principio, @cantidad_por_dosis, @unidad);
END
GO

CREATE OR ALTER PROCEDURE sp_MedicamentoPrincipio_Quitar
    @id_medicamento INT, @id_principio INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM medicamento_principios
    WHERE id_medicamento = @id_medicamento AND id_principio = @id_principio;
END
GO

CREATE OR ALTER VIEW vw_ProductosMedicamentos
AS
    SELECT
        p.id_producto, p.nombre, p.requiere_receta,
        m.id_medicamento, m.concentracion, m.via_administracion, m.controlado,
        m.numero_registro_sanitario, m.condiciones_almacenamiento,
        pa.nombre_inn, pa.grupo_terapeutico, mp.cantidad_por_dosis, mp.unidad
    FROM productos p
    INNER JOIN medicamentos m ON m.id_producto = p.id_producto
    LEFT JOIN medicamento_principios mp ON mp.id_medicamento = m.id_medicamento
    LEFT JOIN principios_activos pa     ON pa.id_principio = mp.id_principio;
GO

-- GET /api/productos/{id}/medicamento -- wrapper de la vista filtrado por
-- producto (evita que la Api arme el WHERE con SQL ad-hoc).
CREATE OR ALTER PROCEDURE sp_Producto_ObtenerFichaMedicamento
    @id_producto INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM vw_ProductosMedicamentos WHERE id_producto = @id_producto;
END
GO
