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
/* ============================================================
   02. SEGURIDAD Y ACCESOS
   Tablas: roles, permisos, rol_permisos, usuarios, empleados
   ============================================================ */

-- ---------- ROLES ----------
CREATE OR ALTER PROCEDURE sp_Rol_Insertar
    @nombre_rol     NVARCHAR(255),
    @descripcion    NVARCHAR(MAX) = NULL,
    @id_rol_creado  INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO roles (nombre_rol, descripcion)
    VALUES (@nombre_rol, @descripcion);

    SET @id_rol_creado = SCOPE_IDENTITY();
END
GO

CREATE OR ALTER PROCEDURE sp_Rol_Actualizar
    @id_rol         INT,
    @nombre_rol     NVARCHAR(255),
    @descripcion    NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM roles WHERE id_rol = @id_rol)
        THROW 50001, 'El rol no existe.', 1;

    UPDATE roles
       SET nombre_rol = @nombre_rol,
           descripcion = @descripcion
     WHERE id_rol = @id_rol;
END
GO

CREATE OR ALTER PROCEDURE sp_Rol_Eliminar
    @id_rol INT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM usuarios WHERE id_rol = @id_rol)
        THROW 50002, 'No se puede eliminar el rol: tiene usuarios asignados.', 1;

    DELETE FROM rol_permisos WHERE id_rol = @id_rol;
    DELETE FROM roles WHERE id_rol = @id_rol;
END
GO

CREATE OR ALTER VIEW vw_Roles
AS
    SELECT id_rol, nombre_rol, descripcion
    FROM roles;
GO

CREATE OR ALTER PROCEDURE sp_Rol_Listar
    @pagina     INT = 1,
    @tamano     INT = 50,
    @busqueda   NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @pagina < 1 SET @pagina = 1;
    IF @tamano < 1 SET @tamano = 50;

    SELECT id_rol, nombre_rol, descripcion
    FROM vw_Roles
    WHERE @busqueda IS NULL OR nombre_rol LIKE '%' + @busqueda + '%'
    ORDER BY nombre_rol
    OFFSET (@pagina - 1) * @tamano ROWS FETCH NEXT @tamano ROWS ONLY;

    SELECT COUNT(*) AS total
    FROM vw_Roles
    WHERE @busqueda IS NULL OR nombre_rol LIKE '%' + @busqueda + '%';
END
GO

CREATE OR ALTER PROCEDURE sp_Rol_ObtenerPorId
    @id_rol INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM vw_Roles WHERE id_rol = @id_rol;
END
GO

-- ---------- PERMISOS ----------
CREATE OR ALTER PROCEDURE sp_Permiso_Insertar
    @modulo             NVARCHAR(255),
    @accion             NVARCHAR(255),
    @descripcion        NVARCHAR(MAX) = NULL,
    @id_permiso_creado  INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM permisos WHERE modulo = @modulo AND accion = @accion)
        THROW 50005, 'Ya existe un permiso con ese modulo y accion.', 1;

    INSERT INTO permisos (modulo, accion, descripcion)
    VALUES (@modulo, @accion, @descripcion);

    SET @id_permiso_creado = SCOPE_IDENTITY();
END
GO

CREATE OR ALTER PROCEDURE sp_Permiso_Actualizar
    @id_permiso     INT,
    @modulo         NVARCHAR(255),
    @accion         NVARCHAR(255),
    @descripcion    NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM permisos WHERE id_permiso = @id_permiso)
        THROW 50006, 'El permiso no existe.', 1;
    IF EXISTS (SELECT 1 FROM permisos WHERE modulo = @modulo AND accion = @accion AND id_permiso <> @id_permiso)
        THROW 50005, 'Ya existe un permiso con ese modulo y accion.', 1;

    UPDATE permisos
       SET modulo = @modulo, accion = @accion, descripcion = @descripcion
     WHERE id_permiso = @id_permiso;
END
GO

CREATE OR ALTER PROCEDURE sp_Permiso_Eliminar
    @id_permiso INT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM rol_permisos WHERE id_permiso = @id_permiso)
        THROW 50007, 'No se puede eliminar: el permiso esta asignado a uno o mas roles.', 1;

    DELETE FROM permisos WHERE id_permiso = @id_permiso;
END
GO

CREATE OR ALTER PROCEDURE sp_Permiso_AsignarARol
    @id_rol     INT,
    @id_permiso INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM rol_permisos WHERE id_rol = @id_rol AND id_permiso = @id_permiso)
        INSERT INTO rol_permisos (id_rol, id_permiso) VALUES (@id_rol, @id_permiso);
END
GO

CREATE OR ALTER PROCEDURE sp_Permiso_RevocarDeRol
    @id_rol     INT,
    @id_permiso INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM rol_permisos WHERE id_rol = @id_rol AND id_permiso = @id_permiso;
END
GO

-- Permisos ya asignados a un rol -- el frontend lo necesita para pintar la
-- matriz modulo x accion con el estado real (sin esto, el dialogo de
-- "permisos del rol" solo podia agregar, nunca ver que ya estaba marcado).
CREATE OR ALTER PROCEDURE sp_Rol_ObtenerPermisos
    @id_rol INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT p.id_permiso, p.modulo, p.accion, p.descripcion
    FROM permisos p
    INNER JOIN rol_permisos rp ON rp.id_permiso = p.id_permiso
    WHERE rp.id_rol = @id_rol;
END
GO

CREATE OR ALTER VIEW vw_Permisos
AS
    SELECT id_permiso, modulo, accion, descripcion
    FROM permisos;
GO

CREATE OR ALTER PROCEDURE sp_Permiso_Listar
    @pagina     INT = 1,
    @tamano     INT = 50,
    @busqueda   NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @pagina < 1 SET @pagina = 1;
    IF @tamano < 1 SET @tamano = 50;

    SELECT id_permiso, modulo, accion, descripcion
    FROM vw_Permisos
    WHERE @busqueda IS NULL OR modulo LIKE '%' + @busqueda + '%' OR accion LIKE '%' + @busqueda + '%'
    ORDER BY modulo, accion
    OFFSET (@pagina - 1) * @tamano ROWS FETCH NEXT @tamano ROWS ONLY;

    SELECT COUNT(*) AS total
    FROM vw_Permisos
    WHERE @busqueda IS NULL OR modulo LIKE '%' + @busqueda + '%' OR accion LIKE '%' + @busqueda + '%';
END
GO

CREATE OR ALTER PROCEDURE sp_Permiso_ObtenerPorId
    @id_permiso INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM vw_Permisos WHERE id_permiso = @id_permiso;
END
GO

-- ---------- EMPLEADOS ----------
CREATE OR ALTER PROCEDURE sp_Empleado_Insertar
    @nombre_completo    NVARCHAR(255),
    @cargo              NVARCHAR(255),
    @email              NVARCHAR(255),
    @id_empleado_creado INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO empleados (nombre_completo, cargo, email)
    VALUES (@nombre_completo, @cargo, @email);

    SET @id_empleado_creado = SCOPE_IDENTITY();
END
GO

CREATE OR ALTER PROCEDURE sp_Empleado_Actualizar
    @id_empleado        INT,
    @nombre_completo     NVARCHAR(255),
    @cargo               NVARCHAR(255),
    @email               NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE empleados
       SET nombre_completo = @nombre_completo,
           cargo = @cargo,
           email = @email
     WHERE id_empleado = @id_empleado;
END
GO

CREATE OR ALTER PROCEDURE sp_Empleado_Eliminar
    @id_empleado INT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM usuarios WHERE id_empleado = @id_empleado)
        THROW 50003, 'No se puede eliminar: el empleado tiene un usuario asociado.', 1;

    DELETE FROM empleados WHERE id_empleado = @id_empleado;
END
GO

CREATE OR ALTER VIEW vw_Empleados
AS
    SELECT id_empleado, nombre_completo, cargo, email
    FROM empleados;
GO

CREATE OR ALTER PROCEDURE sp_Empleado_Listar
    @pagina     INT = 1,
    @tamano     INT = 50,
    @busqueda   NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @pagina < 1 SET @pagina = 1;
    IF @tamano < 1 SET @tamano = 50;

    SELECT id_empleado, nombre_completo, cargo, email
    FROM vw_Empleados
    WHERE @busqueda IS NULL OR nombre_completo LIKE '%' + @busqueda + '%'
    ORDER BY nombre_completo
    OFFSET (@pagina - 1) * @tamano ROWS FETCH NEXT @tamano ROWS ONLY;

    SELECT COUNT(*) AS total
    FROM vw_Empleados
    WHERE @busqueda IS NULL OR nombre_completo LIKE '%' + @busqueda + '%';
END
GO

CREATE OR ALTER PROCEDURE sp_Empleado_ObtenerPorId
    @id_empleado INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM vw_Empleados WHERE id_empleado = @id_empleado;
END
GO

-- ---------- USUARIOS ----------
CREATE OR ALTER PROCEDURE sp_Usuario_Insertar
    @nombre_usuario     NVARCHAR(255),
    @email              NVARCHAR(255),
    @password_hash      NVARCHAR(255),
    @id_rol             INT,
    @id_empleado        INT = NULL,
    @id_usuario_creado  INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM usuarios WHERE nombre_usuario = @nombre_usuario)
        THROW 50004, 'El nombre de usuario ya existe.', 1;

    INSERT INTO usuarios (nombre_usuario, email, password_hash, id_rol, id_empleado, activo, creado_en)
    VALUES (@nombre_usuario, @email, @password_hash, @id_rol, @id_empleado, 1, GETDATE());

    SET @id_usuario_creado = SCOPE_IDENTITY();
END
GO

CREATE OR ALTER PROCEDURE sp_Usuario_Actualizar
    @id_usuario     INT,
    @email          NVARCHAR(255),
    @id_rol         INT,
    @id_empleado    INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE usuarios
       SET email = @email,
           id_rol = @id_rol,
           id_empleado = @id_empleado
     WHERE id_usuario = @id_usuario;
END
GO

CREATE OR ALTER PROCEDURE sp_Usuario_CambiarPassword
    @id_usuario         INT,
    @password_hash_nuevo NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE usuarios
       SET password_hash = @password_hash_nuevo
     WHERE id_usuario = @id_usuario;
END
GO

CREATE OR ALTER PROCEDURE sp_Usuario_Desactivar
    @id_usuario INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE usuarios SET activo = 0 WHERE id_usuario = @id_usuario;
END
GO

-- Autenticación: la API valida el hash de @password_hash contra el recibido
CREATE OR ALTER PROCEDURE sp_Usuario_Autenticar
    @nombre_usuario NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        u.id_usuario, u.nombre_usuario, u.email, u.password_hash,
        u.activo, u.id_rol, r.nombre_rol, u.id_empleado
    FROM usuarios u
    INNER JOIN roles r ON r.id_rol = u.id_rol
    WHERE u.nombre_usuario = @nombre_usuario;

    -- Nota: si retornó fila y la API valida el hash correctamente,
    -- la API invoca sp_Usuario_ActualizarUltimoAcceso.
END
GO

CREATE OR ALTER PROCEDURE sp_Usuario_ActualizarUltimoAcceso
    @id_usuario INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE usuarios SET ultimo_acceso = GETDATE() WHERE id_usuario = @id_usuario;
END
GO

-- Vista de permisos efectivos por usuario (para middleware de autorización)
CREATE OR ALTER VIEW vw_UsuarioPermisos
AS
    SELECT
        u.id_usuario,
        u.nombre_usuario,
        u.activo,
        r.id_rol,
        r.nombre_rol,
        p.id_permiso,
        p.modulo,
        p.accion
    FROM usuarios u
    INNER JOIN roles r         ON r.id_rol = u.id_rol
    INNER JOIN rol_permisos rp ON rp.id_rol = r.id_rol
    INNER JOIN permisos p      ON p.id_permiso = rp.id_permiso;
GO

-- Permisos efectivos de un usuario puntual -- lo usa la Api para armar los
-- claims del JWT en el login (evita que la Api tenga que filtrar
-- vw_UsuarioPermisos con SQL ad-hoc).
CREATE OR ALTER PROCEDURE sp_Usuario_ObtenerPermisos
    @id_usuario INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT id_permiso, modulo, accion
    FROM vw_UsuarioPermisos
    WHERE id_usuario = @id_usuario;
END
GO

-- Listado de usuarios para grillas (sin password_hash)
CREATE OR ALTER VIEW vw_Usuarios
AS
    SELECT
        u.id_usuario, u.nombre_usuario, u.email, u.activo, u.ultimo_acceso, u.creado_en,
        r.id_rol, r.nombre_rol, u.id_empleado, e.nombre_completo AS nombre_empleado
    FROM usuarios u
    INNER JOIN roles r      ON r.id_rol = u.id_rol
    LEFT JOIN empleados e   ON e.id_empleado = u.id_empleado;
GO

CREATE OR ALTER PROCEDURE sp_Usuario_Listar
    @pagina     INT = 1,
    @tamano     INT = 50,
    @busqueda   NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @pagina < 1 SET @pagina = 1;
    IF @tamano < 1 SET @tamano = 50;

    SELECT *
    FROM vw_Usuarios
    WHERE @busqueda IS NULL OR nombre_usuario LIKE '%' + @busqueda + '%' OR email LIKE '%' + @busqueda + '%'
    ORDER BY nombre_usuario
    OFFSET (@pagina - 1) * @tamano ROWS FETCH NEXT @tamano ROWS ONLY;

    SELECT COUNT(*) AS total
    FROM vw_Usuarios
    WHERE @busqueda IS NULL OR nombre_usuario LIKE '%' + @busqueda + '%' OR email LIKE '%' + @busqueda + '%';
END
GO

CREATE OR ALTER PROCEDURE sp_Usuario_ObtenerPorId
    @id_usuario INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM vw_Usuarios WHERE id_usuario = @id_usuario;
END
GO
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
