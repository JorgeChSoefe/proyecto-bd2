import type { ReactNode } from 'react'
import { SinPermiso } from '@/components/feedback/SinPermiso'
import { useCan } from '@/lib/auth/use-can'
import type { Permiso } from '@/lib/auth/permissions'

interface RequierePermisoProps {
  perm: Permiso | Permiso[]
  children: ReactNode
}

/** Sin el permiso, renderiza <SinPermiso/> INLINE (nunca redirige) -- sidebar y topbar quedan intactos. */
export function RequierePermiso({ perm, children }: RequierePermisoProps) {
  const { canAny } = useCan()
  const lista = Array.isArray(perm) ? perm : [perm]
  return canAny(lista) ? <>{children}</> : <SinPermiso />
}

/** Complemento (nunca sustituto) del chequeo del servidor -- solo oculta botones/acciones. */
export function Can({ perm, children }: { perm: Permiso | Permiso[]; children: ReactNode }) {
  const { canAny } = useCan()
  const lista = Array.isArray(perm) ? perm : [perm]
  return canAny(lista) ? <>{children}</> : null
}
