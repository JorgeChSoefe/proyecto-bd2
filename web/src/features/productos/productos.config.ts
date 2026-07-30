import { z } from 'zod'
import { col } from '@/components/crud/columnas'
import type { CrudConfig } from '@/components/crud/crud-config'
import type { Producto } from '@/types/api'
import { zEnteroNoNeg, zIdOpc, zMonto, zTextoOpc, zTextoReq } from '@/lib/validation'

const productoSchema = z.object({
  nombre: zTextoReq(255),
  nombreGenerico: zTextoOpc(255),
  codigoSku: zTextoOpc(255),
  codigoBarras: zTextoOpc(255),
  precioCosto: zMonto,
  precioVenta: zMonto,
  stockMinimo: zEnteroNoNeg,
  requiereReceta: z.boolean(),
  idCategoria: zIdOpc,
  idProveedor: zIdOpc,
  idLaboratorio: zIdOpc,
  idPresentacion: zIdOpc,
})

export type ProductoForm = z.infer<typeof productoSchema>

// Lista + alta/edicion basica corren sobre el motor generico (igual que los
// 8 catalogos). stockActual/precioPromedioPond quedan fuera del formulario a
// proposito -- son de solo lectura, solo los mueve el kardex (ver Fase 5).
// La fila entera navega a /productos/:id (ficha clinica + principios activos,
// ProductoDetallePage) via rutaDetalle.
export const productosConfig: CrudConfig<Producto, ProductoForm> = {
  recurso: 'productos',
  endpoint: '/productos',
  modulo: 'productos',
  titulo: 'Productos',
  tituloSingular: 'Producto',
  getId: (r) => r.idProducto,

  columnas: [
    col.texto<Producto>('nombre', 'Nombre'),
    col.texto<Producto>('codigoSku', 'SKU'),
    col.texto<Producto>('nombreCategoria', 'Categoria'),
    col.moneda<Producto>('precioVenta', 'Precio venta'),
    col.numero<Producto>('stockActual', 'Stock'),
    col.bool<Producto>('requiereReceta', 'Receta', ['Si', 'No']),
  ],
  rutaDetalle: (r) => `/productos/${r.idProducto}`,

  filtros: [
    {
      tipo: 'lookup',
      param: 'idCategoria',
      label: 'Categoria',
      lookup: { recurso: 'categorias', endpoint: '/categorias', campoId: 'idCategoria', campoEtiqueta: 'nombreCategoria' },
    },
  ],

  campos: [
    { name: 'nombre', label: 'Nombre', tipo: 'texto', requerido: true, colSpan: 2, autoFocus: true },
    { name: 'nombreGenerico', label: 'Nombre generico', tipo: 'texto', colSpan: 2 },
    { name: 'codigoSku', label: 'SKU', tipo: 'texto' },
    { name: 'codigoBarras', label: 'Codigo de barras', tipo: 'texto' },
    { name: 'precioCosto', label: 'Precio costo', tipo: 'moneda', requerido: true },
    { name: 'precioVenta', label: 'Precio venta', tipo: 'moneda', requerido: true },
    { name: 'stockMinimo', label: 'Stock minimo', tipo: 'numero', requerido: true },
    { name: 'requiereReceta', label: 'Requiere receta', tipo: 'switch' },
    {
      name: 'idCategoria',
      label: 'Categoria',
      tipo: 'lookup',
      lookup: { recurso: 'categorias', endpoint: '/categorias', campoId: 'idCategoria', campoEtiqueta: 'nombreCategoria' },
    },
    {
      name: 'idProveedor',
      label: 'Proveedor',
      tipo: 'lookup',
      lookup: { recurso: 'proveedores', endpoint: '/proveedores', campoId: 'idProveedor', campoEtiqueta: 'nombreEmpresa' },
    },
    {
      name: 'idLaboratorio',
      label: 'Laboratorio',
      tipo: 'lookup',
      lookup: { recurso: 'laboratorios', endpoint: '/laboratorios', campoId: 'idLaboratorio', campoEtiqueta: 'nombre' },
    },
    {
      name: 'idPresentacion',
      label: 'Presentacion',
      tipo: 'lookup',
      lookup: { recurso: 'presentaciones', endpoint: '/presentaciones', campoId: 'idPresentacion', campoEtiqueta: 'forma' },
    },
  ],
  schema: productoSchema,
  valoresPorDefecto: {
    nombre: '',
    nombreGenerico: undefined,
    codigoSku: undefined,
    codigoBarras: undefined,
    precioCosto: 0,
    precioVenta: 0,
    stockMinimo: 0,
    requiereReceta: false,
    idCategoria: undefined,
    idProveedor: undefined,
    idLaboratorio: undefined,
    idPresentacion: undefined,
  },
  aFormulario: (r) => ({
    nombre: r.nombre,
    nombreGenerico: r.nombreGenerico ?? undefined,
    codigoSku: r.codigoSku ?? undefined,
    codigoBarras: r.codigoBarras ?? undefined,
    precioCosto: r.precioCosto,
    precioVenta: r.precioVenta,
    stockMinimo: r.stockMinimo,
    requiereReceta: r.requiereReceta,
    idCategoria: r.idCategoria ?? undefined,
    idProveedor: r.idProveedor ?? undefined,
    idLaboratorio: r.idLaboratorio ?? undefined,
    idPresentacion: r.idPresentacion ?? undefined,
  }),

  textoEliminar: (r) => `Se eliminara el producto "${r.nombre}". Esta accion no se puede deshacer.`,
}
