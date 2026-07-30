import { obtenerToken } from '@/lib/auth/token-store'

const BASE_URL = import.meta.env.VITE_API_BASE_URL ?? '/api'

export interface ProblemDetails {
  title?: string
  status?: number
  detail?: string
  instance?: string
  /** Solo presente en 400 de validacion (FluentValidation), agrupado por PropertyName -- ver aRutaRhf en problem-details.ts. */
  errores?: Record<string, string[]>
}

export class ApiError extends Error {
  readonly status: number
  readonly problem: ProblemDetails | null

  constructor(status: number, problem: ProblemDetails | null) {
    super(problem?.detail ?? problem?.title ?? `Error HTTP ${status}`)
    this.name = 'ApiError'
    this.status = status
    this.problem = problem
  }

  /** 400 con `errores`: SIEMPRE viene de FluentValidation -- distinto de un 400 sin ese campo. */
  get esValidacion(): boolean {
    return this.status === 400 && !!this.problem?.errores
  }

  get errores(): Record<string, string[]> | null {
    return this.problem?.errores ?? null
  }
}

let manejadorNoAutorizado: (() => void) | null = null

/** Lo registra AuthProvider una sola vez al montar. */
export function alManejarNoAutorizado(handler: () => void): void {
  manejadorNoAutorizado = handler
}

/** Omite undefined/null/'' -- busqueda='' nunca debe viajar en la query string. */
export function buildQuery(params: Record<string, unknown>): string {
  const usp = new URLSearchParams()
  for (const [key, value] of Object.entries(params)) {
    if (value === undefined || value === null || value === '') continue
    usp.set(key, String(value))
  }
  const query = usp.toString()
  return query ? `?${query}` : ''
}

export interface ApiFetchOptions {
  method?: 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE'
  body?: unknown
  signal?: AbortSignal
}

/**
 * fetch nativo (no axios) -- necesitamos mapeo custom a ProblemDetails de
 * todas formas. Nunca reintenta, nunca decide UI: eso vive en
 * problem-details.ts y en QueryClient (main.tsx).
 */
export async function apiFetch<T>(path: string, options: ApiFetchOptions = {}): Promise<T> {
  const token = obtenerToken()
  const headers: Record<string, string> = { Accept: 'application/json' }
  if (options.body !== undefined) headers['Content-Type'] = 'application/json'
  if (token) headers.Authorization = `Bearer ${token}`

  const res = await fetch(`${BASE_URL}${path}`, {
    method: options.method ?? 'GET',
    headers,
    body: options.body !== undefined ? JSON.stringify(options.body) : undefined,
    signal: options.signal,
  })

  if (res.status === 401) {
    manejadorNoAutorizado?.()
    throw new ApiError(401, await leerProblemDetailsSeguro(res))
  }

  if (!res.ok) {
    throw new ApiError(res.status, await leerProblemDetailsSeguro(res))
  }

  if (res.status === 204) return undefined as T

  const texto = await res.text()
  return texto ? (JSON.parse(texto) as T) : (undefined as T)
}

async function leerProblemDetailsSeguro(res: Response): Promise<ProblemDetails | null> {
  try {
    return (await res.json()) as ProblemDetails
  } catch {
    return null
  }
}
