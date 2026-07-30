// Alias amigables sobre la forma real de la Api (camelCase, igual que el
// JSON que manda el servidor -- ver src/PharmaInventory.Domain/Entities y
// src/PharmaInventory.Application/Dtos en el backend). No hay capa de
// traduccion: los nombres son identicos a los del wire a proposito.
//
// Los enums viajan como string snake_case (JsonStringEnumConverter con
// SnakeCaseLower en Program.cs), el mismo vocabulario que usan los CHECK
// constraints de la base -- no como los valores numericos ordinales que
// System.Text.Json manda por defecto.

export type EstadoVenta = 'pendiente' | 'completada' | 'anulada'
export type EstadoCompra = 'pendiente' | 'recibida' | 'anulada'
export type TipoMovimientoKardex = 'entrada' | 'salida' | 'ajuste'
export type TipoAlerta = 'vencimiento_proximo' | 'stock_minimo' | 'lote_agotado'
export type ViaAdministracion =
  | 'oral' | 'topica' | 'intravenosa' | 'intramuscular' | 'subcutanea'
  | 'inhalatoria' | 'oftalmica' | 'otica' | 'nasal' | 'rectal' | 'sublingual'

// ---------- Seguridad ----------

export interface Rol {
  idRol: number
  nombreRol: string
  descripcion: string | null
}

export interface Permiso {
  idPermiso: number
  modulo: string
  accion: string
  descripcion: string | null
}

export interface Empleado {
  idEmpleado: number
  nombreCompleto: string
  cargo: string | null
  email: string | null
}

export interface UsuarioResponse {
  idUsuario: number
  nombreUsuario: string
  email: string | null
  activo: boolean
  ultimoAcceso: string | null
  creadoEn: string
  idRol: number
  nombreRol: string | null
  idEmpleado: number | null
}

export interface LoginResponse {
  token: string
  expiraEn: string
  idUsuario: number
  nombreUsuario: string
  nombreRol: string
}

// ---------- Catalogos ----------

export interface Categoria {
  idCategoria: number
  nombreCategoria: string
  descripcion: string | null
}

export interface Proveedor {
  idProveedor: number
  nombreEmpresa: string
  contactoNombre: string | null
  telefono: string | null
  email: string | null
}

export interface Laboratorio {
  idLaboratorio: number
  nombre: string
  paisOrigen: string | null
  telefono: string | null
  email: string | null
  sitioWeb: string | null
}

export interface PrincipioActivo {
  idPrincipio: number
  nombreInn: string
  grupoTerapeutico: string | null
  descripcion: string | null
}

export interface Presentacion {
  idPresentacion: number
  forma: string
  unidadMedida: string | null
}

export interface Cliente {
  idCliente: number
  nombreCompleto: string
  identificacion: string
  telefono: string | null
  fechaNacimiento: string | null
  email: string | null
}

// ---------- Productos y medicamentos ----------

export interface Producto {
  idProducto: number
  nombre: string
  nombreGenerico: string | null
  codigoSku: string | null
  codigoBarras: string | null
  precioCosto: number
  precioVenta: number
  stockActual: number
  precioPromedioPond: number
  stockMinimo: number
  requiereReceta: boolean
  idCategoria: number | null
  idProveedor: number | null
  idLaboratorio: number | null
  idPresentacion: number | null
  // Solo presentes en listados via vw_Productos (nombres resueltos, no las FK crudas)
  nombreCategoria: string | null
  proveedor: string | null
  laboratorio: string | null
  presentacion: string | null
}

export interface Medicamento {
  idMedicamento: number
  idProducto: number
  concentracion: string | null
  viaAdministracion: ViaAdministracion
  condicionesAlmacenamiento: string | null
  controlado: boolean
  numeroRegistroSanitario: string | null
  indicaciones: string | null
  contraindicaciones: string | null
  efectosSecundarios: string | null
  interacciones: string | null
}

export interface MedicamentoPrincipio {
  idMedicamento: number
  idPrincipio: number
  cantidadPorDosis: number | null
  unidad: string | null
  nombreInn: string | null
  grupoTerapeutico: string | null
}

export interface ProductoDetalleDto {
  producto: Producto
  medicamento: Medicamento | null
  principiosActivos: MedicamentoPrincipio[]
}

export interface FichaMedicamentoDto {
  idProducto: number
  nombre: string
  requiereReceta: boolean
  idMedicamento: number
  concentracion: string | null
  viaAdministracion: ViaAdministracion
  controlado: boolean
  numeroRegistroSanitario: string | null
  condicionesAlmacenamiento: string | null
  nombreInn: string | null
  grupoTerapeutico: string | null
  cantidadPorDosis: number | null
  unidad: string | null
}

// ---------- Inventario ----------

export interface StockActualDto {
  idProducto: number
  nombre: string
  codigoSku: string | null
  stockActual: number
  stockMinimo: number
  precioPromedioPond: number
  bajoStockMinimo: boolean
}

export interface ProductoPorVencerDto {
  idLote: number
  numeroLote: string
  fechaVencimiento: string
  cantidadActual: number
  idProducto: number
  nombre: string
  codigoSku: string | null
  diasParaVencer: number
}

export interface LoteDisponibleDto {
  idLote: number
  numeroLote: string
  fechaVencimiento: string
  cantidadActual: number
}

export interface MovimientoKardex {
  idMovimiento: number
  fechaMovimiento: string
  tipoMovimiento: TipoMovimientoKardex
  referenciaDoc: string | null
  idReferenciaDoc: number | null
  cantidadEntrada: number
  cantidadSalida: number
  saldoStock: number
  costoUnitario: number | null
  costoTotalMov: number | null
  precioPromedioPond: number | null
  saldoValorado: number | null
  idProducto: number
  idLote: number | null
  idUsuario: number | null
  observaciones: string | null
  nombreUsuario: string | null
}

export interface AlertaStock {
  idAlerta: number
  tipoAlerta: TipoAlerta
  idProducto: number | null
  idLote: number | null
  mensaje: string | null
  fechaAlerta: string
  resuelta: boolean
  fechaResolucion: string | null
  idUsuarioResolucion: number | null
  nombreProducto: string | null
}

// ---------- Clientes y recetas ----------

export interface Receta {
  idReceta: number
  numeroReceta: string
  idCliente: number
  nombreMedico: string | null
  numColegioMedico: string | null
  fechaEmision: string
  fechaVencimiento: string | null
  dispensada: boolean
  idVenta: number | null
  notas: string | null
  creadoEn: string
  nombreCliente: string | null
}

export interface DetalleReceta {
  idDetalle: number
  idReceta: number
  idProducto: number
  cantidadPrescrita: number
  dosis: string | null
  duracionTratamiento: string | null
  dispensada: boolean
  nombreProducto: string | null
}

export interface RecetaDetalleDto {
  receta: Receta
  lineas: DetalleReceta[]
}

// ---------- Ventas ----------

export interface Venta {
  idVenta: number
  fechaVenta: string
  total: number
  estado: EstadoVenta
  idEmpleado: number | null
  idCliente: number | null
  idUsuario: number | null
  idReceta: number | null
  nombreEmpleado: string | null
  nombreCliente: string | null
  nombreUsuario: string | null
}

export interface DetalleVenta {
  idDetalle: number
  cantidad: number
  precioUnitario: number
  subtotal: number
  idVenta: number
  idProducto: number
  idLote: number | null
  nombreProducto: string | null
  numeroLote: string | null
}

export interface VentaDetalleDto {
  venta: Venta
  lineas: DetalleVenta[]
}

// ---------- Compras ----------

export interface Compra {
  idCompra: number
  fechaCompra: string
  total: number
  estado: EstadoCompra
  idProveedor: number | null
  idEmpleado: number | null
  idUsuario: number | null
  nombreProveedor: string | null
  nombreEmpleado: string | null
  nombreUsuario: string | null
}

export interface DetalleCompra {
  idDetalle: number
  cantidad: number
  precioUnitario: number
  subtotal: number
  idCompra: number
  idProducto: number
  idLote: number | null
  nombreProducto: string | null
  numeroLote: string | null
  numeroLotePropuesto: string | null
  fechaFabricacionPropuesta: string | null
  fechaVencimientoPropuesta: string | null
  fechaVencimientoReal: string | null
}

export interface CompraDetalleDto {
  compra: Compra
  lineas: DetalleCompra[]
}
