import { Navigate, Outlet, useLocation } from 'react-router'
import { useAuth } from '@/lib/auth/auth-context'

/** Envuelve la rama autenticada del router. Sin sesion -> redirect a /login preservando a donde volver. */
export function RutaProtegida() {
  const { sesion } = useAuth()
  const location = useLocation()

  if (!sesion) {
    return <Navigate to="/login" replace state={{ volverA: location.pathname + location.search }} />
  }

  return <Outlet />
}
