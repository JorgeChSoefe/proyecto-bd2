import { useMemo } from 'react'
import { useAuth } from './auth-context'
import type { Permiso } from './permissions'

export interface UseCanResult {
  can: (permiso: Permiso) => boolean
  canAny: (permisos: Permiso[]) => boolean
  canAll: (permisos: Permiso[]) => boolean
}

export function useCan(): UseCanResult {
  const { sesion } = useAuth()
  const permisos = sesion?.permisos

  return useMemo(
    () => ({
      can: (permiso) => permisos?.has(permiso) ?? false,
      canAny: (lista) => lista.some((p) => permisos?.has(p) ?? false),
      canAll: (lista) => lista.every((p) => permisos?.has(p) ?? false),
    }),
    [permisos],
  )
}
