import { useQueryClient } from '@tanstack/react-query'
import { createContext, useCallback, useContext, useEffect, useState, type ReactNode } from 'react'
import { toast } from 'sonner'
import { apiFetch, alManejarNoAutorizado } from '@/lib/api/client'
import type { LoginResponse } from '@/types/api'
import {
  establecerSesion,
  limpiarSesion,
  obtenerSesion,
  restaurarSesionDesdeStorage,
  suscribirseASesion,
  type SesionActual,
} from './token-store'

interface AuthContextValue {
  sesion: SesionActual | null
  sesionExpirada: boolean
  login: (nombreUsuario: string, password: string) => Promise<void>
  logout: () => void
  reautenticar: (password: string) => Promise<void>
}

const AuthContext = createContext<AuthContextValue | null>(null)

const AVISO_ANTES_MS = 5 * 60 * 1000

/**
 * Al expirar (o ante cualquier 401), NO redirige a /login -- marca
 * sesionExpirada y AppProviders monta un <ReauthDialog/> modal encima de lo
 * que sea que este en pantalla. Un cajero puede tener 12 lineas de venta
 * tipeadas; un redirect las destruye, el modal las preserva. Las mutaciones
 * nunca se reintentan automaticamente tras reautenticar (ver main.tsx,
 * retry:false global) -- una venta reintentada sola es una venta duplicada
 * moviendo stock real.
 */
export function AuthProvider({ children }: { children: ReactNode }) {
  const [sesion, setSesion] = useState<SesionActual | null>(() => restaurarSesionDesdeStorage())
  const [sesionExpirada, setSesionExpirada] = useState(false)
  const queryClient = useQueryClient()

  useEffect(() => suscribirseASesion(() => setSesion(obtenerSesion())), [])

  useEffect(() => {
    alManejarNoAutorizado(() => setSesionExpirada(true))
  }, [])

  useEffect(() => {
    if (!sesion) return

    const expiraEnMs = new Date(sesion.expiraEn).getTime()
    const faltanMs = expiraEnMs - Date.now()
    if (faltanMs <= 0) {
      setSesionExpirada(true)
      return
    }

    const avisoId =
      faltanMs > AVISO_ANTES_MS
        ? window.setTimeout(() => {
            toast.warning('Tu sesion expira en 5 minutos.', { duration: 10_000 })
          }, faltanMs - AVISO_ANTES_MS)
        : undefined

    const expiraId = window.setTimeout(() => setSesionExpirada(true), faltanMs)

    return () => {
      if (avisoId !== undefined) window.clearTimeout(avisoId)
      window.clearTimeout(expiraId)
    }
  }, [sesion])

  const login = useCallback(async (nombreUsuario: string, password: string) => {
    const respuesta = await apiFetch<LoginResponse>('/auth/login', { method: 'POST', body: { nombreUsuario, password } })
    establecerSesion(respuesta)
    setSesionExpirada(false)
  }, [])

  const logout = useCallback(() => {
    limpiarSesion()
    setSesionExpirada(false)
    queryClient.clear()
  }, [queryClient])

  const reautenticar = useCallback(
    async (password: string) => {
      const usuarioActual = obtenerSesion()?.nombreUsuario
      if (!usuarioActual) throw new Error('No hay sesion previa para reautenticar.')
      await login(usuarioActual, password)
      queryClient.invalidateQueries()
    },
    [login, queryClient],
  )

  const value: AuthContextValue = { sesion, sesionExpirada, login, logout, reautenticar }

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth debe usarse dentro de <AuthProvider>.')
  return ctx
}
