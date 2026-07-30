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
