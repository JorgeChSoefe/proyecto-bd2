import { apiFetch, buildQuery } from '@/lib/api/client'
import type { ListaParams, Paginado } from '@/types/pagination'

/**
 * Wrapper delgado sobre cualquier endpoint que siga el patron
 * _Listar/_ObtenerPorId/_Insertar/_Actualizar/_Eliminar (los 8 catalogos
 * simples + usuarios + clientes). `crear` retorna `unknown` a proposito: la
 * forma del body de un POST no esta especificada de manera uniforme entre
 * modulos y nada del camino generico depende de ella -- exito significa
 * "invalidar y cerrar el dialog".
 */
export function createCrudApi<TRow, TCrear, TEditar = TCrear>(endpoint: string) {
  return {
    listar: (params: ListaParams, signal?: AbortSignal) => apiFetch<Paginado<TRow>>(`${endpoint}${buildQuery(params)}`, { signal }),
    obtener: (id: number, signal?: AbortSignal) => apiFetch<TRow>(`${endpoint}/${id}`, { signal }),
    crear: (body: TCrear) => apiFetch<unknown>(endpoint, { method: 'POST', body }),
    actualizar: ({ id, body }: { id: number; body: TEditar }) => apiFetch<void>(`${endpoint}/${id}`, { method: 'PUT', body }),
    eliminar: (id: number) => apiFetch<void>(`${endpoint}/${id}`, { method: 'DELETE' }),
  }
}
