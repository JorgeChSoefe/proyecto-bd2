/** Espejo de PharmaInventory.Application.Common.PagedResult<T>. */
export interface Paginado<T> {
  items: T[]
  total: number
  pagina: number
  tamano: number
}

/** Espejo de PharmaInventory.Application.Common.PaginacionQuery. */
export interface ListaParams {
  pagina: number
  tamano: number
  busqueda?: string
  [extra: string]: string | number | boolean | undefined
}

export function totalPaginas(paginado: Pick<Paginado<unknown>, 'total' | 'tamano'>): number {
  return Math.max(1, Math.ceil(paginado.total / paginado.tamano))
}
