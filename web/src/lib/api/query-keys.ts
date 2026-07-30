import type { ListaParams } from '@/types/pagination'

/**
 * Factory jerarquica de query keys: un invalidateQueries({queryKey: qk.catalogo(r)})
 * mata toda la lista + los items sueltos de ese recurso de un tiro.
 */
export const qk = {
  catalogo: (recurso: string) => ['catalogo', recurso] as const,
  catalogoLista: (recurso: string, params: ListaParams) => ['catalogo', recurso, 'lista', params] as const,
  catalogoItem: (recurso: string, id: number) => ['catalogo', recurso, 'item', id] as const,

  lookups: (recurso: string, busqueda?: string) => ['lookups', recurso, busqueda ?? ''] as const,

  usuarioPermisosDeRol: (idRol: number) => ['usuarios', 'rol-permisos', idRol] as const,

  productos: {
    todo: ['productos'] as const,
    detalle: (id: number) => ['productos', 'detalle', id] as const,
    ficha: (id: number) => ['productos', 'ficha', id] as const,
  },

  inventario: {
    todo: ['inventario'] as const,
    stock: (params: ListaParams & { soloBajoMinimo?: boolean }) => ['inventario', 'stock', params] as const,
    porVencer: (dias: number) => ['inventario', 'por-vencer', dias] as const,
    kardex: (idProducto: number, params: ListaParams) => ['inventario', 'kardex', idProducto, params] as const,
    alertas: (params: ListaParams & { tipo?: string }) => ['inventario', 'alertas', params] as const,
    lotes: (idProducto: number) => ['inventario', 'lotes', idProducto] as const,
  },

  recetas: {
    pendientes: (params: ListaParams & { idCliente?: number }) => ['recetas', 'pendientes', params] as const,
    detalle: (id: number) => ['recetas', 'detalle', id] as const,
  },

  ventas: {
    todo: ['ventas'] as const,
    lista: (params: Record<string, unknown>) => ['ventas', 'lista', params] as const,
    detalle: (id: number) => ['ventas', 'detalle', id] as const,
  },

  compras: {
    todo: ['compras'] as const,
    lista: (params: Record<string, unknown>) => ['compras', 'lista', params] as const,
    detalle: (id: number) => ['compras', 'detalle', id] as const,
  },
}
