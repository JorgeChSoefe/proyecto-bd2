import type { LoginResponse } from '@/types/api'
import { decodificarJwt } from './jwt'
import type { Permiso } from './permissions'

const STORAGE_KEY = 'pharma.auth'

export interface SesionActual {
  token: string
  expiraEn: string // ISO, viene de LoginResponse.expiraEn (autoridad del servidor)
  idUsuario: number
  nombreUsuario: string
  nombreRol: string
  permisos: Set<Permiso>
}

/**
 * Singleton en memoria -- fuente de verdad para apiFetch (que corre dentro
 * de query functions de TanStack Query, sin acceso a hooks/contexto React).
 * Se espeja en localStorage SOLO para sobrevivir un F5: con un token de 120
 * minutos y sin endpoint de refresh, memoria-sola forzaria re-login en cada
 * recarga de pagina, inaceptable para un panel que la gente recarga todo el
 * dia. Trade-off de XSS aceptado explicitamente (ver auth-context.tsx).
 */
let sesion: SesionActual | null = null
const listeners = new Set<() => void>()

function notificar() {
  for (const l of listeners) l()
}

export function suscribirseASesion(listener: () => void): () => void {
  listeners.add(listener)
  return () => listeners.delete(listener)
}

export function obtenerSesion(): SesionActual | null {
  return sesion
}

export function obtenerToken(): string | null {
  return sesion?.token ?? null
}

function aSesion(login: LoginResponse): SesionActual {
  const { permisos } = decodificarJwt(login.token)
  return {
    token: login.token,
    expiraEn: login.expiraEn,
    idUsuario: login.idUsuario,
    nombreUsuario: login.nombreUsuario,
    nombreRol: login.nombreRol,
    permisos,
  }
}

export function establecerSesion(login: LoginResponse): void {
  sesion = aSesion(login)
  localStorage.setItem(STORAGE_KEY, JSON.stringify(login))
  notificar()
}

export function limpiarSesion(): void {
  sesion = null
  localStorage.removeItem(STORAGE_KEY)
  notificar()
}

/** Se llama una sola vez al arrancar la app (AuthProvider). Lectura de localStorage es sincronica -- no hay flash de "no autenticado". */
export function restaurarSesionDesdeStorage(): SesionActual | null {
  const crudo = localStorage.getItem(STORAGE_KEY)
  if (!crudo) return null

  try {
    const login = JSON.parse(crudo) as LoginResponse
    const candidata = aSesion(login)

    const expiraEnMs = new Date(candidata.expiraEn).getTime()
    const expJwtMs = candidata ? decodificarJwt(login.token).expUnixSeconds : null
    const yaVencio =
      (Number.isFinite(expiraEnMs) && expiraEnMs <= Date.now()) ||
      (expJwtMs != null && expJwtMs * 1000 <= Date.now())

    if (yaVencio) {
      localStorage.removeItem(STORAGE_KEY)
      return null
    }

    sesion = candidata
    return candidata
  } catch {
    localStorage.removeItem(STORAGE_KEY)
    return null
  }
}
