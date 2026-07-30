import type { QueryClient } from '@tanstack/react-query'
import { qk } from './query-keys'

/**
 * Tabla de invalidacion cruzada -- centralizada aca a proposito. Escribirla
 * mal (u olvidarla) en algun mutation individual es exactamente como
 * aparecen los bugs de "stock que no se actualiza" dificiles de reproducir.
 *
 * Ojo con esto: Stock/Alertas/Productos tienen DOS query keys distintas para
 * la misma lista -- `qk.inventario.*`/`qk.productos.*` (namespace propio) Y
 * `qk.catalogo('inventario-stock'|'inventario-alertas'|'productos')` (el que
 * arma createCrudApi para cualquier config que corre sobre el motor CrudPage
 * generico). Invalidar solo la primera deja el ultimo (el que realmente
 * renderiza la tabla) con datos viejos -- por eso cada helper de aca invalida
 * ambas.
 */
function invalidarStockYAlertas(qc: QueryClient) {
  qc.invalidateQueries({ queryKey: qk.inventario.todo })
  qc.invalidateQueries({ queryKey: qk.catalogo('inventario-stock') })
  qc.invalidateQueries({ queryKey: qk.catalogo('inventario-alertas') })
}

function invalidarProductos(qc: QueryClient) {
  qc.invalidateQueries({ queryKey: qk.productos.todo })
  qc.invalidateQueries({ queryKey: qk.catalogo('productos') })
}

export function invalidarTrasVenta(qc: QueryClient, idReceta?: number | null) {
  qc.invalidateQueries({ queryKey: qk.ventas.todo })
  invalidarStockYAlertas(qc)
  invalidarProductos(qc)
  if (idReceta != null) qc.invalidateQueries({ queryKey: qk.recetas.detalle(idReceta) })
}

export function invalidarTrasCompra(qc: QueryClient) {
  qc.invalidateQueries({ queryKey: qk.compras.todo })
  invalidarStockYAlertas(qc)
  invalidarProductos(qc)
}

export function invalidarTrasAjusteInventario(qc: QueryClient) {
  invalidarStockYAlertas(qc)
  invalidarProductos(qc)
}

export function invalidarTrasResolverAlerta(qc: QueryClient) {
  qc.invalidateQueries({ queryKey: ['inventario', 'alertas'] }) // prefijo -- matchea cualquier pagina/tamano/filtro
  qc.invalidateQueries({ queryKey: qk.catalogo('inventario-alertas') })
}

export function invalidarCatalogo(qc: QueryClient, recurso: string) {
  qc.invalidateQueries({ queryKey: qk.catalogo(recurso) })
  qc.invalidateQueries({ queryKey: ['lookups', recurso] })
}
