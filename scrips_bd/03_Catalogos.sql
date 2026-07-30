/* ============================================================
   03. CATALOGOS BASE
   Tablas: categorias, proveedores, laboratorios,
           principios_activos, presentaciones
   ============================================================ */

-- ---------- CATEGORIAS ----------
CREATE OR ALTER PROCEDURE sp_Categoria_Insertar
    @nombre_categoria NVARCHAR(255),
    @descripcion      NVARCHAR(255) = NULL,
    @id_creado        INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO categorias (nombre_categoria, descripcion)
    VALUES (@nombre_categoria, @descripcion);
    SET @id_creado = SCOPE_IDENTITY();
END
GO

CREATE OR ALTER PROCEDURE sp_Categoria_Actualizar
    @id_categoria INT, @nombre_categoria NVARCHAR(255), @descripcion NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE categorias SET nombre_categoria = @nombre_categoria, descripcion = @descripcion
    WHERE id_categoria = @id_categoria;
END
GO

CREATE OR ALTER PROCEDURE sp_Categoria_Eliminar
    @id_categoria INT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM productos WHERE id_categoria = @id_categoria)
        THROW 50010, 'No se puede eliminar: hay productos con esta categoria.', 1;
    DELETE FROM categorias WHERE id_categoria = @id_categoria;
END
GO

CREATE OR ALTER VIEW vw_Categorias
AS
    SELECT id_categoria, nombre_categoria, descripcion FROM categorias;
GO

CREATE OR ALTER PROCEDURE sp_Categoria_Listar
    @pagina INT = 1, @tamano INT = 50, @busqueda NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @pagina < 1 SET @pagina = 1;
    IF @tamano < 1 SET @tamano = 50;

    SELECT * FROM vw_Categorias
    WHERE @busqueda IS NULL OR nombre_categoria LIKE '%' + @busqueda + '%'
    ORDER BY nombre_categoria
    OFFSET (@pagina - 1) * @tamano ROWS FETCH NEXT @tamano ROWS ONLY;

    SELECT COUNT(*) AS total FROM vw_Categorias
    WHERE @busqueda IS NULL OR nombre_categoria LIKE '%' + @busqueda + '%';
END
GO

CREATE OR ALTER PROCEDURE sp_Categoria_ObtenerPorId
    @id_categoria INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM vw_Categorias WHERE id_categoria = @id_categoria;
END
GO

-- ---------- PROVEEDORES ----------
CREATE OR ALTER PROCEDURE sp_Proveedor_Insertar
    @nombre_empresa NVARCHAR(255), @contacto_nombre NVARCHAR(255) = NULL,
    @telefono NVARCHAR(255) = NULL, @email NVARCHAR(255) = NULL,
    @id_creado INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO proveedores (nombre_empresa, contacto_nombre, telefono, email)
    VALUES (@nombre_empresa, @contacto_nombre, @telefono, @email);
    SET @id_creado = SCOPE_IDENTITY();
END
GO

CREATE OR ALTER PROCEDURE sp_Proveedor_Actualizar
    @id_proveedor INT, @nombre_empresa NVARCHAR(255), @contacto_nombre NVARCHAR(255) = NULL,
    @telefono NVARCHAR(255) = NULL, @email NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE proveedores
       SET nombre_empresa = @nombre_empresa, contacto_nombre = @contacto_nombre,
           telefono = @telefono, email = @email
     WHERE id_proveedor = @id_proveedor;
END
GO

CREATE OR ALTER PROCEDURE sp_Proveedor_Eliminar
    @id_proveedor INT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM productos WHERE id_proveedor = @id_proveedor)
        THROW 50011, 'No se puede eliminar: hay productos de este proveedor.', 1;
    DELETE FROM proveedores WHERE id_proveedor = @id_proveedor;
END
GO

CREATE OR ALTER VIEW vw_Proveedores
AS
    SELECT id_proveedor, nombre_empresa, contacto_nombre, telefono, email FROM proveedores;
GO

CREATE OR ALTER PROCEDURE sp_Proveedor_Listar
    @pagina INT = 1, @tamano INT = 50, @busqueda NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @pagina < 1 SET @pagina = 1;
    IF @tamano < 1 SET @tamano = 50;

    SELECT * FROM vw_Proveedores
    WHERE @busqueda IS NULL OR nombre_empresa LIKE '%' + @busqueda + '%'
    ORDER BY nombre_empresa
    OFFSET (@pagina - 1) * @tamano ROWS FETCH NEXT @tamano ROWS ONLY;

    SELECT COUNT(*) AS total FROM vw_Proveedores
    WHERE @busqueda IS NULL OR nombre_empresa LIKE '%' + @busqueda + '%';
END
GO

CREATE OR ALTER PROCEDURE sp_Proveedor_ObtenerPorId
    @id_proveedor INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM vw_Proveedores WHERE id_proveedor = @id_proveedor;
END
GO

-- ---------- LABORATORIOS ----------
CREATE OR ALTER PROCEDURE sp_Laboratorio_Insertar
    @nombre NVARCHAR(255), @pais_origen NVARCHAR(255) = NULL, @telefono NVARCHAR(255) = NULL,
    @email NVARCHAR(255) = NULL, @sitio_web NVARCHAR(255) = NULL,
    @id_creado INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO laboratorios (nombre, pais_origen, telefono, email, sitio_web)
    VALUES (@nombre, @pais_origen, @telefono, @email, @sitio_web);
    SET @id_creado = SCOPE_IDENTITY();
END
GO

CREATE OR ALTER PROCEDURE sp_Laboratorio_Actualizar
    @id_laboratorio INT, @nombre NVARCHAR(255), @pais_origen NVARCHAR(255) = NULL,
    @telefono NVARCHAR(255) = NULL, @email NVARCHAR(255) = NULL, @sitio_web NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE laboratorios
       SET nombre = @nombre, pais_origen = @pais_origen, telefono = @telefono,
           email = @email, sitio_web = @sitio_web
     WHERE id_laboratorio = @id_laboratorio;
END
GO

CREATE OR ALTER PROCEDURE sp_Laboratorio_Eliminar
    @id_laboratorio INT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM productos WHERE id_laboratorio = @id_laboratorio)
        THROW 50012, 'No se puede eliminar: hay productos de este laboratorio.', 1;
    DELETE FROM laboratorios WHERE id_laboratorio = @id_laboratorio;
END
GO

CREATE OR ALTER VIEW vw_Laboratorios
AS
    SELECT id_laboratorio, nombre, pais_origen, telefono, email, sitio_web FROM laboratorios;
GO

CREATE OR ALTER PROCEDURE sp_Laboratorio_Listar
    @pagina INT = 1, @tamano INT = 50, @busqueda NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @pagina < 1 SET @pagina = 1;
    IF @tamano < 1 SET @tamano = 50;

    SELECT * FROM vw_Laboratorios
    WHERE @busqueda IS NULL OR nombre LIKE '%' + @busqueda + '%'
    ORDER BY nombre
    OFFSET (@pagina - 1) * @tamano ROWS FETCH NEXT @tamano ROWS ONLY;

    SELECT COUNT(*) AS total FROM vw_Laboratorios
    WHERE @busqueda IS NULL OR nombre LIKE '%' + @busqueda + '%';
END
GO

CREATE OR ALTER PROCEDURE sp_Laboratorio_ObtenerPorId
    @id_laboratorio INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM vw_Laboratorios WHERE id_laboratorio = @id_laboratorio;
END
GO

-- ---------- PRINCIPIOS ACTIVOS ----------
CREATE OR ALTER PROCEDURE sp_PrincipioActivo_Insertar
    @nombre_inn NVARCHAR(255), @grupo_terapeutico NVARCHAR(255) = NULL,
    @descripcion NVARCHAR(MAX) = NULL, @id_creado INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO principios_activos (nombre_inn, grupo_terapeutico, descripcion)
    VALUES (@nombre_inn, @grupo_terapeutico, @descripcion);
    SET @id_creado = SCOPE_IDENTITY();
END
GO

CREATE OR ALTER PROCEDURE sp_PrincipioActivo_Actualizar
    @id_principio INT, @nombre_inn NVARCHAR(255), @grupo_terapeutico NVARCHAR(255) = NULL,
    @descripcion NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE principios_activos
       SET nombre_inn = @nombre_inn, grupo_terapeutico = @grupo_terapeutico, descripcion = @descripcion
     WHERE id_principio = @id_principio;
END
GO

CREATE OR ALTER PROCEDURE sp_PrincipioActivo_Eliminar
    @id_principio INT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM medicamento_principios WHERE id_principio = @id_principio)
        THROW 50013, 'No se puede eliminar: esta en uso por medicamentos.', 1;
    DELETE FROM principios_activos WHERE id_principio = @id_principio;
END
GO

CREATE OR ALTER VIEW vw_PrincipiosActivos
AS
    SELECT id_principio, nombre_inn, grupo_terapeutico, descripcion FROM principios_activos;
GO

CREATE OR ALTER PROCEDURE sp_PrincipioActivo_Listar
    @pagina INT = 1, @tamano INT = 50, @busqueda NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @pagina < 1 SET @pagina = 1;
    IF @tamano < 1 SET @tamano = 50;

    SELECT * FROM vw_PrincipiosActivos
    WHERE @busqueda IS NULL OR nombre_inn LIKE '%' + @busqueda + '%'
    ORDER BY nombre_inn
    OFFSET (@pagina - 1) * @tamano ROWS FETCH NEXT @tamano ROWS ONLY;

    SELECT COUNT(*) AS total FROM vw_PrincipiosActivos
    WHERE @busqueda IS NULL OR nombre_inn LIKE '%' + @busqueda + '%';
END
GO

CREATE OR ALTER PROCEDURE sp_PrincipioActivo_ObtenerPorId
    @id_principio INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM vw_PrincipiosActivos WHERE id_principio = @id_principio;
END
GO

-- ---------- PRESENTACIONES ----------
CREATE OR ALTER PROCEDURE sp_Presentacion_Insertar
    @forma NVARCHAR(255), @unidad_medida NVARCHAR(255) = NULL, @id_creado INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO presentaciones (forma, unidad_medida) VALUES (@forma, @unidad_medida);
    SET @id_creado = SCOPE_IDENTITY();
END
GO

CREATE OR ALTER PROCEDURE sp_Presentacion_Actualizar
    @id_presentacion INT, @forma NVARCHAR(255), @unidad_medida NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE presentaciones SET forma = @forma, unidad_medida = @unidad_medida
    WHERE id_presentacion = @id_presentacion;
END
GO

CREATE OR ALTER PROCEDURE sp_Presentacion_Eliminar
    @id_presentacion INT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM productos WHERE id_presentacion = @id_presentacion)
        THROW 50014, 'No se puede eliminar: hay productos con esta presentacion.', 1;
    DELETE FROM presentaciones WHERE id_presentacion = @id_presentacion;
END
GO

CREATE OR ALTER VIEW vw_Presentaciones
AS
    SELECT id_presentacion, forma, unidad_medida FROM presentaciones;
GO

CREATE OR ALTER PROCEDURE sp_Presentacion_Listar
    @pagina INT = 1, @tamano INT = 50, @busqueda NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @pagina < 1 SET @pagina = 1;
    IF @tamano < 1 SET @tamano = 50;

    SELECT * FROM vw_Presentaciones
    WHERE @busqueda IS NULL OR forma LIKE '%' + @busqueda + '%'
    ORDER BY forma
    OFFSET (@pagina - 1) * @tamano ROWS FETCH NEXT @tamano ROWS ONLY;

    SELECT COUNT(*) AS total FROM vw_Presentaciones
    WHERE @busqueda IS NULL OR forma LIKE '%' + @busqueda + '%';
END
GO

CREATE OR ALTER PROCEDURE sp_Presentacion_ObtenerPorId
    @id_presentacion INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM vw_Presentaciones WHERE id_presentacion = @id_presentacion;
END
GO
