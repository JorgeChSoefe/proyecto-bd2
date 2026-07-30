import { keepPreviousData, useQuery } from '@tanstack/react-query'
import { apiFetch, buildQuery } from '@/lib/api/client'
import { qk } from '@/lib/api/query-keys'
import type { Paginado } from '@/types/pagination'

export interface LookupConfig {
  /** Clave de cache: 'categorias'. */
  recurso: string
  /** '/categorias'. */
  endpoint: string
  /** 'idCategoria'. */
  campoId: string
  /** 'nombreCategoria'. */
  campoEtiqueta: string
  /** Se muestra en gris debajo/al lado de la etiqueta, ej. 'codigoSku'. */
  campoSecundario?: string
}

/** Combobox con busqueda server-side contra cualquier endpoint _Listar. Cache de 5 min: son catalogos, cambian poco. */
export function useLookup<T extends Record<string, unknown>>(config: LookupConfig, busqueda?: string) {
  return useQuery({
    queryKey: qk.lookups(config.recurso, busqueda),
    queryFn: ({ signal }) =>
      apiFetch<Paginado<T>>(`${config.endpoint}${buildQuery({ pagina: 1, tamano: 20, busqueda })}`, { signal }),
    staleTime: 5 * 60_000,
    placeholderData: keepPreviousData,
  })
}
