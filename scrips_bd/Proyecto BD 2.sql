CREATE TABLE [roles] (
  [id_rol] int PRIMARY KEY IDENTITY(1, 1),
  [nombre_rol] nvarchar(255),
  [descripcion] text
)
GO

CREATE TABLE [permisos] (
  [id_permiso] int PRIMARY KEY IDENTITY(1, 1),
  [modulo] nvarchar(255),
  [accion] nvarchar(255),
  [descripcion] text
)
GO

CREATE TABLE [rol_permisos] (
  [id_rol] int,
  [id_permiso] int,
  PRIMARY KEY ([id_rol], [id_permiso])
)
GO

CREATE TABLE [empleados] (
  [id_empleado] int PRIMARY KEY IDENTITY(1, 1),
  [nombre_completo] nvarchar(255),
  [cargo] nvarchar(255),
  [email] nvarchar(255)
)
GO

CREATE TABLE [usuarios] (
  [id_usuario] int PRIMARY KEY IDENTITY(1, 1),
  [nombre_usuario] nvarchar(255),
  [email] nvarchar(255),
  [password_hash] nvarchar(255),
  [id_rol] int,
  [id_empleado] int,
  [activo] boolean,
  [ultimo_acceso] datetime,
  [creado_en] datetime
)
GO

CREATE TABLE [categorias] (
  [id_categoria] int PRIMARY KEY IDENTITY(1, 1),
  [nombre_categoria] nvarchar(255),
  [descripcion] nvarchar(255)
)
GO

CREATE TABLE [proveedores] (
  [id_proveedor] int PRIMARY KEY IDENTITY(1, 1),
  [nombre_empresa] nvarchar(255),
  [contacto_nombre] nvarchar(255),
  [telefono] nvarchar(255),
  [email] nvarchar(255)
)
GO

CREATE TABLE [laboratorios] (
  [id_laboratorio] int PRIMARY KEY IDENTITY(1, 1),
  [nombre] nvarchar(255) NOT NULL,
  [pais_origen] nvarchar(255),
  [telefono] nvarchar(255),
  [email] nvarchar(255),
  [sitio_web] nvarchar(255)
)
GO

CREATE TABLE [principios_activos] (
  [id_principio] int PRIMARY KEY IDENTITY(1, 1),
  [nombre_inn] nvarchar(255) NOT NULL,
  [grupo_terapeutico] nvarchar(255),
  [descripcion] text
)
GO

CREATE TABLE [presentaciones] (
  [id_presentacion] int PRIMARY KEY IDENTITY(1, 1),
  [forma] nvarchar(255) NOT NULL,
  [unidad_medida] nvarchar(255)
)
GO

CREATE TABLE [productos] (
  [id_producto] int PRIMARY KEY IDENTITY(1, 1),
  [nombre] nvarchar(255) NOT NULL,
  [nombre_generico] nvarchar(255),
  [codigo_sku] nvarchar(255) UNIQUE,
  [codigo_barras] nvarchar(255) UNIQUE,
  [precio_costo] decimal,
  [precio_venta] decimal,
  [stock_actual] int,
  [precio_promedio_pond] decimal,
  [stock_minimo] int,
  [requiere_receta] boolean DEFAULT (false),
  [id_categoria] int,
  [id_proveedor] int,
  [id_laboratorio] int,
  [id_presentacion] int
)
GO

CREATE TABLE [medicamentos] (
  [id_medicamento] int PRIMARY KEY,
  [id_producto] int,
  [concentracion] nvarchar(255),
  [via_administracion] nvarchar(255) NOT NULL CHECK ([via_administracion] IN ('oral', 'topica', 'intravenosa', 'intramuscular', 'subcutanea', 'inhalatoria', 'oftalmica', 'otica', 'nasal', 'rectal', 'sublingual')),
  [condiciones_almacenamiento] nvarchar(255),
  [controlado] boolean DEFAULT (false),
  [numero_registro_sanitario] nvarchar(255),
  [indicaciones] text,
  [contraindicaciones] text,
  [efectos_secundarios] text,
  [interacciones] text
)
GO

CREATE TABLE [medicamento_principios] (
  [id_medicamento] int,
  [id_principio] int,
  [cantidad_por_dosis] decimal,
  [unidad] nvarchar(255),
  PRIMARY KEY ([id_medicamento], [id_principio])
)
GO

CREATE TABLE [lotes] (
  [id_lote] int PRIMARY KEY IDENTITY(1, 1),
  [numero_lote] nvarchar(255) NOT NULL,
  [id_producto] int,
  [id_compra] int,
  [fecha_fabricacion] date,
  [fecha_vencimiento] date NOT NULL,
  [cantidad_inicial] int NOT NULL,
  [cantidad_actual] int NOT NULL,
  [precio_costo_lote] decimal,
  [activo] boolean DEFAULT (true),
  [creado_en] datetime
)
GO

CREATE TABLE [clientes] (
  [id_cliente] int PRIMARY KEY IDENTITY(1, 1),
  [nombre_completo] nvarchar(255),
  [identificacion] nvarchar(255) UNIQUE,
  [telefono] nvarchar(255),
  [fecha_nacimiento] date,
  [email] nvarchar(255)
)
GO

CREATE TABLE [recetas] (
  [id_receta] int PRIMARY KEY IDENTITY(1, 1),
  [numero_receta] nvarchar(255) UNIQUE,
  [id_cliente] int,
  [nombre_medico] nvarchar(255),
  [num_colegio_medico] nvarchar(255),
  [fecha_emision] date NOT NULL,
  [fecha_vencimiento] date,
  [dispensada] boolean DEFAULT (false),
  [id_venta] int,
  [notas] text,
  [creado_en] datetime
)
GO

CREATE TABLE [detalle_recetas] (
  [id_detalle] int PRIMARY KEY IDENTITY(1, 1),
  [id_receta] int,
  [id_producto] int,
  [cantidad_prescrita] int,
  [dosis] nvarchar(255),
  [duracion_tratamiento] nvarchar(255),
  [dispensada] boolean DEFAULT (false)
)
GO

CREATE TABLE [ventas] (
  [id_venta] int PRIMARY KEY IDENTITY(1, 1),
  [fecha_venta] datetime,
  [total] decimal,
  [estado] nvarchar(255) NOT NULL CHECK ([estado] IN ('pendiente', 'completada', 'anulada')),
  [id_empleado] int,
  [id_cliente] int,
  [id_usuario] int,
  [id_receta] int
)
GO

CREATE TABLE [detalle_ventas] (
  [id_detalle] int PRIMARY KEY IDENTITY(1, 1),
  [cantidad] int,
  [precio_unitario] decimal,
  [subtotal] decimal,
  [id_venta] int,
  [id_producto] int,
  [id_lote] int
)
GO

CREATE TABLE [compras] (
  [id_compra] int PRIMARY KEY IDENTITY(1, 1),
  [fecha_compra] datetime,
  [total] decimal,
  [estado] nvarchar(255) NOT NULL CHECK ([estado] IN ('pendiente', 'recibida', 'anulada')),
  [id_proveedor] int,
  [id_empleado] int,
  [id_usuario] int
)
GO

CREATE TABLE [detalle_compras] (
  [id_detalle] int PRIMARY KEY IDENTITY(1, 1),
  [cantidad] int,
  [precio_unitario] decimal,
  [subtotal] decimal,
  [id_compra] int,
  [id_producto] int,
  [id_lote] int
)
GO

CREATE TABLE [kardex] (
  [id_movimiento] int PRIMARY KEY IDENTITY(1, 1),
  [fecha_movimiento] datetime,
  [tipo_movimiento] nvarchar(255) NOT NULL CHECK ([tipo_movimiento] IN ('entrada', 'salida', 'ajuste')),
  [referencia_doc] nvarchar(255),
  [id_referencia_doc] int,
  [cantidad_entrada] int,
  [cantidad_salida] int,
  [saldo_stock] int,
  [costo_unitario] decimal,
  [costo_total_mov] decimal,
  [precio_promedio_pond] decimal,
  [saldo_valorado] decimal,
  [id_producto] int,
  [id_lote] int,
  [id_usuario] int
)
GO

CREATE TABLE [alertas_stock] (
  [id_alerta] int PRIMARY KEY IDENTITY(1, 1),
  [tipo_alerta] nvarchar(255) NOT NULL CHECK ([tipo_alerta] IN ('vencimiento_proximo', 'stock_minimo', 'lote_agotado')),
  [id_producto] int,
  [id_lote] int,
  [mensaje] text,
  [fecha_alerta] datetime,
  [resuelta] boolean DEFAULT (false),
  [fecha_resolucion] datetime,
  [id_usuario_resolucion] int
)
GO

CREATE UNIQUE INDEX [lotes_index_0] ON [lotes] ("id_producto", "numero_lote")
GO

CREATE INDEX [lotes_index_1] ON [lotes] ("fecha_vencimiento")
GO

EXEC sp_addextendedproperty
@name = N'Table_Description',
@value = 'NUEVO — fabricante del medicamento',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'laboratorios';
GO

EXEC sp_addextendedproperty
@name = N'Table_Description',
@value = 'NUEVO — catálogo INN/DCI de ingredientes activos',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'principios_activos';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Nombre Internacional No Propietario',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'principios_activos',
@level2type = N'Column', @level2name = 'nombre_inn';
GO

EXEC sp_addextendedproperty
@name = N'Table_Description',
@value = 'NUEVO — formas farmacéuticas',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'presentaciones';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'ej: tableta, cápsula, jarabe, ampolla, crema',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'presentaciones',
@level2type = N'Column', @level2name = 'forma';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'mg, ml, UI, %',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'presentaciones',
@level2type = N'Column', @level2name = 'unidad_medida';
GO

EXEC sp_addextendedproperty
@name = N'Table_Description',
@value = 'MODIFICADO — agrega laboratorio y presentación',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'productos';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'nombre genérico / DCI',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'productos',
@level2type = N'Column', @level2name = 'nombre_generico';
GO

EXEC sp_addextendedproperty
@name = N'Table_Description',
@value = 'NUEVO — datos clínicos y regulatorios del medicamento',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'medicamentos';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = '1:1 con productos',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'medicamentos',
@level2type = N'Column', @level2name = 'id_producto';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'ej: 500mg, 10mg/5ml',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'medicamentos',
@level2type = N'Column', @level2name = 'concentracion';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'ej: refrigerar 2-8°C, temperatura ambiente',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'medicamentos',
@level2type = N'Column', @level2name = 'condiciones_almacenamiento';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'estupefaciente o psicotrópico',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'medicamentos',
@level2type = N'Column', @level2name = 'controlado';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'registro CCSS/Ministerio de Salud CR',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'medicamentos',
@level2type = N'Column', @level2name = 'numero_registro_sanitario';
GO

EXEC sp_addextendedproperty
@name = N'Table_Description',
@value = 'NUEVO — relación N:M medicamento ↔ principios activos',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'medicamento_principios';
GO

EXEC sp_addextendedproperty
@name = N'Table_Description',
@value = 'NUEVO — control de lotes y vencimientos por producto',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'lotes';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'lote ingresado con esta compra',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'lotes',
@level2type = N'Column', @level2name = 'id_compra';
GO

EXEC sp_addextendedproperty
@name = N'Table_Description',
@value = 'NUEVO — registro de recetas médicas',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'recetas';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'venta que dispensó la receta',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'recetas',
@level2type = N'Column', @level2name = 'id_venta';
GO

EXEC sp_addextendedproperty
@name = N'Table_Description',
@value = 'NUEVO — medicamentos prescritos en la receta',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'detalle_recetas';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'ej: 1 tableta cada 8 horas',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'detalle_recetas',
@level2type = N'Column', @level2name = 'dosis';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'ej: 7 días',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'detalle_recetas',
@level2type = N'Column', @level2name = 'duracion_tratamiento';
GO

EXEC sp_addextendedproperty
@name = N'Table_Description',
@value = 'MODIFICADO — agrega id_receta',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'ventas';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'nullable — solo si aplica receta',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'ventas',
@level2type = N'Column', @level2name = 'id_receta';
GO

EXEC sp_addextendedproperty
@name = N'Table_Description',
@value = 'MODIFICADO — agrega id_lote para trazabilidad',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'detalle_ventas';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'lote despachado — FEFO',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'detalle_ventas',
@level2type = N'Column', @level2name = 'id_lote';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'lote recibido en esta compra',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'detalle_compras',
@level2type = N'Column', @level2name = 'id_lote';
GO

EXEC sp_addextendedproperty
@name = N'Table_Description',
@value = 'MODIFICADO — agrega id_lote',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'kardex';
GO

EXEC sp_addextendedproperty
@name = N'Table_Description',
@value = 'NUEVO — log de alertas automáticas de inventario',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'alertas_stock';
GO

ALTER TABLE [rol_permisos] ADD FOREIGN KEY ([id_rol]) REFERENCES [roles] ([id_rol])
GO

ALTER TABLE [rol_permisos] ADD FOREIGN KEY ([id_permiso]) REFERENCES [permisos] ([id_permiso])
GO

ALTER TABLE [usuarios] ADD FOREIGN KEY ([id_rol]) REFERENCES [roles] ([id_rol])
GO

ALTER TABLE [usuarios] ADD FOREIGN KEY ([id_empleado]) REFERENCES [empleados] ([id_empleado])
GO

ALTER TABLE [productos] ADD FOREIGN KEY ([id_categoria]) REFERENCES [categorias] ([id_categoria])
GO

ALTER TABLE [productos] ADD FOREIGN KEY ([id_proveedor]) REFERENCES [proveedores] ([id_proveedor])
GO

ALTER TABLE [productos] ADD FOREIGN KEY ([id_laboratorio]) REFERENCES [laboratorios] ([id_laboratorio])
GO

ALTER TABLE [productos] ADD FOREIGN KEY ([id_presentacion]) REFERENCES [presentaciones] ([id_presentacion])
GO

ALTER TABLE [medicamentos] ADD FOREIGN KEY ([id_producto]) REFERENCES [productos] ([id_producto])
GO

ALTER TABLE [medicamento_principios] ADD FOREIGN KEY ([id_medicamento]) REFERENCES [medicamentos] ([id_medicamento])
GO

ALTER TABLE [medicamento_principios] ADD FOREIGN KEY ([id_principio]) REFERENCES [principios_activos] ([id_principio])
GO

ALTER TABLE [lotes] ADD FOREIGN KEY ([id_producto]) REFERENCES [productos] ([id_producto])
GO

ALTER TABLE [lotes] ADD FOREIGN KEY ([id_compra]) REFERENCES [compras] ([id_compra])
GO

ALTER TABLE [recetas] ADD FOREIGN KEY ([id_cliente]) REFERENCES [clientes] ([id_cliente])
GO

ALTER TABLE [recetas] ADD FOREIGN KEY ([id_venta]) REFERENCES [ventas] ([id_venta])
GO

ALTER TABLE [detalle_recetas] ADD FOREIGN KEY ([id_receta]) REFERENCES [recetas] ([id_receta])
GO

ALTER TABLE [detalle_recetas] ADD FOREIGN KEY ([id_producto]) REFERENCES [productos] ([id_producto])
GO

ALTER TABLE [ventas] ADD FOREIGN KEY ([id_empleado]) REFERENCES [empleados] ([id_empleado])
GO

ALTER TABLE [ventas] ADD FOREIGN KEY ([id_cliente]) REFERENCES [clientes] ([id_cliente])
GO

ALTER TABLE [ventas] ADD FOREIGN KEY ([id_usuario]) REFERENCES [usuarios] ([id_usuario])
GO

ALTER TABLE [ventas] ADD FOREIGN KEY ([id_receta]) REFERENCES [recetas] ([id_receta])
GO

ALTER TABLE [detalle_ventas] ADD FOREIGN KEY ([id_venta]) REFERENCES [ventas] ([id_venta])
GO

ALTER TABLE [detalle_ventas] ADD FOREIGN KEY ([id_producto]) REFERENCES [productos] ([id_producto])
GO

ALTER TABLE [detalle_ventas] ADD FOREIGN KEY ([id_lote]) REFERENCES [lotes] ([id_lote])
GO

ALTER TABLE [compras] ADD FOREIGN KEY ([id_proveedor]) REFERENCES [proveedores] ([id_proveedor])
GO

ALTER TABLE [compras] ADD FOREIGN KEY ([id_empleado]) REFERENCES [empleados] ([id_empleado])
GO

ALTER TABLE [compras] ADD FOREIGN KEY ([id_usuario]) REFERENCES [usuarios] ([id_usuario])
GO

ALTER TABLE [detalle_compras] ADD FOREIGN KEY ([id_compra]) REFERENCES [compras] ([id_compra])
GO

ALTER TABLE [detalle_compras] ADD FOREIGN KEY ([id_producto]) REFERENCES [productos] ([id_producto])
GO

ALTER TABLE [detalle_compras] ADD FOREIGN KEY ([id_lote]) REFERENCES [lotes] ([id_lote])
GO

ALTER TABLE [kardex] ADD FOREIGN KEY ([id_producto]) REFERENCES [productos] ([id_producto])
GO

ALTER TABLE [kardex] ADD FOREIGN KEY ([id_lote]) REFERENCES [lotes] ([id_lote])
GO

ALTER TABLE [kardex] ADD FOREIGN KEY ([id_usuario]) REFERENCES [usuarios] ([id_usuario])
GO

ALTER TABLE [alertas_stock] ADD FOREIGN KEY ([id_producto]) REFERENCES [productos] ([id_producto])
GO

ALTER TABLE [alertas_stock] ADD FOREIGN KEY ([id_lote]) REFERENCES [lotes] ([id_lote])
GO

ALTER TABLE [alertas_stock] ADD FOREIGN KEY ([id_usuario_resolucion]) REFERENCES [usuarios] ([id_usuario])
GO
