/* ============================================================
   11. SEED DE DATOS DE DESARROLLO
   Re-ejecutable: cada bloque valida existencia por su llave natural
   antes de insertar (IF NOT EXISTS / WHERE NOT EXISTS).

   Usuarios de prueba (misma password para los 3, solo para desarrollo):
     admin / farmaceutico1 / cajero1   ->  password: Admin123!
   ============================================================ */

USE PharmaInventory;
GO

/* ---------- Roles ---------- */
IF NOT EXISTS (SELECT 1 FROM roles WHERE nombre_rol = 'Administrador')
    INSERT INTO roles (nombre_rol, descripcion) VALUES ('Administrador', 'Acceso total al sistema');
IF NOT EXISTS (SELECT 1 FROM roles WHERE nombre_rol = 'Farmaceutico')
    INSERT INTO roles (nombre_rol, descripcion) VALUES ('Farmaceutico', 'Operacion diaria: inventario, ventas, recetas, compras');
IF NOT EXISTS (SELECT 1 FROM roles WHERE nombre_rol = 'Cajero')
    INSERT INTO roles (nombre_rol, descripcion) VALUES ('Cajero', 'Solo ventas y consulta de clientes/productos');
GO

/* ---------- Permisos (modulo, accion) alineados a los endpoints de la seccion 4 ---------- */
;WITH nuevos_permisos (modulo, accion, descripcion) AS (
    SELECT * FROM (VALUES
        ('usuarios','listar','Listar usuarios'), ('usuarios','ver','Ver detalle de usuario'),
        ('usuarios','crear','Crear usuario'), ('usuarios','editar','Editar usuario'), ('usuarios','eliminar','Desactivar usuario'),

        ('roles','listar','Listar roles'), ('roles','ver','Ver detalle de rol'),
        ('roles','crear','Crear rol'), ('roles','editar','Editar rol'), ('roles','eliminar','Eliminar rol'),

        ('permisos','listar','Listar permisos'), ('permisos','ver','Ver detalle de permiso'),
        ('permisos','crear','Crear permiso'), ('permisos','editar','Editar permiso'), ('permisos','eliminar','Eliminar permiso'),

        ('empleados','listar','Listar empleados'), ('empleados','ver','Ver detalle de empleado'),
        ('empleados','crear','Crear empleado'), ('empleados','editar','Editar empleado'), ('empleados','eliminar','Eliminar empleado'),

        ('categorias','listar','Listar categorias'), ('categorias','ver','Ver categoria'),
        ('categorias','crear','Crear categoria'), ('categorias','editar','Editar categoria'), ('categorias','eliminar','Eliminar categoria'),

        ('proveedores','listar','Listar proveedores'), ('proveedores','ver','Ver proveedor'),
        ('proveedores','crear','Crear proveedor'), ('proveedores','editar','Editar proveedor'), ('proveedores','eliminar','Eliminar proveedor'),

        ('laboratorios','listar','Listar laboratorios'), ('laboratorios','ver','Ver laboratorio'),
        ('laboratorios','crear','Crear laboratorio'), ('laboratorios','editar','Editar laboratorio'), ('laboratorios','eliminar','Eliminar laboratorio'),

        ('principios_activos','listar','Listar principios activos'), ('principios_activos','ver','Ver principio activo'),
        ('principios_activos','crear','Crear principio activo'), ('principios_activos','editar','Editar principio activo'), ('principios_activos','eliminar','Eliminar principio activo'),

        ('presentaciones','listar','Listar presentaciones'), ('presentaciones','ver','Ver presentacion'),
        ('presentaciones','crear','Crear presentacion'), ('presentaciones','editar','Editar presentacion'), ('presentaciones','eliminar','Eliminar presentacion'),

        ('productos','listar','Listar productos'), ('productos','ver','Ver producto'),
        ('productos','crear','Crear producto'), ('productos','editar','Editar producto'), ('productos','eliminar','Eliminar producto'),

        ('medicamentos','ver','Ver ficha de medicamento'), ('medicamentos','crear','Crear ficha de medicamento'), ('medicamentos','editar','Editar ficha de medicamento'),

        ('inventario','consultar','Consultar stock/kardex/alertas'), ('inventario','ajustar','Ajuste manual de inventario'),
        ('inventario','resolver_alerta','Resolver alertas de stock'),

        ('clientes','listar','Listar clientes'), ('clientes','ver','Ver cliente'),
        ('clientes','crear','Crear cliente'), ('clientes','editar','Editar cliente'), ('clientes','eliminar','Eliminar cliente'),

        ('recetas','listar','Listar recetas'), ('recetas','ver','Ver receta'), ('recetas','crear','Registrar receta'),

        ('ventas','listar','Listar ventas'), ('ventas','ver','Ver venta'),
        ('ventas','crear','Registrar venta'), ('ventas','anular','Anular venta'),

        ('compras','listar','Listar compras'), ('compras','ver','Ver compra'), ('compras','crear','Registrar compra'),
        ('compras','recibir','Recibir compra'), ('compras','anular','Anular compra')
    ) AS v(modulo, accion, descripcion)
)
INSERT INTO permisos (modulo, accion, descripcion)
SELECT np.modulo, np.accion, np.descripcion
FROM nuevos_permisos np
WHERE NOT EXISTS (SELECT 1 FROM permisos p WHERE p.modulo = np.modulo AND p.accion = np.accion);
GO

/* ---------- rol_permisos ---------- */
-- Administrador: todos los permisos
INSERT INTO rol_permisos (id_rol, id_permiso)
SELECT r.id_rol, p.id_permiso
FROM roles r CROSS JOIN permisos p
WHERE r.nombre_rol = 'Administrador'
  AND NOT EXISTS (SELECT 1 FROM rol_permisos rp WHERE rp.id_rol = r.id_rol AND rp.id_permiso = p.id_permiso);

-- Farmaceutico: todo excepto gestion de usuarios/roles/permisos
INSERT INTO rol_permisos (id_rol, id_permiso)
SELECT r.id_rol, p.id_permiso
FROM roles r CROSS JOIN permisos p
WHERE r.nombre_rol = 'Farmaceutico'
  AND p.modulo NOT IN ('usuarios','roles','permisos')
  AND NOT EXISTS (SELECT 1 FROM rol_permisos rp WHERE rp.id_rol = r.id_rol AND rp.id_permiso = p.id_permiso);

-- Cajero: ventas, clientes, consulta de recetas/productos/inventario
INSERT INTO rol_permisos (id_rol, id_permiso)
SELECT r.id_rol, p.id_permiso
FROM roles r CROSS JOIN permisos p
WHERE r.nombre_rol = 'Cajero'
  AND ( (p.modulo = 'ventas' AND p.accion IN ('listar','ver','crear'))
     OR (p.modulo = 'clientes' AND p.accion IN ('listar','ver','crear'))
     OR (p.modulo = 'recetas' AND p.accion IN ('listar','ver'))
     OR (p.modulo = 'productos' AND p.accion IN ('listar','ver'))
     OR (p.modulo = 'inventario' AND p.accion = 'consultar') )
  AND NOT EXISTS (SELECT 1 FROM rol_permisos rp WHERE rp.id_rol = r.id_rol AND rp.id_permiso = p.id_permiso);
GO

/* ---------- Empleados + usuarios de prueba ----------
   Password para los 3: Admin123!
   Hash BCrypt ($2b$, 11 rounds) generado una vez con python3-bcrypt;
   BCrypt.Net-Next (capa Infrastructure) verifica $2a$/$2b$/$2y$ por igual. */
DECLARE @hash_dev NVARCHAR(255) = N'$2b$11$Q/Yd60Xqhn4syABG2m7JYO5V.4iv2KJxLXZXuHP7iLVOBhDpxNr3.';

IF NOT EXISTS (SELECT 1 FROM empleados WHERE email = 'admin@farmacia.cr')
    INSERT INTO empleados (nombre_completo, cargo, email) VALUES ('Ana Sofia Rodriguez Mora', 'Administradora de Sistema', 'admin@farmacia.cr');
IF NOT EXISTS (SELECT 1 FROM empleados WHERE email = 'farmaceutico1@farmacia.cr')
    INSERT INTO empleados (nombre_completo, cargo, email) VALUES ('Carlos Andres Jimenez Solano', 'Farmaceutico', 'farmaceutico1@farmacia.cr');
IF NOT EXISTS (SELECT 1 FROM empleados WHERE email = 'cajero1@farmacia.cr')
    INSERT INTO empleados (nombre_completo, cargo, email) VALUES ('Maria Jose Vargas Castro', 'Cajera', 'cajero1@farmacia.cr');

IF NOT EXISTS (SELECT 1 FROM usuarios WHERE nombre_usuario = 'admin')
    INSERT INTO usuarios (nombre_usuario, email, password_hash, id_rol, id_empleado, activo, creado_en)
    SELECT 'admin', 'admin@farmacia.cr', @hash_dev, r.id_rol, e.id_empleado, 1, SYSDATETIME()
    FROM roles r, empleados e
    WHERE r.nombre_rol = 'Administrador' AND e.email = 'admin@farmacia.cr';

IF NOT EXISTS (SELECT 1 FROM usuarios WHERE nombre_usuario = 'farmaceutico1')
    INSERT INTO usuarios (nombre_usuario, email, password_hash, id_rol, id_empleado, activo, creado_en)
    SELECT 'farmaceutico1', 'farmaceutico1@farmacia.cr', @hash_dev, r.id_rol, e.id_empleado, 1, SYSDATETIME()
    FROM roles r, empleados e
    WHERE r.nombre_rol = 'Farmaceutico' AND e.email = 'farmaceutico1@farmacia.cr';

IF NOT EXISTS (SELECT 1 FROM usuarios WHERE nombre_usuario = 'cajero1')
    INSERT INTO usuarios (nombre_usuario, email, password_hash, id_rol, id_empleado, activo, creado_en)
    SELECT 'cajero1', 'cajero1@farmacia.cr', @hash_dev, r.id_rol, e.id_empleado, 1, SYSDATETIME()
    FROM roles r, empleados e
    WHERE r.nombre_rol = 'Cajero' AND e.email = 'cajero1@farmacia.cr';
GO

/* ---------- Catalogos base ---------- */
;WITH nuevas_categorias (nombre_categoria, descripcion) AS (
    SELECT * FROM (VALUES
        ('Analgesicos','Medicamentos para el dolor'),
        ('Antibioticos','Medicamentos antibacterianos'),
        ('Antihistaminicos','Medicamentos para alergias'),
        ('Antiinflamatorios','Medicamentos antiinflamatorios'),
        ('Vitaminas y Suplementos','Suplementos nutricionales'),
        ('Gastrointestinal','Medicamentos para el sistema digestivo'),
        ('Sistema Nervioso Central','Medicamentos que actuan sobre el SNC')
    ) AS v(nombre_categoria, descripcion)
)
INSERT INTO categorias (nombre_categoria, descripcion)
SELECT nc.nombre_categoria, nc.descripcion FROM nuevas_categorias nc
WHERE NOT EXISTS (SELECT 1 FROM categorias c WHERE c.nombre_categoria = nc.nombre_categoria);

;WITH nuevos_proveedores (nombre_empresa, contacto_nombre, telefono, email) AS (
    SELECT * FROM (VALUES
        ('Distribuidora Farmaceutica CR S.A.','Luis Fernando Mora','2222-1010','ventas@disfarmacr.co.cr'),
        ('Corporacion Fischel','Patricia Elena Solis','2233-4040','contacto@fischel.co.cr'),
        ('Drogueria Los Andes','Roberto Alfaro Nunez','2244-5050','info@losandes.co.cr')
    ) AS v(nombre_empresa, contacto_nombre, telefono, email)
)
INSERT INTO proveedores (nombre_empresa, contacto_nombre, telefono, email)
SELECT np.nombre_empresa, np.contacto_nombre, np.telefono, np.email FROM nuevos_proveedores np
WHERE NOT EXISTS (SELECT 1 FROM proveedores p WHERE p.nombre_empresa = np.nombre_empresa);

;WITH nuevos_laboratorios (nombre, pais_origen, telefono, email, sitio_web) AS (
    SELECT * FROM (VALUES
        ('Laboratorios Bayer','Alemania','2211-3030','contacto@bayer.com','https://www.bayer.com'),
        ('Roche Costa Rica','Suiza','2211-3131','contacto@roche.co.cr','https://www.roche.co.cr'),
        ('Stein Pharma','Costa Rica','2211-3232','contacto@stein.co.cr','https://www.stein.co.cr')
    ) AS v(nombre, pais_origen, telefono, email, sitio_web)
)
INSERT INTO laboratorios (nombre, pais_origen, telefono, email, sitio_web)
SELECT nl.nombre, nl.pais_origen, nl.telefono, nl.email, nl.sitio_web FROM nuevos_laboratorios nl
WHERE NOT EXISTS (SELECT 1 FROM laboratorios l WHERE l.nombre = nl.nombre);

;WITH nuevos_principios (nombre_inn, grupo_terapeutico, descripcion) AS (
    SELECT * FROM (VALUES
        ('Paracetamol','Analgesico/Antipiretico','Alivio del dolor leve a moderado y fiebre'),
        ('Ibuprofeno','Antiinflamatorio no esteroideo','AINE para dolor e inflamacion'),
        ('Amoxicilina','Antibiotico betalactamico','Antibiotico de amplio espectro'),
        ('Loratadina','Antihistaminico','Alivio de sintomas alergicos'),
        ('Omeprazol','Inhibidor de la bomba de protones','Reduccion de acidez gastrica')
    ) AS v(nombre_inn, grupo_terapeutico, descripcion)
)
INSERT INTO principios_activos (nombre_inn, grupo_terapeutico, descripcion)
SELECT np.nombre_inn, np.grupo_terapeutico, np.descripcion FROM nuevos_principios np
WHERE NOT EXISTS (SELECT 1 FROM principios_activos pa WHERE pa.nombre_inn = np.nombre_inn);

;WITH nuevas_presentaciones (forma, unidad_medida) AS (
    SELECT * FROM (VALUES
        ('Tableta','mg'), ('Capsula','mg'), ('Jarabe','ml'), ('Ampolla','mg/ml'), ('Crema','%')
    ) AS v(forma, unidad_medida)
)
INSERT INTO presentaciones (forma, unidad_medida)
SELECT np.forma, np.unidad_medida FROM nuevas_presentaciones np
WHERE NOT EXISTS (SELECT 1 FROM presentaciones pr WHERE pr.forma = np.forma);
GO

/* ---------- Productos + fichas de medicamento ---------- */
DECLARE @cat_analgesicos INT = (SELECT id_categoria FROM categorias WHERE nombre_categoria = 'Analgesicos');
DECLARE @cat_antibioticos INT = (SELECT id_categoria FROM categorias WHERE nombre_categoria = 'Antibioticos');
DECLARE @cat_antihistaminicos INT = (SELECT id_categoria FROM categorias WHERE nombre_categoria = 'Antihistaminicos');
DECLARE @cat_antiinflamatorios INT = (SELECT id_categoria FROM categorias WHERE nombre_categoria = 'Antiinflamatorios');
DECLARE @cat_vitaminas INT = (SELECT id_categoria FROM categorias WHERE nombre_categoria = 'Vitaminas y Suplementos');
DECLARE @cat_gastro INT = (SELECT id_categoria FROM categorias WHERE nombre_categoria = 'Gastrointestinal');
DECLARE @cat_snc INT = (SELECT id_categoria FROM categorias WHERE nombre_categoria = 'Sistema Nervioso Central');

DECLARE @prov1 INT = (SELECT id_proveedor FROM proveedores WHERE nombre_empresa = 'Distribuidora Farmaceutica CR S.A.');
DECLARE @lab_bayer INT = (SELECT id_laboratorio FROM laboratorios WHERE nombre = 'Laboratorios Bayer');
DECLARE @lab_roche INT = (SELECT id_laboratorio FROM laboratorios WHERE nombre = 'Roche Costa Rica');
DECLARE @lab_stein INT = (SELECT id_laboratorio FROM laboratorios WHERE nombre = 'Stein Pharma');

DECLARE @pres_tableta INT = (SELECT id_presentacion FROM presentaciones WHERE forma = 'Tableta');
DECLARE @pres_capsula INT = (SELECT id_presentacion FROM presentaciones WHERE forma = 'Capsula');
DECLARE @pres_jarabe INT = (SELECT id_presentacion FROM presentaciones WHERE forma = 'Jarabe');
DECLARE @pres_ampolla INT = (SELECT id_presentacion FROM presentaciones WHERE forma = 'Ampolla');
DECLARE @pres_crema INT = (SELECT id_presentacion FROM presentaciones WHERE forma = 'Crema');

DECLARE @id_out INT;

IF NOT EXISTS (SELECT 1 FROM productos WHERE codigo_sku = 'PARA500')
    EXEC sp_Producto_Insertar
        @nombre = 'Paracetamol 500mg', @nombre_generico = 'Paracetamol', @codigo_sku = 'PARA500', @codigo_barras = '7501000000001',
        @precio_costo = 1200.00, @precio_venta = 2000.00, @stock_minimo = 30, @requiere_receta = 0,
        @id_categoria = @cat_analgesicos, @id_proveedor = @prov1, @id_laboratorio = @lab_bayer, @id_presentacion = @pres_tableta,
        @id_producto_creado = @id_out OUTPUT;

IF NOT EXISTS (SELECT 1 FROM productos WHERE codigo_sku = 'IBU400')
    EXEC sp_Producto_Insertar
        @nombre = 'Ibuprofeno 400mg', @nombre_generico = 'Ibuprofeno', @codigo_sku = 'IBU400', @codigo_barras = '7501000000002',
        @precio_costo = 1500.00, @precio_venta = 2500.00, @stock_minimo = 30, @requiere_receta = 0,
        @id_categoria = @cat_antiinflamatorios, @id_proveedor = @prov1, @id_laboratorio = @lab_bayer, @id_presentacion = @pres_tableta,
        @id_producto_creado = @id_out OUTPUT;

IF NOT EXISTS (SELECT 1 FROM productos WHERE codigo_sku = 'AMOX500')
    EXEC sp_Producto_Insertar
        @nombre = 'Amoxicilina 500mg', @nombre_generico = 'Amoxicilina', @codigo_sku = 'AMOX500', @codigo_barras = '7501000000003',
        @precio_costo = 3200.00, @precio_venta = 5500.00, @stock_minimo = 20, @requiere_receta = 1,
        @id_categoria = @cat_antibioticos, @id_proveedor = @prov1, @id_laboratorio = @lab_stein, @id_presentacion = @pres_capsula,
        @id_producto_creado = @id_out OUTPUT;

IF NOT EXISTS (SELECT 1 FROM productos WHERE codigo_sku = 'LORA10')
    EXEC sp_Producto_Insertar
        @nombre = 'Loratadina 10mg', @nombre_generico = 'Loratadina', @codigo_sku = 'LORA10', @codigo_barras = '7501000000004',
        @precio_costo = 1800.00, @precio_venta = 3000.00, @stock_minimo = 20, @requiere_receta = 0,
        @id_categoria = @cat_antihistaminicos, @id_proveedor = @prov1, @id_laboratorio = @lab_stein, @id_presentacion = @pres_tableta,
        @id_producto_creado = @id_out OUTPUT;

IF NOT EXISTS (SELECT 1 FROM productos WHERE codigo_sku = 'OMEP20')
    EXEC sp_Producto_Insertar
        @nombre = 'Omeprazol 20mg', @nombre_generico = 'Omeprazol', @codigo_sku = 'OMEP20', @codigo_barras = '7501000000005',
        @precio_costo = 2400.00, @precio_venta = 4000.00, @stock_minimo = 20, @requiere_receta = 0,
        @id_categoria = @cat_gastro, @id_proveedor = @prov1, @id_laboratorio = @lab_stein, @id_presentacion = @pres_capsula,
        @id_producto_creado = @id_out OUTPUT;

IF NOT EXISTS (SELECT 1 FROM productos WHERE codigo_sku = 'DIAZ5')
    EXEC sp_Producto_Insertar
        @nombre = 'Diazepam 5mg', @nombre_generico = 'Diazepam', @codigo_sku = 'DIAZ5', @codigo_barras = '7501000000006',
        @precio_costo = 2000.00, @precio_venta = 3500.00, @stock_minimo = 10, @requiere_receta = 1,
        @id_categoria = @cat_snc, @id_proveedor = @prov1, @id_laboratorio = @lab_roche, @id_presentacion = @pres_tableta,
        @id_producto_creado = @id_out OUTPUT;

IF NOT EXISTS (SELECT 1 FROM productos WHERE codigo_sku = 'MORF10')
    EXEC sp_Producto_Insertar
        @nombre = 'Morfina 10mg/ml Ampolla', @nombre_generico = 'Morfina', @codigo_sku = 'MORF10', @codigo_barras = '7501000000007',
        @precio_costo = 4500.00, @precio_venta = 7500.00, @stock_minimo = 10, @requiere_receta = 1,
        @id_categoria = @cat_snc, @id_proveedor = @prov1, @id_laboratorio = @lab_roche, @id_presentacion = @pres_ampolla,
        @id_producto_creado = @id_out OUTPUT;

IF NOT EXISTS (SELECT 1 FROM productos WHERE codigo_sku = 'VITC1000')
    EXEC sp_Producto_Insertar
        @nombre = 'Vitamina C 1000mg', @nombre_generico = 'Acido Ascorbico', @codigo_sku = 'VITC1000', @codigo_barras = '7501000000008',
        @precio_costo = 2800.00, @precio_venta = 4500.00, @stock_minimo = 20, @requiere_receta = 0,
        @id_categoria = @cat_vitaminas, @id_proveedor = @prov1, @id_laboratorio = @lab_bayer, @id_presentacion = @pres_tableta,
        @id_producto_creado = @id_out OUTPUT;

IF NOT EXISTS (SELECT 1 FROM productos WHERE codigo_sku = 'COMPB')
    EXEC sp_Producto_Insertar
        @nombre = 'Complejo B Jarabe', @nombre_generico = 'Complejo B', @codigo_sku = 'COMPB', @codigo_barras = '7501000000009',
        @precio_costo = 2600.00, @precio_venta = 4200.00, @stock_minimo = 15, @requiere_receta = 0,
        @id_categoria = @cat_vitaminas, @id_proveedor = @prov1, @id_laboratorio = @lab_bayer, @id_presentacion = @pres_jarabe,
        @id_producto_creado = @id_out OUTPUT;

IF NOT EXISTS (SELECT 1 FROM productos WHERE codigo_sku = 'HIDROCORT1')
    EXEC sp_Producto_Insertar
        @nombre = 'Crema Hidrocortisona 1%', @nombre_generico = 'Hidrocortisona', @codigo_sku = 'HIDROCORT1', @codigo_barras = '7501000000010',
        @precio_costo = 1900.00, @precio_venta = 3200.00, @stock_minimo = 15, @requiere_receta = 0,
        @id_categoria = @cat_antiinflamatorios, @id_proveedor = @prov1, @id_laboratorio = @lab_stein, @id_presentacion = @pres_crema,
        @id_producto_creado = @id_out OUTPUT;
GO

/* ---------- Fichas de medicamento + principios activos ---------- */
DECLARE @p_para INT = (SELECT id_producto FROM productos WHERE codigo_sku = 'PARA500');
DECLARE @p_ibu  INT = (SELECT id_producto FROM productos WHERE codigo_sku = 'IBU400');
DECLARE @p_amox INT = (SELECT id_producto FROM productos WHERE codigo_sku = 'AMOX500');
DECLARE @p_lora INT = (SELECT id_producto FROM productos WHERE codigo_sku = 'LORA10');
DECLARE @p_omep INT = (SELECT id_producto FROM productos WHERE codigo_sku = 'OMEP20');
DECLARE @p_diaz INT = (SELECT id_producto FROM productos WHERE codigo_sku = 'DIAZ5');
DECLARE @p_morf INT = (SELECT id_producto FROM productos WHERE codigo_sku = 'MORF10');
DECLARE @p_hidro INT = (SELECT id_producto FROM productos WHERE codigo_sku = 'HIDROCORT1');

IF NOT EXISTS (SELECT 1 FROM medicamentos WHERE id_producto = @p_para)
    EXEC sp_Medicamento_Insertar @id_producto=@p_para, @concentracion='500mg', @via_administracion='oral',
        @condiciones_almacenamiento='Temperatura ambiente', @controlado=0,
        @numero_registro_sanitario='CCSS-2020-0001', @indicaciones='Dolor leve a moderado, fiebre',
        @contraindicaciones='Insuficiencia hepatica severa', @efectos_secundarios='Raros a dosis terapeuticas',
        @interacciones='Warfarina (dosis altas prolongadas)';

IF NOT EXISTS (SELECT 1 FROM medicamentos WHERE id_producto = @p_ibu)
    EXEC sp_Medicamento_Insertar @id_producto=@p_ibu, @concentracion='400mg', @via_administracion='oral',
        @condiciones_almacenamiento='Temperatura ambiente', @controlado=0,
        @numero_registro_sanitario='CCSS-2020-0002', @indicaciones='Dolor e inflamacion',
        @contraindicaciones='Ulcera peptica activa', @efectos_secundarios='Molestias gastricas',
        @interacciones='Anticoagulantes, otros AINEs';

IF NOT EXISTS (SELECT 1 FROM medicamentos WHERE id_producto = @p_amox)
    EXEC sp_Medicamento_Insertar @id_producto=@p_amox, @concentracion='500mg', @via_administracion='oral',
        @condiciones_almacenamiento='Temperatura ambiente', @controlado=0,
        @numero_registro_sanitario='CCSS-2020-0003', @indicaciones='Infecciones bacterianas sensibles a amoxicilina',
        @contraindicaciones='Alergia a betalactamicos', @efectos_secundarios='Diarrea, rash',
        @interacciones='Alopurinol, anticonceptivos orales';

IF NOT EXISTS (SELECT 1 FROM medicamentos WHERE id_producto = @p_lora)
    EXEC sp_Medicamento_Insertar @id_producto=@p_lora, @concentracion='10mg', @via_administracion='oral',
        @condiciones_almacenamiento='Temperatura ambiente', @controlado=0,
        @numero_registro_sanitario='CCSS-2020-0004', @indicaciones='Rinitis alergica, urticaria',
        @contraindicaciones='Hipersensibilidad a loratadina', @efectos_secundarios='Somnolencia leve, cefalea',
        @interacciones='Ketoconazol, eritromicina';

IF NOT EXISTS (SELECT 1 FROM medicamentos WHERE id_producto = @p_omep)
    EXEC sp_Medicamento_Insertar @id_producto=@p_omep, @concentracion='20mg', @via_administracion='oral',
        @condiciones_almacenamiento='Temperatura ambiente', @controlado=0,
        @numero_registro_sanitario='CCSS-2020-0005', @indicaciones='Reflujo gastroesofagico, ulcera peptica',
        @contraindicaciones='Hipersensibilidad a inhibidores de bomba de protones', @efectos_secundarios='Cefalea, diarrea',
        @interacciones='Clopidogrel, warfarina';

IF NOT EXISTS (SELECT 1 FROM medicamentos WHERE id_producto = @p_diaz)
    EXEC sp_Medicamento_Insertar @id_producto=@p_diaz, @concentracion='5mg', @via_administracion='oral',
        @condiciones_almacenamiento='Temperatura ambiente, lugar seguro', @controlado=1,
        @numero_registro_sanitario='CCSS-2020-0006', @indicaciones='Ansiedad, espasmos musculares',
        @contraindicaciones='Miastenia gravis, insuficiencia respiratoria severa', @efectos_secundarios='Sedacion, dependencia',
        @interacciones='Alcohol, otros depresores del SNC';

IF NOT EXISTS (SELECT 1 FROM medicamentos WHERE id_producto = @p_morf)
    EXEC sp_Medicamento_Insertar @id_producto=@p_morf, @concentracion='10mg/ml', @via_administracion='intravenosa',
        @condiciones_almacenamiento='Refrigerar 2-8C, lugar seguro bajo llave', @controlado=1,
        @numero_registro_sanitario='CCSS-2020-0007', @indicaciones='Dolor severo agudo/oncologico',
        @contraindicaciones='Depresion respiratoria', @efectos_secundarios='Depresion respiratoria, dependencia',
        @interacciones='Otros opioides, depresores del SNC';

IF NOT EXISTS (SELECT 1 FROM medicamentos WHERE id_producto = @p_hidro)
    EXEC sp_Medicamento_Insertar @id_producto=@p_hidro, @concentracion='1%', @via_administracion='topica',
        @condiciones_almacenamiento='Temperatura ambiente', @controlado=0,
        @numero_registro_sanitario='CCSS-2020-0008', @indicaciones='Dermatitis, eczema leve',
        @contraindicaciones='Infeccion cutanea no tratada', @efectos_secundarios='Irritacion local',
        @interacciones='Ninguna relevante por via topica';
GO

DECLARE @med_para INT = (SELECT id_medicamento FROM medicamentos WHERE id_producto = (SELECT id_producto FROM productos WHERE codigo_sku='PARA500'));
DECLARE @med_ibu  INT = (SELECT id_medicamento FROM medicamentos WHERE id_producto = (SELECT id_producto FROM productos WHERE codigo_sku='IBU400'));
DECLARE @med_amox INT = (SELECT id_medicamento FROM medicamentos WHERE id_producto = (SELECT id_producto FROM productos WHERE codigo_sku='AMOX500'));
DECLARE @med_lora INT = (SELECT id_medicamento FROM medicamentos WHERE id_producto = (SELECT id_producto FROM productos WHERE codigo_sku='LORA10'));
DECLARE @med_omep INT = (SELECT id_medicamento FROM medicamentos WHERE id_producto = (SELECT id_producto FROM productos WHERE codigo_sku='OMEP20'));

DECLARE @prin_para INT = (SELECT id_principio FROM principios_activos WHERE nombre_inn = 'Paracetamol');
DECLARE @prin_ibu  INT = (SELECT id_principio FROM principios_activos WHERE nombre_inn = 'Ibuprofeno');
DECLARE @prin_amox INT = (SELECT id_principio FROM principios_activos WHERE nombre_inn = 'Amoxicilina');
DECLARE @prin_lora INT = (SELECT id_principio FROM principios_activos WHERE nombre_inn = 'Loratadina');
DECLARE @prin_omep INT = (SELECT id_principio FROM principios_activos WHERE nombre_inn = 'Omeprazol');

EXEC sp_MedicamentoPrincipio_Asignar @id_medicamento=@med_para, @id_principio=@prin_para, @cantidad_por_dosis=500, @unidad='mg';
EXEC sp_MedicamentoPrincipio_Asignar @id_medicamento=@med_ibu,  @id_principio=@prin_ibu,  @cantidad_por_dosis=400, @unidad='mg';
EXEC sp_MedicamentoPrincipio_Asignar @id_medicamento=@med_amox, @id_principio=@prin_amox, @cantidad_por_dosis=500, @unidad='mg';
EXEC sp_MedicamentoPrincipio_Asignar @id_medicamento=@med_lora, @id_principio=@prin_lora, @cantidad_por_dosis=10,  @unidad='mg';
EXEC sp_MedicamentoPrincipio_Asignar @id_medicamento=@med_omep, @id_principio=@prin_omep, @cantidad_por_dosis=20,  @unidad='mg';
GO

/* ---------- Stock inicial: compra real recibida via el flujo completo ----------
   Ejercita sp_Compra_Registrar + sp_Compra_Recibir con el fix de B4
   (id_detalle) como parte del propio seed. */
IF NOT EXISTS (SELECT 1 FROM compras)
BEGIN
    DECLARE @id_proveedor_seed INT = (SELECT id_proveedor FROM proveedores WHERE nombre_empresa = 'Distribuidora Farmaceutica CR S.A.');
    DECLARE @id_empleado_seed INT = (SELECT id_empleado FROM empleados WHERE email = 'admin@farmacia.cr');
    DECLARE @id_usuario_seed INT = (SELECT id_usuario FROM usuarios WHERE nombre_usuario = 'admin');

    DECLARE @detalle_compra dbo.TipoDetalleCompra;
    INSERT INTO @detalle_compra (id_producto, cantidad, precio_unitario, numero_lote, fecha_fabricacion, fecha_vencimiento)
    SELECT id_producto, 100, precio_costo,
           'LOTE-INI-' + CAST(id_producto AS NVARCHAR(10)),
           DATEADD(MONTH, -3, CAST(GETDATE() AS DATE)),
           DATEADD(MONTH, 18, CAST(GETDATE() AS DATE))
    FROM productos;

    DECLARE @id_compra_creada INT;
    EXEC sp_Compra_Registrar
        @id_proveedor = @id_proveedor_seed, @id_empleado = @id_empleado_seed, @id_usuario = @id_usuario_seed,
        @detalle = @detalle_compra, @id_compra_creada = @id_compra_creada OUTPUT;

    DECLARE @detalle_recibir dbo.TipoDetalleCompra;
    INSERT INTO @detalle_recibir (id_detalle, id_producto, cantidad, precio_unitario, numero_lote, fecha_fabricacion, fecha_vencimiento)
    SELECT dc.id_detalle, dc.id_producto, dc.cantidad, dc.precio_unitario,
           'LOTE-INI-' + CAST(dc.id_producto AS NVARCHAR(10)),
           DATEADD(MONTH, -3, CAST(GETDATE() AS DATE)),
           DATEADD(MONTH, 18, CAST(GETDATE() AS DATE))
    FROM detalle_compras dc
    WHERE dc.id_compra = @id_compra_creada;

    EXEC sp_Compra_Recibir
        @id_compra = @id_compra_creada, @id_usuario = @id_usuario_seed, @detalle = @detalle_recibir;

    -- Segundo lote de Paracetamol que vence pronto, para poblar vw_ProductosPorVencer
    DECLARE @p_para_seed INT = (SELECT id_producto FROM productos WHERE codigo_sku = 'PARA500');
    DECLARE @detalle_compra2 dbo.TipoDetalleCompra;
    INSERT INTO @detalle_compra2 (id_producto, cantidad, precio_unitario, numero_lote, fecha_fabricacion, fecha_vencimiento)
    VALUES (@p_para_seed, 20, 1200.00, 'LOTE-VENCE-PRONTO', DATEADD(MONTH, -6, CAST(GETDATE() AS DATE)), DATEADD(DAY, 20, CAST(GETDATE() AS DATE)));

    DECLARE @id_compra_creada2 INT;
    EXEC sp_Compra_Registrar
        @id_proveedor = @id_proveedor_seed, @id_empleado = @id_empleado_seed, @id_usuario = @id_usuario_seed,
        @detalle = @detalle_compra2, @id_compra_creada = @id_compra_creada2 OUTPUT;

    DECLARE @detalle_recibir2 dbo.TipoDetalleCompra;
    INSERT INTO @detalle_recibir2 (id_detalle, id_producto, cantidad, precio_unitario, numero_lote, fecha_fabricacion, fecha_vencimiento)
    SELECT dc.id_detalle, dc.id_producto, dc.cantidad, dc.precio_unitario, 'LOTE-VENCE-PRONTO',
           DATEADD(MONTH, -6, CAST(GETDATE() AS DATE)), DATEADD(DAY, 20, CAST(GETDATE() AS DATE))
    FROM detalle_compras dc WHERE dc.id_compra = @id_compra_creada2;

    EXEC sp_Compra_Recibir
        @id_compra = @id_compra_creada2, @id_usuario = @id_usuario_seed, @detalle = @detalle_recibir2;
END
GO

/* ---------- Clientes + receta vigente ---------- */
DECLARE @id_out2 INT;

IF NOT EXISTS (SELECT 1 FROM clientes WHERE identificacion = '1-1111-1111')
    EXEC sp_Cliente_Insertar @nombre_completo='Marco Antonio Vindas Ureña', @identificacion='1-1111-1111',
        @telefono='8888-1111', @fecha_nacimiento='1985-04-12', @email='marco.vindas@example.com', @id_creado=@id_out2 OUTPUT;

IF NOT EXISTS (SELECT 1 FROM clientes WHERE identificacion = '2-2222-2222')
    EXEC sp_Cliente_Insertar @nombre_completo='Gabriela Isabel Chaves Rojas', @identificacion='2-2222-2222',
        @telefono='8888-2222', @fecha_nacimiento='1990-09-25', @email='gabriela.chaves@example.com', @id_creado=@id_out2 OUTPUT;
GO

IF NOT EXISTS (SELECT 1 FROM recetas WHERE numero_receta = 'RX-0001')
BEGIN
    DECLARE @id_cliente_rx INT = (SELECT id_cliente FROM clientes WHERE identificacion = '1-1111-1111');
    DECLARE @p_amox_rx INT = (SELECT id_producto FROM productos WHERE codigo_sku = 'AMOX500');

    DECLARE @detalle_receta dbo.TipoDetalleReceta;
    INSERT INTO @detalle_receta (id_producto, cantidad_prescrita, dosis, duracion_tratamiento)
    VALUES (@p_amox_rx, 21, '1 capsula cada 8 horas', '7 dias');

    DECLARE @id_receta_creada INT;
    EXEC sp_Receta_Registrar
        @numero_receta = 'RX-0001', @id_cliente = @id_cliente_rx,
        @nombre_medico = 'Dra. Silvia Ramirez Solano', @num_colegio_medico = 'MED-4521',
        @fecha_emision = '2026-07-20', @fecha_vencimiento = '2026-08-20',
        @notas = 'Tratamiento por infeccion de vias respiratorias', @detalle = @detalle_receta,
        @id_receta_creada = @id_receta_creada OUTPUT;
END
GO
