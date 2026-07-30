import { useCallback, useMemo } from 'react'
import { useSearchParams } from 'react-router'
import { z } from 'zod'

const paramsSchema = z.object({
  pagina: z.coerce.number().int().min(1).catch(1),
  tamano: z.coerce.number().int().min(5).max(200).catch(50), // el tope real de la Api es 200
  busqueda: z.string().trim().max(200).catch(''),
})

export interface UseTableParamsOptions {
  /** Para endpoints que no aceptan `busqueda` (ej. /recetas/pendientes). */
  sinBusqueda?: boolean
  tamanoDefecto?: number
}

/**
 * pagina/tamano/busqueda/filtros viven en la URL, nunca en useState local --
 * asi las listas son bookmarkeables, el boton atras funciona, y un F5 no
 * pierde el lugar. Cambiar busqueda o cualquier filtro resetea pagina a 1 en
 * el MISMO setSearchParams (si no, se puede terminar en "pagina 5 de 1
 * resultado" viendo una tabla vacia).
 */
export function useTableParams(options: UseTableParamsOptions = {}) {
  const [searchParams, setSearchParams] = useSearchParams()

  const parsed = useMemo(
    () =>
      paramsSchema.parse({
        pagina: searchParams.get('pagina') ?? undefined,
        tamano: searchParams.get('tamano') ?? options.tamanoDefecto ?? undefined,
        busqueda: searchParams.get('busqueda') ?? undefined,
      }),
    [searchParams, options.tamanoDefecto],
  )

  const setPagina = useCallback(
    (pagina: number) => {
      setSearchParams((prev) => {
        const next = new URLSearchParams(prev)
        next.set('pagina', String(pagina))
        return next
      })
    },
    [setSearchParams],
  )

  const setBusqueda = useCallback(
    (busqueda: string) => {
      setSearchParams(
        (prev) => {
          const next = new URLSearchParams(prev)
          if (busqueda) next.set('busqueda', busqueda)
          else next.delete('busqueda')
          next.set('pagina', '1')
          return next
        },
        { replace: true }, // sin esto, cada tecla del debounce seria una entrada de historial
      )
    },
    [setSearchParams],
  )

  const setFiltro = useCallback(
    (param: string, valor: string | undefined) => {
      setSearchParams((prev) => {
        const next = new URLSearchParams(prev)
        if (valor === undefined || valor === '') next.delete(param)
        else next.set(param, valor)
        next.set('pagina', '1')
        return next
      })
    },
    [setSearchParams],
  )

  const obtenerFiltro = useCallback((param: string) => searchParams.get(param) ?? undefined, [searchParams])

  return {
    pagina: parsed.pagina,
    tamano: parsed.tamano,
    busqueda: options.sinBusqueda ? undefined : parsed.busqueda || undefined,
    setPagina,
    setBusqueda,
    setFiltro,
    obtenerFiltro,
  }
}
