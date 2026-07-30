import { jwtDecode } from 'jwt-decode'
import type { Permiso } from './permissions'

/**
 * Del JWT solo se lee "perm" y "exp". La identidad visible (nombreUsuario,
 * nombreRol, idUsuario) viene de la respuesta de /api/auth/login, NO se
 * re-lee del token: el claim de identidad serializa como "nameid" o como la
 * URI larga de ClaimTypes.NameIdentifier segun el handler de JWT que use el
 * backend en cada momento, y no vale la pena acoplarse a eso.
 */
interface JwtPayloadCrudo {
  perm?: string | string[]
  exp?: number
}

export interface JwtInfo {
  permisos: Set<Permiso>
  expUnixSeconds: number | null
}

export function decodificarJwt(token: string): JwtInfo {
  const payload = jwtDecode<JwtPayloadCrudo>(token)
  const crudo = payload.perm
  const lista = Array.isArray(crudo) ? crudo : crudo ? [crudo] : []
  return {
    permisos: new Set(lista as Permiso[]),
    expUnixSeconds: payload.exp ?? null,
  }
}
