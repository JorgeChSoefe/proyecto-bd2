/* ============================================================
   10. ESQUEMA DE TABLAS — T-SQL valido (SQL Server 2022)
   Traduccion de "Proyecto BD 2.sql" (export dbdiagram, no ejecutable):
     boolean          -> BIT NOT NULL DEFAULT (...)
     text             -> NVARCHAR(MAX)
     decimal (dinero) -> DECIMAL(18,2)
     decimal (ratios) -> DECIMAL(18,4)  (precio_promedio_pond, cantidad_por_dosis)
     datetime         -> DATETIME2(0)
   Mismas 20 tablas del diagrama original, sin agregar ninguna nueva,
   salvo la columna kardex.observaciones (ver nota mas abajo).
   Re-ejecutable: cada CREATE TABLE esta protegido con IF OBJECT_ID.
   ============================================================ */

IF DB_ID(N'PharmaInventory') IS NULL
BEGIN
    CREATE DATABASE PharmaInventory;
END
GO

USE PharmaInventory;
GO

/* ---------- 02. Seguridad y accesos ---------- */

IF OBJECT_ID(N'dbo.roles', N'U') IS NULL
CREATE TABLE dbo.roles (
    id_rol          INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_roles PRIMARY KEY,
    nombre_rol      NVARCHAR(255)     NOT NULL,
    descripcion     NVARCHAR(MAX)     NULL,
    CONSTRAINT UQ_roles_nombre UNIQUE (nombre_rol)
);
GO

IF OBJECT_ID(N'dbo.permisos', N'U') IS NULL
CREATE TABLE dbo.permisos (
    id_permiso      INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_permisos PRIMARY KEY,
    modulo          NVARCHAR(255)     NOT NULL,
    accion          NVARCHAR(255)     NOT NULL,
    descripcion     NVARCHAR(MAX)     NULL,
    CONSTRAINT UQ_permisos_modulo_accion UNIQUE (modulo, accion)
);
GO

IF OBJECT_ID(N'dbo.rol_permisos', N'U') IS NULL
CREATE TABLE dbo.rol_permisos (
    id_rol          INT NOT NULL,
    id_permiso      INT NOT NULL,
    CONSTRAINT PK_rol_permisos PRIMARY KEY (id_rol, id_permiso)
);
GO

IF OBJECT_ID(N'dbo.empleados', N'U') IS NULL
CREATE TABLE dbo.empleados (
    id_empleado     INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_empleados PRIMARY KEY,
    nombre_completo NVARCHAR(255)     NOT NULL,
    cargo           NVARCHAR(255)     NULL,
    email           NVARCHAR(255)     NULL
);
GO

IF OBJECT_ID(N'dbo.usuarios', N'U') IS NULL
CREATE TABLE dbo.usuarios (
    id_usuario      INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_usuarios PRIMARY KEY,
    nombre_usuario  NVARCHAR(255)     NOT NULL,
    email           NVARCHAR(255)     NULL,
    password_hash   NVARCHAR(255)     NOT NULL,
    id_rol          INT               NOT NULL,
    id_empleado     INT               NULL,
    activo          BIT               NOT NULL CONSTRAINT DF_usuarios_activo DEFAULT (1),
    ultimo_acceso   DATETIME2(0)      NULL,
    creado_en       DATETIME2(0)      NOT NULL CONSTRAINT DF_usuarios_creado_en DEFAULT (SYSDATETIME()),
    CONSTRAINT UQ_usuarios_nombre_usuario UNIQUE (nombre_usuario)
);
GO

/* ---------- 03. Catalogos base ---------- */

IF OBJECT_ID(N'dbo.categorias', N'U') IS NULL
CREATE TABLE dbo.categorias (
    id_categoria    INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_categorias PRIMARY KEY,
    nombre_categoria NVARCHAR(255)    NOT NULL,
    descripcion     NVARCHAR(255)     NULL,
    CONSTRAINT UQ_categorias_nombre UNIQUE (nombre_categoria)
);
GO

IF OBJECT_ID(N'dbo.proveedores', N'U') IS NULL
CREATE TABLE dbo.proveedores (
    id_proveedor    INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_proveedores PRIMARY KEY,
    nombre_empresa  NVARCHAR(255)     NOT NULL,
    contacto_nombre NVARCHAR(255)     NULL,
    telefono        NVARCHAR(255)     NULL,
    email           NVARCHAR(255)     NULL
);
GO

IF OBJECT_ID(N'dbo.laboratorios', N'U') IS NULL
CREATE TABLE dbo.laboratorios (
    id_laboratorio  INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_laboratorios PRIMARY KEY,
    nombre          NVARCHAR(255)     NOT NULL,
    pais_origen     NVARCHAR(255)     NULL,
    telefono        NVARCHAR(255)     NULL,
    email           NVARCHAR(255)     NULL,
    sitio_web       NVARCHAR(255)     NULL
);
GO

IF OBJECT_ID(N'dbo.principios_activos', N'U') IS NULL
CREATE TABLE dbo.principios_activos (
    id_principio        INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_principios_activos PRIMARY KEY,
    nombre_inn          NVARCHAR(255)     NOT NULL,
    grupo_terapeutico   NVARCHAR(255)     NULL,
    descripcion         NVARCHAR(MAX)     NULL
);
GO

IF OBJECT_ID(N'dbo.presentaciones', N'U') IS NULL
CREATE TABLE dbo.presentaciones (
    id_presentacion INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_presentaciones PRIMARY KEY,
    forma           NVARCHAR(255)     NOT NULL,
    unidad_medida   NVARCHAR(255)     NULL
);
GO

/* ---------- 04. Productos y medicamentos ---------- */

IF OBJECT_ID(N'dbo.productos', N'U') IS NULL
CREATE TABLE dbo.productos (
    id_producto             INT IDENTITY(1,1)  NOT NULL CONSTRAINT PK_productos PRIMARY KEY,
    nombre                  NVARCHAR(255)       NOT NULL,
    nombre_generico         NVARCHAR(255)       NULL,
    codigo_sku              NVARCHAR(255)       NULL,
    codigo_barras           NVARCHAR(255)       NULL,
    precio_costo            DECIMAL(18,2)       NOT NULL CONSTRAINT DF_productos_precio_costo DEFAULT (0),
    precio_venta            DECIMAL(18,2)       NOT NULL CONSTRAINT DF_productos_precio_venta DEFAULT (0),
    stock_actual            INT                 NOT NULL CONSTRAINT DF_productos_stock_actual DEFAULT (0),
    precio_promedio_pond    DECIMAL(18,4)       NOT NULL CONSTRAINT DF_productos_ppp DEFAULT (0),
    stock_minimo            INT                 NOT NULL CONSTRAINT DF_productos_stock_minimo DEFAULT (0),
    requiere_receta         BIT                 NOT NULL CONSTRAINT DF_productos_requiere_receta DEFAULT (0),
    id_categoria            INT                 NULL,
    id_proveedor            INT                 NULL,
    id_laboratorio          INT                 NULL,
    id_presentacion         INT                 NULL,
    CONSTRAINT UQ_productos_sku UNIQUE (codigo_sku),
    CONSTRAINT UQ_productos_barras UNIQUE (codigo_barras)
);
GO

-- id_medicamento es 1:1 con productos: NO tiene IDENTITY, sp_Medicamento_Insertar
-- lo llena con el mismo id_producto.
IF OBJECT_ID(N'dbo.medicamentos', N'U') IS NULL
CREATE TABLE dbo.medicamentos (
    id_medicamento              INT           NOT NULL CONSTRAINT PK_medicamentos PRIMARY KEY,
    id_producto                 INT           NOT NULL,
    concentracion                NVARCHAR(255) NULL,
    via_administracion           NVARCHAR(255) NOT NULL
        CONSTRAINT CK_medicamentos_via CHECK (via_administracion IN
            ('oral','topica','intravenosa','intramuscular','subcutanea',
             'inhalatoria','oftalmica','otica','nasal','rectal','sublingual')),
    condiciones_almacenamiento   NVARCHAR(255) NULL,
    controlado                   BIT           NOT NULL CONSTRAINT DF_medicamentos_controlado DEFAULT (0),
    numero_registro_sanitario    NVARCHAR(255) NULL,
    indicaciones                 NVARCHAR(MAX) NULL,
    contraindicaciones           NVARCHAR(MAX) NULL,
    efectos_secundarios          NVARCHAR(MAX) NULL,
    interacciones                NVARCHAR(MAX) NULL,
    CONSTRAINT UQ_medicamentos_producto UNIQUE (id_producto)
);
GO

IF OBJECT_ID(N'dbo.medicamento_principios', N'U') IS NULL
CREATE TABLE dbo.medicamento_principios (
    id_medicamento      INT             NOT NULL,
    id_principio        INT             NOT NULL,
    cantidad_por_dosis  DECIMAL(18,4)   NULL,
    unidad              NVARCHAR(255)   NULL,
    CONSTRAINT PK_medicamento_principios PRIMARY KEY (id_medicamento, id_principio)
);
GO

/* ---------- 05. Inventario ---------- */

IF OBJECT_ID(N'dbo.clientes', N'U') IS NULL
CREATE TABLE dbo.clientes (
    id_cliente          INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_clientes PRIMARY KEY,
    nombre_completo     NVARCHAR(255)     NOT NULL,
    identificacion      NVARCHAR(255)     NOT NULL,
    telefono            NVARCHAR(255)     NULL,
    fecha_nacimiento    DATE              NULL,
    email               NVARCHAR(255)     NULL,
    CONSTRAINT UQ_clientes_identificacion UNIQUE (identificacion)
);
GO

IF OBJECT_ID(N'dbo.compras', N'U') IS NULL
CREATE TABLE dbo.compras (
    id_compra       INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_compras PRIMARY KEY,
    fecha_compra    DATETIME2(0)      NOT NULL CONSTRAINT DF_compras_fecha DEFAULT (SYSDATETIME()),
    total           DECIMAL(18,2)     NOT NULL CONSTRAINT DF_compras_total DEFAULT (0),
    estado          NVARCHAR(255)     NOT NULL
        CONSTRAINT CK_compras_estado CHECK (estado IN ('pendiente','recibida','anulada')),
    id_proveedor    INT               NULL,
    id_empleado     INT               NULL,
    id_usuario      INT               NULL
);
GO

IF OBJECT_ID(N'dbo.lotes', N'U') IS NULL
CREATE TABLE dbo.lotes (
    id_lote             INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_lotes PRIMARY KEY,
    numero_lote         NVARCHAR(255)     NOT NULL,
    id_producto         INT               NOT NULL,
    id_compra           INT               NULL,
    fecha_fabricacion   DATE              NULL,
    fecha_vencimiento   DATE              NOT NULL,
    cantidad_inicial    INT               NOT NULL,
    cantidad_actual     INT               NOT NULL CONSTRAINT DF_lotes_cantidad_actual DEFAULT (0),
    precio_costo_lote   DECIMAL(18,2)     NULL,
    activo              BIT               NOT NULL CONSTRAINT DF_lotes_activo DEFAULT (1),
    creado_en           DATETIME2(0)      NOT NULL CONSTRAINT DF_lotes_creado_en DEFAULT (SYSDATETIME())
);
GO

IF OBJECT_ID(N'dbo.detalle_compras', N'U') IS NULL
CREATE TABLE dbo.detalle_compras (
    id_detalle      INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_detalle_compras PRIMARY KEY,
    cantidad        INT               NOT NULL,
    precio_unitario DECIMAL(18,2)     NOT NULL,
    subtotal        DECIMAL(18,2)     NOT NULL,
    id_compra       INT               NOT NULL,
    id_producto     INT               NOT NULL,
    id_lote         INT               NULL,
    -- Lote/fechas propuestos al registrar (antes de recibir) -- ver
    -- sp_Compra_Registrar/sp_Compra_Recibir en 08_Compras.sql.
    numero_lote_propuesto        NVARCHAR(255) NULL,
    fecha_fabricacion_propuesta  DATE          NULL,
    fecha_vencimiento_propuesta  DATE          NULL
);
GO

-- Aditivo para bases ya desplegadas antes de que existieran estas 3 columnas.
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.detalle_compras') AND name = 'numero_lote_propuesto')
    ALTER TABLE dbo.detalle_compras ADD numero_lote_propuesto NVARCHAR(255) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.detalle_compras') AND name = 'fecha_fabricacion_propuesta')
    ALTER TABLE dbo.detalle_compras ADD fecha_fabricacion_propuesta DATE NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.detalle_compras') AND name = 'fecha_vencimiento_propuesta')
    ALTER TABLE dbo.detalle_compras ADD fecha_vencimiento_propuesta DATE NULL;
GO

/* ---------- 06/07. Ventas y recetas (ciclo ventas <-> recetas) ---------- */

-- ventas.id_receta se agrega SIN FK todavia (recetas aun no existe); la
-- restriccion se aplica al final junto con las demas ALTER TABLE.
IF OBJECT_ID(N'dbo.ventas', N'U') IS NULL
CREATE TABLE dbo.ventas (
    id_venta        INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_ventas PRIMARY KEY,
    fecha_venta     DATETIME2(0)      NOT NULL CONSTRAINT DF_ventas_fecha DEFAULT (SYSDATETIME()),
    total           DECIMAL(18,2)     NOT NULL CONSTRAINT DF_ventas_total DEFAULT (0),
    estado          NVARCHAR(255)     NOT NULL
        CONSTRAINT CK_ventas_estado CHECK (estado IN ('pendiente','completada','anulada')),
    id_empleado     INT               NULL,
    id_cliente      INT               NULL,
    id_usuario      INT               NULL,
    id_receta       INT               NULL
);
GO

IF OBJECT_ID(N'dbo.recetas', N'U') IS NULL
CREATE TABLE dbo.recetas (
    id_receta           INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_recetas PRIMARY KEY,
    numero_receta       NVARCHAR(255)     NOT NULL,
    id_cliente          INT               NOT NULL,
    nombre_medico       NVARCHAR(255)     NULL,
    num_colegio_medico  NVARCHAR(255)     NULL,
    fecha_emision       DATE              NOT NULL,
    fecha_vencimiento   DATE              NULL,
    dispensada          BIT               NOT NULL CONSTRAINT DF_recetas_dispensada DEFAULT (0),
    id_venta            INT               NULL,
    notas               NVARCHAR(MAX)     NULL,
    creado_en            DATETIME2(0)      NOT NULL CONSTRAINT DF_recetas_creado_en DEFAULT (SYSDATETIME()),
    CONSTRAINT UQ_recetas_numero UNIQUE (numero_receta)
);
GO

IF OBJECT_ID(N'dbo.detalle_recetas', N'U') IS NULL
CREATE TABLE dbo.detalle_recetas (
    id_detalle              INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_detalle_recetas PRIMARY KEY,
    id_receta               INT               NOT NULL,
    id_producto              INT               NOT NULL,
    cantidad_prescrita       INT               NOT NULL,
    dosis                    NVARCHAR(255)     NULL,
    duracion_tratamiento     NVARCHAR(255)     NULL,
    dispensada               BIT               NOT NULL CONSTRAINT DF_detalle_recetas_dispensada DEFAULT (0)
);
GO

IF OBJECT_ID(N'dbo.detalle_ventas', N'U') IS NULL
CREATE TABLE dbo.detalle_ventas (
    id_detalle      INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_detalle_ventas PRIMARY KEY,
    cantidad        INT               NOT NULL,
    precio_unitario DECIMAL(18,2)     NOT NULL,
    subtotal        DECIMAL(18,2)     NOT NULL,
    id_venta        INT               NOT NULL,
    id_producto     INT               NOT NULL,
    id_lote         INT               NULL
);
GO

/* ---------- Kardex y alertas ---------- */

-- NOTA: 'observaciones' es la unica columna agregada al esquema original.
-- sp_Inventario_AjusteManual recibe @motivo y hoy lo descarta (no habia
-- donde persistirlo) -- rompia la trazabilidad de mermas/conteos fisicos
-- que pide la seccion 5.3 del spec. Columna aditiva y NULL: no rompe nada.
IF OBJECT_ID(N'dbo.kardex', N'U') IS NULL
CREATE TABLE dbo.kardex (
    id_movimiento           INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_kardex PRIMARY KEY,
    fecha_movimiento        DATETIME2(0)      NOT NULL CONSTRAINT DF_kardex_fecha DEFAULT (SYSDATETIME()),
    tipo_movimiento         NVARCHAR(255)     NOT NULL
        CONSTRAINT CK_kardex_tipo CHECK (tipo_movimiento IN ('entrada','salida','ajuste')),
    referencia_doc          NVARCHAR(255)     NULL,
    id_referencia_doc       INT               NULL,
    cantidad_entrada        INT               NOT NULL CONSTRAINT DF_kardex_cant_entrada DEFAULT (0),
    cantidad_salida         INT               NOT NULL CONSTRAINT DF_kardex_cant_salida DEFAULT (0),
    saldo_stock             INT               NOT NULL,
    costo_unitario          DECIMAL(18,2)     NULL,
    costo_total_mov         DECIMAL(18,2)     NULL,
    precio_promedio_pond    DECIMAL(18,4)     NULL,
    saldo_valorado          DECIMAL(18,2)     NULL,
    id_producto             INT               NOT NULL,
    id_lote                 INT               NULL,
    id_usuario              INT               NULL,
    observaciones            NVARCHAR(500)     NULL
);
GO

IF OBJECT_ID(N'dbo.alertas_stock', N'U') IS NULL
CREATE TABLE dbo.alertas_stock (
    id_alerta               INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_alertas_stock PRIMARY KEY,
    tipo_alerta              NVARCHAR(255)     NOT NULL
        CONSTRAINT CK_alertas_tipo CHECK (tipo_alerta IN ('vencimiento_proximo','stock_minimo','lote_agotado')),
    id_producto              INT               NULL,
    id_lote                  INT               NULL,
    mensaje                  NVARCHAR(MAX)     NULL,
    fecha_alerta             DATETIME2(0)      NOT NULL CONSTRAINT DF_alertas_fecha DEFAULT (SYSDATETIME()),
    resuelta                 BIT               NOT NULL CONSTRAINT DF_alertas_resuelta DEFAULT (0),
    fecha_resolucion         DATETIME2(0)      NULL,
    id_usuario_resolucion    INT               NULL
);
GO

/* ============================================================
   INDICES DE APOYO
   ============================================================ */

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'lotes_index_0' AND object_id = OBJECT_ID('dbo.lotes'))
    CREATE UNIQUE INDEX lotes_index_0 ON dbo.lotes (id_producto, numero_lote);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'lotes_index_1' AND object_id = OBJECT_ID('dbo.lotes'))
    CREATE INDEX lotes_index_1 ON dbo.lotes (fecha_vencimiento);
GO

-- Cubre fn_ObtenerLoteFEFOTabla sin lookups a la tabla base.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_lotes_fefo' AND object_id = OBJECT_ID('dbo.lotes'))
    CREATE INDEX IX_lotes_fefo ON dbo.lotes (id_producto, fecha_vencimiento, id_lote)
        INCLUDE (cantidad_actual, precio_costo_lote)
        WHERE activo = 1;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_kardex_producto_fecha' AND object_id = OBJECT_ID('dbo.kardex'))
    CREATE INDEX IX_kardex_producto_fecha ON dbo.kardex (id_producto, fecha_movimiento);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_detalle_ventas_venta' AND object_id = OBJECT_ID('dbo.detalle_ventas'))
    CREATE INDEX IX_detalle_ventas_venta ON dbo.detalle_ventas (id_venta);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_detalle_compras_compra' AND object_id = OBJECT_ID('dbo.detalle_compras'))
    CREATE INDEX IX_detalle_compras_compra ON dbo.detalle_compras (id_compra);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_alertas_abiertas' AND object_id = OBJECT_ID('dbo.alertas_stock'))
    CREATE INDEX IX_alertas_abiertas ON dbo.alertas_stock (tipo_alerta, resuelta);
GO

/* ============================================================
   FOREIGN KEYS
   ============================================================ */

IF OBJECT_ID(N'FK_rol_permisos_rol', N'F') IS NULL
    ALTER TABLE dbo.rol_permisos ADD CONSTRAINT FK_rol_permisos_rol FOREIGN KEY (id_rol) REFERENCES dbo.roles (id_rol);
GO
IF OBJECT_ID(N'FK_rol_permisos_permiso', N'F') IS NULL
    ALTER TABLE dbo.rol_permisos ADD CONSTRAINT FK_rol_permisos_permiso FOREIGN KEY (id_permiso) REFERENCES dbo.permisos (id_permiso);
GO
IF OBJECT_ID(N'FK_usuarios_rol', N'F') IS NULL
    ALTER TABLE dbo.usuarios ADD CONSTRAINT FK_usuarios_rol FOREIGN KEY (id_rol) REFERENCES dbo.roles (id_rol);
GO
IF OBJECT_ID(N'FK_usuarios_empleado', N'F') IS NULL
    ALTER TABLE dbo.usuarios ADD CONSTRAINT FK_usuarios_empleado FOREIGN KEY (id_empleado) REFERENCES dbo.empleados (id_empleado);
GO
IF OBJECT_ID(N'FK_productos_categoria', N'F') IS NULL
    ALTER TABLE dbo.productos ADD CONSTRAINT FK_productos_categoria FOREIGN KEY (id_categoria) REFERENCES dbo.categorias (id_categoria);
GO
IF OBJECT_ID(N'FK_productos_proveedor', N'F') IS NULL
    ALTER TABLE dbo.productos ADD CONSTRAINT FK_productos_proveedor FOREIGN KEY (id_proveedor) REFERENCES dbo.proveedores (id_proveedor);
GO
IF OBJECT_ID(N'FK_productos_laboratorio', N'F') IS NULL
    ALTER TABLE dbo.productos ADD CONSTRAINT FK_productos_laboratorio FOREIGN KEY (id_laboratorio) REFERENCES dbo.laboratorios (id_laboratorio);
GO
IF OBJECT_ID(N'FK_productos_presentacion', N'F') IS NULL
    ALTER TABLE dbo.productos ADD CONSTRAINT FK_productos_presentacion FOREIGN KEY (id_presentacion) REFERENCES dbo.presentaciones (id_presentacion);
GO
IF OBJECT_ID(N'FK_medicamentos_producto', N'F') IS NULL
    ALTER TABLE dbo.medicamentos ADD CONSTRAINT FK_medicamentos_producto FOREIGN KEY (id_producto) REFERENCES dbo.productos (id_producto);
GO
IF OBJECT_ID(N'FK_medprin_medicamento', N'F') IS NULL
    ALTER TABLE dbo.medicamento_principios ADD CONSTRAINT FK_medprin_medicamento FOREIGN KEY (id_medicamento) REFERENCES dbo.medicamentos (id_medicamento);
GO
IF OBJECT_ID(N'FK_medprin_principio', N'F') IS NULL
    ALTER TABLE dbo.medicamento_principios ADD CONSTRAINT FK_medprin_principio FOREIGN KEY (id_principio) REFERENCES dbo.principios_activos (id_principio);
GO
IF OBJECT_ID(N'FK_compras_proveedor', N'F') IS NULL
    ALTER TABLE dbo.compras ADD CONSTRAINT FK_compras_proveedor FOREIGN KEY (id_proveedor) REFERENCES dbo.proveedores (id_proveedor);
GO
IF OBJECT_ID(N'FK_compras_empleado', N'F') IS NULL
    ALTER TABLE dbo.compras ADD CONSTRAINT FK_compras_empleado FOREIGN KEY (id_empleado) REFERENCES dbo.empleados (id_empleado);
GO
IF OBJECT_ID(N'FK_compras_usuario', N'F') IS NULL
    ALTER TABLE dbo.compras ADD CONSTRAINT FK_compras_usuario FOREIGN KEY (id_usuario) REFERENCES dbo.usuarios (id_usuario);
GO
IF OBJECT_ID(N'FK_lotes_producto', N'F') IS NULL
    ALTER TABLE dbo.lotes ADD CONSTRAINT FK_lotes_producto FOREIGN KEY (id_producto) REFERENCES dbo.productos (id_producto);
GO
IF OBJECT_ID(N'FK_lotes_compra', N'F') IS NULL
    ALTER TABLE dbo.lotes ADD CONSTRAINT FK_lotes_compra FOREIGN KEY (id_compra) REFERENCES dbo.compras (id_compra);
GO
IF OBJECT_ID(N'FK_detcompras_compra', N'F') IS NULL
    ALTER TABLE dbo.detalle_compras ADD CONSTRAINT FK_detcompras_compra FOREIGN KEY (id_compra) REFERENCES dbo.compras (id_compra);
GO
IF OBJECT_ID(N'FK_detcompras_producto', N'F') IS NULL
    ALTER TABLE dbo.detalle_compras ADD CONSTRAINT FK_detcompras_producto FOREIGN KEY (id_producto) REFERENCES dbo.productos (id_producto);
GO
IF OBJECT_ID(N'FK_detcompras_lote', N'F') IS NULL
    ALTER TABLE dbo.detalle_compras ADD CONSTRAINT FK_detcompras_lote FOREIGN KEY (id_lote) REFERENCES dbo.lotes (id_lote);
GO
IF OBJECT_ID(N'FK_ventas_empleado', N'F') IS NULL
    ALTER TABLE dbo.ventas ADD CONSTRAINT FK_ventas_empleado FOREIGN KEY (id_empleado) REFERENCES dbo.empleados (id_empleado);
GO
IF OBJECT_ID(N'FK_ventas_cliente', N'F') IS NULL
    ALTER TABLE dbo.ventas ADD CONSTRAINT FK_ventas_cliente FOREIGN KEY (id_cliente) REFERENCES dbo.clientes (id_cliente);
GO
IF OBJECT_ID(N'FK_ventas_usuario', N'F') IS NULL
    ALTER TABLE dbo.ventas ADD CONSTRAINT FK_ventas_usuario FOREIGN KEY (id_usuario) REFERENCES dbo.usuarios (id_usuario);
GO
IF OBJECT_ID(N'FK_recetas_cliente', N'F') IS NULL
    ALTER TABLE dbo.recetas ADD CONSTRAINT FK_recetas_cliente FOREIGN KEY (id_cliente) REFERENCES dbo.clientes (id_cliente);
GO
IF OBJECT_ID(N'FK_recetas_venta', N'F') IS NULL
    ALTER TABLE dbo.recetas ADD CONSTRAINT FK_recetas_venta FOREIGN KEY (id_venta) REFERENCES dbo.ventas (id_venta);
GO
-- Cierre del ciclo ventas <-> recetas: recetas ya existe, ahora se puede referenciar.
IF OBJECT_ID(N'FK_ventas_receta', N'F') IS NULL
    ALTER TABLE dbo.ventas ADD CONSTRAINT FK_ventas_receta FOREIGN KEY (id_receta) REFERENCES dbo.recetas (id_receta);
GO
IF OBJECT_ID(N'FK_detrecetas_receta', N'F') IS NULL
    ALTER TABLE dbo.detalle_recetas ADD CONSTRAINT FK_detrecetas_receta FOREIGN KEY (id_receta) REFERENCES dbo.recetas (id_receta);
GO
IF OBJECT_ID(N'FK_detrecetas_producto', N'F') IS NULL
    ALTER TABLE dbo.detalle_recetas ADD CONSTRAINT FK_detrecetas_producto FOREIGN KEY (id_producto) REFERENCES dbo.productos (id_producto);
GO
IF OBJECT_ID(N'FK_detventas_venta', N'F') IS NULL
    ALTER TABLE dbo.detalle_ventas ADD CONSTRAINT FK_detventas_venta FOREIGN KEY (id_venta) REFERENCES dbo.ventas (id_venta);
GO
IF OBJECT_ID(N'FK_detventas_producto', N'F') IS NULL
    ALTER TABLE dbo.detalle_ventas ADD CONSTRAINT FK_detventas_producto FOREIGN KEY (id_producto) REFERENCES dbo.productos (id_producto);
GO
IF OBJECT_ID(N'FK_detventas_lote', N'F') IS NULL
    ALTER TABLE dbo.detalle_ventas ADD CONSTRAINT FK_detventas_lote FOREIGN KEY (id_lote) REFERENCES dbo.lotes (id_lote);
GO
IF OBJECT_ID(N'FK_kardex_producto', N'F') IS NULL
    ALTER TABLE dbo.kardex ADD CONSTRAINT FK_kardex_producto FOREIGN KEY (id_producto) REFERENCES dbo.productos (id_producto);
GO
IF OBJECT_ID(N'FK_kardex_lote', N'F') IS NULL
    ALTER TABLE dbo.kardex ADD CONSTRAINT FK_kardex_lote FOREIGN KEY (id_lote) REFERENCES dbo.lotes (id_lote);
GO
IF OBJECT_ID(N'FK_kardex_usuario', N'F') IS NULL
    ALTER TABLE dbo.kardex ADD CONSTRAINT FK_kardex_usuario FOREIGN KEY (id_usuario) REFERENCES dbo.usuarios (id_usuario);
GO
IF OBJECT_ID(N'FK_alertas_producto', N'F') IS NULL
    ALTER TABLE dbo.alertas_stock ADD CONSTRAINT FK_alertas_producto FOREIGN KEY (id_producto) REFERENCES dbo.productos (id_producto);
GO
IF OBJECT_ID(N'FK_alertas_lote', N'F') IS NULL
    ALTER TABLE dbo.alertas_stock ADD CONSTRAINT FK_alertas_lote FOREIGN KEY (id_lote) REFERENCES dbo.lotes (id_lote);
GO
IF OBJECT_ID(N'FK_alertas_usuario_resolucion', N'F') IS NULL
    ALTER TABLE dbo.alertas_stock ADD CONSTRAINT FK_alertas_usuario_resolucion FOREIGN KEY (id_usuario_resolucion) REFERENCES dbo.usuarios (id_usuario);
GO
