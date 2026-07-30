# SPEC — Sistema de Inventario de Farmacia
### API .NET Core | Acceso a datos 100% vía Stored Procedures, Functions y Views

> **Regla de oro del proyecto:** ninguna capa de la aplicación ejecuta SQL ad-hoc ni usa un ORM que traduzca LINQ a SQL contra las tablas. Todo `SELECT`, `INSERT`, `UPDATE`, `DELETE` pasa por un objeto de base de datos (SP, función o vista) ya existente o definido aquí. El esquema base es **`Proyecto_BD_2.sql`** — no se agregan tablas nuevas, solo objetos de acceso (procedimientos, funciones, vistas, índices de apoyo si hiciera falta).

---

## 1. Arquitectura general (.NET Core)

```
/src
  /PharmaInventory.Api            -> Controllers, middlewares, DI, Program.cs
  /PharmaInventory.Application    -> Interfaces de repos, Services, DTOs, Validators (FluentValidation)
  /PharmaInventory.Domain         -> Entidades POCO (1:1 con tablas), Enums, excepciones de dominio
  /PharmaInventory.Infrastructure -> Implementación de repos (Dapper), acceso a SPs/Views/Functions
  /PharmaInventory.Tests          -> Unit + Integration tests
```

**Reglas de capa:**

- **Domain**: solo POCOs que reflejan columnas de las tablas (`Producto`, `Lote`, `Venta`, etc.) + enums para los `CHECK` (`EstadoVenta`, `TipoMovimientoKardex`, `ViaAdministracion`, `TipoAlerta`). Sin lógica de negocio "gorda"; la lógica transaccional pesada (descuento de stock, FEFO, kardex, promedio ponderado) vive en los SPs, no en C#.
- **Application**: interfaces `IProductoRepository`, `IVentaService`, DTOs de entrada/salida, validación de forma (no de negocio — la de negocio la valida el SP y se traduce el error).
- **Infrastructure**: **Dapper** (no EF Core) para invocar exclusivamente SPs/Views/Functions con `CommandType.StoredProcedure`. Nunca `Query<T>("SELECT * FROM productos ...")`.
- **Api**: controllers delgados, delegan a services de Application.

**Manejo de errores de negocio desde SQL:** los SPs usan `THROW`/`RAISERROR` con códigos de error propios (rango 50000+) que la capa Infrastructure captura y mapea a excepciones tipadas (`StockInsuficienteException`, `RecetaVencidaException`, etc.) que el controller traduce a `4xx`.

```csharp
// Ejemplo patrón de repositorio (Infrastructure)
public class ProductoRepository : IProductoRepository
{
    private readonly IDbConnection _db;

    public async Task<ProductoDto?> ObtenerPorIdAsync(int idProducto)
    {
        var p = new DynamicParameters();
        p.Add("@id_producto", idProducto);
        var result = await _db.QuerySingleOrDefaultAsync<ProductoDto>(
            "sp_Producto_ObtenerPorId", p, commandType: CommandType.StoredProcedure);
        return result;
    }
}
```

---

## 2. Convenciones de nomenclatura de objetos de BD

| Tipo | Prefijo | Ejemplo |
|---|---|---|
| Stored Procedure | `sp_<Entidad>_<Accion>` | `sp_Producto_Insertar` |
| Función escalar | `fn_<Proposito>` | `fn_ObtenerLoteFEFO` |
| Función de tabla (TVF) | `fn_<Proposito>Tabla` | `fn_KardexPorProductoTabla` |
| Vista | `vw_<Proposito>` | `vw_StockActual` |
| Parámetro de salida de error | `@codigo_error OUTPUT`, `@mensaje_error OUTPUT` | — |

Todos los SPs de escritura devuelven, como mínimo: `@id_generado` (cuando aplica) y usan `TRY/CATCH` con `THROW`.

---

## 3. Módulos y objetos de base de datos requeridos

### 3.1 Seguridad y Accesos
**Tablas:** `roles`, `permisos`, `rol_permisos`, `usuarios`, `empleados`

| Objeto | Tipo | Descripción |
|---|---|---|
| `sp_Usuario_Autenticar` | SP | Recibe `@nombre_usuario`; retorna fila de `usuarios` + `nombre_rol` para que la API valide el hash y arme el JWT/claims. Actualiza `ultimo_acceso`. |
| `sp_Usuario_Insertar` / `_Actualizar` / `_Desactivar` | SP | CRUD de usuarios (Desactivar = soft delete vía `activo = 0`) |
| `sp_Rol_Insertar` / `_Actualizar` / `_Eliminar` | SP | CRUD de roles |
| `sp_Permiso_AsignarARol` / `_RevocarDeRol` | SP | Maneja `rol_permisos` |
| `vw_UsuarioPermisos` | Vista | JOIN `usuarios` → `roles` → `rol_permisos` → `permisos`, para que el middleware de autorización resuelva permisos por módulo/acción en una sola consulta |
| `sp_Empleado_Insertar` / `_Actualizar` / `_Eliminar` | SP | CRUD de empleados |
| `vw_Empleados` | Vista | Listado simple |

### 3.2 Catálogos base
**Tablas:** `categorias`, `proveedores`, `laboratorios`, `principios_activos`, `presentaciones`

| Objeto | Tipo | Descripción |
|---|---|---|
| `sp_Categoria_Insertar/_Actualizar/_Eliminar` | SP | CRUD |
| `sp_Proveedor_Insertar/_Actualizar/_Eliminar` | SP | CRUD |
| `sp_Laboratorio_Insertar/_Actualizar/_Eliminar` | SP | CRUD |
| `sp_PrincipioActivo_Insertar/_Actualizar/_Eliminar` | SP | CRUD |
| `sp_Presentacion_Insertar/_Actualizar/_Eliminar` | SP | CRUD |
| `vw_Categorias`, `vw_Proveedores`, `vw_Laboratorios`, `vw_PrincipiosActivos`, `vw_Presentaciones` | Vista | Listados para combos/tablas del front |

### 3.3 Productos y Medicamentos
**Tablas:** `productos`, `medicamentos`, `medicamento_principios`

| Objeto | Tipo | Descripción |
|---|---|---|
| `sp_Producto_Insertar` | SP | Crea fila en `productos`; valida `codigo_sku`/`codigo_barras` únicos vía `TRY/CATCH` (o `IF EXISTS` antes de insertar) |
| `sp_Producto_Actualizar` | SP | Actualiza datos maestros (no toca `stock_actual`, eso solo lo mueve el kardex) |
| `sp_Producto_Eliminar` | SP | Soft delete o bloqueo si tiene movimientos (`IF EXISTS` en `kardex`/`lotes`) |
| `sp_Producto_ObtenerPorId` | SP | Detalle completo, incluye `medicamentos` si `requiere_receta = 1` (LEFT JOIN) |
| `sp_Medicamento_Insertar/_Actualizar` | SP | CRUD de ficha clínica (1:1 con producto) |
| `sp_MedicamentoPrincipio_Asignar/_Quitar` | SP | Maneja tabla N:M `medicamento_principios` |
| `vw_Productos` | Vista | Catálogo con joins a categoría/proveedor/laboratorio/presentación, para grillas |
| `vw_ProductosMedicamentos` | Vista | `productos` + `medicamentos` + `principios_activos` agregados (para ficha técnica) |
| `fn_ValidarSkuUnico` | Función escalar | Reutilizable desde varios SPs |

### 3.4 Inventario (núcleo del sistema)
**Tablas:** `lotes`, `kardex`, `alertas_stock`

| Objeto | Tipo | Descripción |
|---|---|---|
| `sp_Lote_Insertar` | SP | Se invoca **desde** `sp_Compra_Recibir` (no expuesto suelto salvo ajustes manuales); crea lote, `cantidad_actual = cantidad_inicial` |
| `fn_ObtenerLoteFEFO` | Función escalar/TVF | Dado `@id_producto` y `@cantidad_requerida`, retorna el/los lotes a descontar siguiendo **First-Expired-First-Out** (`fecha_vencimiento ASC`, `activo = 1`, `cantidad_actual > 0`) |
| `sp_Kardex_RegistrarMovimiento` | SP | Núcleo transaccional: inserta en `kardex`, recalcula `saldo_stock`, `precio_promedio_pond`, `saldo_valorado`; actualiza `productos.stock_actual` y `productos.precio_promedio_pond`. Se llama internamente desde compras, ventas y ajustes — **no se expone como endpoint libre de escritura de stock**, solo el tipo `'ajuste'` se expone a un endpoint de "ajuste manual de inventario" con permiso especial. |
| `fn_CalcularPrecioPromedioPonderado` | Función escalar | `(saldo_valorado_actual + costo_entrada) / (saldo_stock_actual + cantidad_entrada)` |
| `sp_Inventario_AjusteManual` | SP | Movimiento tipo `'ajuste'` (mermas, conteos físicos), requiere `@id_usuario` y `@motivo` |
| `vw_StockActual` | Vista | `productos` + suma de `lotes.cantidad_actual` agrupado, comparado contra `stock_minimo` |
| `vw_ProductosPorVencer` | Vista | `lotes` con `fecha_vencimiento` dentro de N días (parámetro vía función o filtro en la app), `activo = 1`, `cantidad_actual > 0` |
| `vw_KardexProducto` | Vista | Historial de movimientos por producto, ordenado por fecha |
| `sp_Alerta_GenerarPorStockMinimo` | SP | Job programado (SQL Agent o `IHostedService` que lo invoca): inserta en `alertas_stock` tipo `'stock_minimo'` si `stock_actual <= stock_minimo` y no existe alerta abierta |
| `sp_Alerta_GenerarPorVencimiento` | SP | Igual, tipo `'vencimiento_proximo'` para lotes por vencer |
| `sp_Alerta_Resolver` | SP | Marca `resuelta = 1`, `fecha_resolucion`, `id_usuario_resolucion` |
| `vw_AlertasActivas` | Vista | `alertas_stock` donde `resuelta = 0` |

### 3.5 Clientes y Recetas
**Tablas:** `clientes`, `recetas`, `detalle_recetas`

| Objeto | Tipo | Descripción |
|---|---|---|
| `sp_Cliente_Insertar/_Actualizar/_Eliminar` | SP | CRUD, valida `identificacion` única |
| `sp_Receta_Registrar` | SP transaccional | Inserta `recetas` + N filas `detalle_recetas` en una sola transacción (parámetro tabla `TVP` con el detalle) |
| `sp_Receta_ObtenerPorId` | SP | Cabecera + detalle |
| `sp_Receta_MarcarDispensada` | SP | Se invoca desde `sp_Venta_Registrar` cuando la venta cubre una receta; marca `recetas.dispensada` y cada `detalle_recetas.dispensada` según cantidades vendidas |
| `fn_RecetaVigente` | Función escalar | `1/0` según `fecha_vencimiento >= GETDATE()` |
| `vw_RecetasPendientes` | Vista | Recetas con `dispensada = 0` y vigentes |

### 3.6 Ventas
**Tablas:** `ventas`, `detalle_ventas`

| Objeto | Tipo | Descripción |
|---|---|---|
| `sp_Venta_Registrar` | SP transaccional (el más crítico) | Recibe cabecera + TVP de detalle (`id_producto`, `cantidad`, `precio_unitario`). Por cada línea: 1) si `medicamentos.controlado=1` o `productos.requiere_receta=1`, valida receta vigente con `fn_RecetaVigente`, si no existe/lanza error de negocio; 2) resuelve lote(s) vía `fn_ObtenerLoteFEFO`; 3) valida stock suficiente, si no `THROW` `StockInsuficiente`; 4) inserta `detalle_ventas` con `id_lote`; 5) llama `sp_Kardex_RegistrarMovimiento` tipo `'salida'` por cada lote afectado; 6) actualiza `ventas.total`; 7) si `id_receta` no es null, llama `sp_Receta_MarcarDispensada`. Todo en una transacción con `TRY/CATCH/ROLLBACK`. |
| `sp_Venta_Anular` | SP | Cambia `estado='anulada'`, revierte stock (kardex tipo `'entrada'` de reverso), solo si no han pasado X días (regla de negocio configurable) |
| `sp_Venta_ObtenerPorId` | SP | Cabecera + detalle + producto |
| `vw_Ventas` | Vista | Listado con joins a cliente/empleado/usuario |
| `vw_VentasDetalladas` | Vista | Para reportes: venta + detalle + producto + lote |

### 3.7 Compras
**Tablas:** `compras`, `detalle_compras`

| Objeto | Tipo | Descripción |
|---|---|---|
| `sp_Compra_Registrar` | SP | Crea cabecera `compras` en estado `'pendiente'` + TVP de detalle (sin generar lotes aún) |
| `sp_Compra_Recibir` | SP transaccional | Cambia estado a `'recibida'`; por cada línea crea/actualiza `lotes` (`sp_Lote_Insertar` interno) con `numero_lote`, `fecha_vencimiento`, `cantidad_inicial=cantidad`; llama `sp_Kardex_RegistrarMovimiento` tipo `'entrada'` (recalcula `precio_promedio_pond` con `fn_CalcularPrecioPromedioPonderado`) |
| `sp_Compra_Anular` | SP | Solo si `estado='pendiente'` |
| `sp_Compra_ObtenerPorId` | SP | Cabecera + detalle |
| `vw_Compras` | Vista | Listado con joins a proveedor/empleado/usuario |

---

## 4. Endpoints REST propuestos (mapeo directo a los objetos anteriores)

```
AUTH
POST   /api/auth/login                     -> sp_Usuario_Autenticar

USUARIOS / ROLES / EMPLEADOS
GET    /api/usuarios                       -> vw_UsuarioPermisos (paginado)
POST   /api/usuarios                       -> sp_Usuario_Insertar
PUT    /api/usuarios/{id}                  -> sp_Usuario_Actualizar
DELETE /api/usuarios/{id}                  -> sp_Usuario_Desactivar
CRUD similar para /api/roles, /api/permisos, /api/empleados

CATALOGOS
CRUD estándar para /api/categorias, /api/proveedores, /api/laboratorios,
                    /api/principios-activos, /api/presentaciones

PRODUCTOS
GET    /api/productos                      -> vw_Productos
GET    /api/productos/{id}                 -> sp_Producto_ObtenerPorId
POST   /api/productos                      -> sp_Producto_Insertar
PUT    /api/productos/{id}                 -> sp_Producto_Actualizar
DELETE /api/productos/{id}                 -> sp_Producto_Eliminar
GET    /api/productos/{id}/medicamento     -> vw_ProductosMedicamentos

INVENTARIO
GET    /api/inventario/stock               -> vw_StockActual
GET    /api/inventario/por-vencer?dias=30  -> vw_ProductosPorVencer
GET    /api/inventario/kardex/{idProducto} -> vw_KardexProducto
POST   /api/inventario/ajustes             -> sp_Inventario_AjusteManual
GET    /api/inventario/alertas             -> vw_AlertasActivas
PATCH  /api/inventario/alertas/{id}/resolver -> sp_Alerta_Resolver

CLIENTES / RECETAS
CRUD /api/clientes
POST   /api/recetas                        -> sp_Receta_Registrar
GET    /api/recetas/{id}                   -> sp_Receta_ObtenerPorId
GET    /api/recetas/pendientes             -> vw_RecetasPendientes

VENTAS
POST   /api/ventas                         -> sp_Venta_Registrar
GET    /api/ventas/{id}                    -> sp_Venta_ObtenerPorId
GET    /api/ventas                         -> vw_Ventas
PATCH  /api/ventas/{id}/anular             -> sp_Venta_Anular

COMPRAS
POST   /api/compras                        -> sp_Compra_Registrar
PATCH  /api/compras/{id}/recibir           -> sp_Compra_Recibir
PATCH  /api/compras/{id}/anular            -> sp_Compra_Anular
GET    /api/compras/{id}                   -> sp_Compra_ObtenerPorId
GET    /api/compras                        -> vw_Compras
```

---

## 5. Reglas de negocio que viven en SQL (no en C#)

1. **FEFO** (First-Expired-First-Out): toda salida de stock se resuelve con `fn_ObtenerLoteFEFO`.
2. **Costo promedio ponderado**: recalculado en cada entrada por `fn_CalcularPrecioPromedioPonderado`, persistido en `productos.precio_promedio_pond` y `kardex.precio_promedio_pond`/`saldo_valorado`.
3. **Trazabilidad**: cada movimiento de stock (venta, compra, ajuste) genera **una fila de kardex**; nunca se actualiza `stock_actual` directamente desde la API.
4. **Control de recetas**: medicamentos `controlado = 1` o producto `requiere_receta = 1` exigen receta vigente (`fn_RecetaVigente`) antes de vender.
5. **Alertas automáticas**: generadas por job (SQL Agent o `BackgroundService` en .NET que invoca los SPs), nunca calculadas en tiempo real en el front.
6. **Transaccionalidad**: `sp_Venta_Registrar`, `sp_Compra_Recibir` y `sp_Receta_Registrar` son atómicos (`BEGIN TRAN ... COMMIT/ROLLBACK`) porque tocan múltiples tablas relacionadas.

---

## 6. Próximos pasos sugeridos

1. Confirmar contigo el detalle de `sp_Venta_Registrar` y `sp_Compra_Recibir` (son los más complejos) antes de codificarlos — te propongo iterar con el **DDL real de cada SP** en el siguiente paso.
2. Definir los `TVP` (Table-Valued Parameters) para detalle de venta/compra/receta (tipo de tabla `dbo.TipoDetalleVenta`, etc.).
3. Escribir los SPs en el orden: catálogos → productos → inventario (kardex/FEFO) → compras → ventas → recetas → alertas.
4. En paralelo, armar los DTOs y el esqueleto de capas en .NET (te lo puedo generar).

¿Quieres que continúe con el **DDL de los stored procedures/functions/views** (T-SQL completo) o prefieres primero el **esqueleto del proyecto .NET** (carpetas, DI, Dapper config)?